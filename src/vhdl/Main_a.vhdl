architecture arch of Main is
    -- Clock structure
    signal clocks    : t_clocks;
    signal last_reading_stamp : unsigned(19 downto 0);

    -- Display control
    signal disp_ready,
           disp_enable,
           disp_displaying : std_logic := '0';
    signal disp_dpoint  : std_logic_vector(3 downto 0) := (others => '0');
    signal delayed_keypress : std_logic_vector(1 downto 0) := (others => '1');

    -- Scheduler control
    signal schd_ready : std_logic := '0';
    -- Scheduler Data
    signal schd_measurement_out : std_logic_vector(CHECKSUM_OFFSET downto 0) := (others => '0');

    -- DataProcessor control
    signal dproc_enable, dproc_ready : std_logic := '0';
    -- DataProcessor output
    signal dproc_measurement_out : std_logic_vector(DATA_PM10P_OFFSET downto 0) := (others => '0');
    signal dproc_checksum        : std_logic_vector(CHECKSUM_LEN - 1  downto 0) := (others => '0');

    -- Storage State/Flags
    signal strg_reset,
           strg_overflow,
           strg_error,
           strg_rw,   -- '0' Read, '1' Read/Write
           strg_ready,
           strg_enable : std_logic := '0';

    -- Storage Data
    signal strg_data_type : storage_data_type;
    signal strg_timestamp : std_logic_vector(19 downto 0);
    signal strg_data_in,
           strg_data_out  : std_logic_vector(59 downto 0) := (others => '0');

    -- Settings
    signal read_freq_setting,
           sample_size,
           disp_timeout : std_logic_vector(5 downto 0);
    signal pressure_ref,
           pm10_norm    : std_logic_vector(7 downto 0);
    signal comms_btname : STRING(1 to 10);

    -- Communications state/flags
    signal comms_ready,
           comms_busy,
           comms_enable,
           comms_syn,
           comms_sleep,
           comms_ack   : std_logic := '0';
    signal comms_storage_request  : t_storage_request;
    signal comms_storage_response : t_storage_response;

    -- State
    signal state       : handler_state_type := INIT;
    signal seconds_cnt : unsigned(19 downto 0);
begin
    clk_map : clocks.CLK_50M <= CLOCK_50;
    vclock : entity utils.clock_divider -- default denominator is 42
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_1M19);
    khz_clock : entity utils.clock_divider -- 500kHz
        GENERIC MAP (denominator => to_unsigned(100, 26))
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_0M5);
    hz100_clock : entity utils.clock_divider
        GENERIC MAP (denominator => HZ_DURATION/100)
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_0HZ01);
    hz10_clock : entity utils.clock_divider
        GENERIC MAP (denominator => HZ_DURATION/10)
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_0HZ1);
    hz_clock : entity utils.clock_divider
        GENERIC MAP (denominator => HZ_DURATION)
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_1HZ);

    scheduler_mod : entity modules.Scheduler PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Data/Flags
        ready             => schd_ready,
        read_freq_setting => read_freq_setting,
        measurement_out   => schd_measurement_out,
        REFERENCE_PRESS   => pressure_ref,

        -- Sensor IO lines
        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout
    );

    processor_mod : entity modules.DataProcessor PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Control
        enable      => dproc_enable,
        ready       => dproc_ready,

        -- I/O
        pm10_norm   => pm10_norm,
        sample_size => sample_size,
        data_in     => schd_measurement_out(DATA_TEMP_OFFSET downto 0), -- skip the checksum here
        data_out    => dproc_measurement_out,
        checksum    => dproc_checksum
    );

    storage_mod : entity modules.Storage PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Control
        enable          => strg_enable,
        ready           => strg_ready,
        rw              => strg_rw,
        error           => strg_error,
        reset_settings  => strg_reset,

        -- Data
        data_type => strg_data_type,
        timestamp => strg_timestamp,
        overflow  => strg_overflow,
        data_in   => strg_data_in,
        data_out  => strg_data_out,

        -- I/O
        storage_inout => storage_inout, storage_out => storage_out
    );

    display_mod : entity modules.Display PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Data/Flags
        ready   => disp_ready,
        enable  => disp_enable,
        data    => dproc_measurement_out,
        timeout => disp_timeout,
        dpoint  => disp_dpoint,
        displaying => disp_displaying,

        -- IO lines
        display_out => display_out, keys => delayed_keypress
    );

    communications_mod : entity modules.Communications PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Control
        enable          => comms_enable,
        ready           => comms_ready,
        busy            => comms_busy,
        storage_syn     => comms_syn,
        storage_ack     => comms_ack,

        -- Internal wiring for storage access
        storage_request  => comms_storage_request,
        storage_response => comms_storage_response,

        -- Settings
        read_freq_setting => read_freq_setting,
        btname => comms_btname,
        timestamp => std_logic_vector(seconds_cnt),

        -- I/O
        comms_in => comms_in, comms_out => comms_out,
        sleep_led => comms_sleep
    );

    TIME_COUNTER: process(clocks.CLK_1HZ) begin
        if rising_edge(clocks.CLK_1HZ) then
            seconds_cnt <= seconds_cnt + 1;
        end if;
    end process;

    EVENT_HANDLER: process(clocks.CLK_0M5)
        variable return_state : handler_state_type := INIT;
        variable fetch_step   : integer range 1 to 6 := 1;
        variable init_ready,
                 fetch_fired,
                 store_reading_fired,
                 process_reading_fired,
                 process_reading_running,
                 display_reading_fired,
                 comms_storage_req_fired,
                 display_boot_flash     : boolean := false;

        function EV_PROCESS_READING(constant schd_rdy, dprc_rdy : in std_logic; constant proc_read_fired : in boolean) return boolean is begin
            return (std2bool(schd_rdy) and std2bool(dprc_rdy) and not proc_read_fired);
        end function;

        function EV_STORE_READING(constant dprc_rdy, strg_rdy : in std_logic; constant strg_read_fired, proc_read_fired, process_reading_running : in boolean) return boolean is begin
            return (std2bool(dprc_rdy) and std2bool(strg_rdy) and proc_read_fired and not process_reading_running and not strg_read_fired);
        end function;

        function EV_DISPLAY_READING(
                constant dprc_rdy, disp_rdy : in std_logic;
                constant proc_read_fired, proc_read_running, show_on_boot, pressed_key, data_rdy, disp_fired : in boolean
            ) return boolean is begin
            return (
                std2bool(dprc_rdy) and std2bool(disp_rdy) and proc_read_fired and not proc_read_running and not disp_fired
                and (pressed_key or show_on_boot) and data_rdy
            );
        end function;

        function EV_COMMS_TO_STORAGE(constant strg_rdy, comms_rdy : in std_logic; constant strg_req_rdy, strg_req_fired : in boolean) return boolean is begin
            return (std2bool(strg_rdy) and not std2bool(comms_rdy) and strg_req_rdy and not strg_req_fired);
        end function;

        function EV_STORAGE_TO_COMMS(constant strg_rdy, comms_rdy : in std_logic; constant strg_req_rdy, strg_req_fired : in boolean) return boolean is begin
            return (std2bool(strg_rdy) and not std2bool(comms_rdy) and strg_req_rdy and strg_req_fired);
        end function;
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_0M5) then
            case state is
                when INIT =>
                    disp_dpoint(3) <= '1';
                    if strg_ready = '1' then
                        -- get all the settings!
                        if fetch_fired then
                            disp_dpoint(2) <= '1';
                            case fetch_step is
                                when 1 => read_freq_setting <= strg_data_out(5 downto 0);
                                when 2 => pm10_norm         <= strg_data_out(7 downto 0);
                                when 3 => sample_size       <= strg_data_out(5 downto 0);
                                when 4 => disp_timeout      <= strg_data_out(5 downto 0); disp_dpoint(1) <= '1';
                                when 5 => comms_btname      <= v2str(strg_data_out);
                                when 6 =>
                                    pressure_ref <= strg_data_out(7 downto 0);
                                    init_ready := true;
                            end case;
                            if init_ready then
                                state <= READY;
                                return_state := READY;
                                comms_enable <= '1';
                            elsif fetch_step < 6 then
                                fetch_step := fetch_step + 1;
                            end if;
                            fetch_fired := false;
                        elsif not fetch_fired then
                            strg_rw <= '0';
                            strg_reset <= '0';
                            strg_enable <= '1';
                            case fetch_step is
                                when 1 => strg_data_type <= setting_read_freq;
                                when 2 => strg_data_type <= setting_pm10_norm;
                                when 3 => strg_data_type <= setting_avg_sample_size;
                                when 4 => strg_data_type <= setting_display_timeout;
                                when 5 => strg_data_type <= setting_device_name;
                                when 6 => strg_data_type <= setting_pressure_reference;
                            end case;
                            fetch_fired := true;
                            state <= STORAGE;
                        end if;
                    end if;
                when READY =>
                    if EV_PROCESS_READING(schd_ready, dproc_ready, process_reading_fired) then
                        last_reading_stamp <= seconds_cnt;
                        -- signal DataProcessor
                        process_reading_fired   := true;
                        process_reading_running := true;
                        dproc_enable <= '1';
                    elsif EV_STORE_READING(dproc_ready, strg_ready, store_reading_fired, process_reading_fired, process_reading_running) then
                        store_reading_fired := true;
                        -- signal Storage
                        strg_rw <= '1';
                        strg_reset <= '0';
                        strg_enable <= '1';
                        strg_data_in <= (others => '0');
                        strg_data_in(CHECKSUM_OFFSET downto 0) <= dproc_checksum & dproc_measurement_out(DATA_TEMP_OFFSET downto 0);
                        strg_timestamp <= std_logic_vector(last_reading_stamp);
                        strg_data_type <= data_record;
                        state <= STORAGE;
                        if not display_boot_flash then
                            disp_dpoint(0) <= '1';
                        end if;
                    elsif EV_DISPLAY_READING(dproc_ready, disp_ready, process_reading_fired, process_reading_running, not display_boot_flash, unsigned(delayed_keypress) > 0, unsigned(dproc_measurement_out) > 0, display_reading_fired) then
                        -- this means that the display can be interacted with (but it may still be displaying)
                        -- and we got a key press (any)
                        display_reading_fired := true;
                        disp_enable <= '1';
                        if not display_boot_flash then
                            disp_dpoint <= (others => '0');
                            display_boot_flash := true;
                        end if;
                    elsif EV_COMMS_TO_STORAGE(strg_ready, comms_ready, (comms_syn = '1' and comms_ack = '0'), comms_storage_req_fired) then
                        -- skip running a storage request when we only need the latest reading
                        if not comms_storage_request.latest then
                            -- before storage is called, prepare input
                            strg_rw        <= comms_storage_request.rw_mode;
                            strg_reset     <= comms_storage_request.reset;
                            strg_data_type <= comms_storage_request.data_type;
                            strg_timestamp <= comms_storage_request.timestamp;
                            if comms_storage_request.rw_mode = '1' then
                                strg_data_in <= comms_storage_request.data;
                            end if;
                            -- now start storage processing
                            strg_enable <= '1';

                            state <= STORAGE;
                        end if;
                        comms_storage_req_fired := true;
                    elsif EV_STORAGE_TO_COMMS(strg_ready, comms_ready, (comms_syn = '1' and comms_ack = '0'), comms_storage_req_fired) then
                        comms_storage_response.data <= (others => '0');
                        if comms_storage_request.latest then
                            -- just get the latest data from scheduler and return it
                            comms_storage_response.data(39 downto 0) <= dproc_checksum & dproc_measurement_out(DATA_TEMP_OFFSET downto 0);
                            comms_storage_response.overflow  <= '0';
                            comms_storage_response.timestamp <= std_logic_vector(last_reading_stamp);
                        else
                            -- after storage is called
                            -- fetch data
                            if comms_storage_request.rw_mode = '0' then
                                comms_storage_response.data  <= strg_data_out;
                            elsif strg_error = '0' then
                                -- update our settings using what was written to memory
                                case comms_storage_request.data_type is
                                    when setting_pm10_norm =>
                                        pm10_norm         <= comms_storage_request.data(7 downto 0);
                                    when setting_read_freq =>
                                        read_freq_setting <= comms_storage_request.data(5 downto 0);
                                    when setting_avg_sample_size =>
                                        sample_size       <= comms_storage_request.data(5 downto 0);
                                    when setting_display_timeout =>
                                        disp_timeout      <= comms_storage_request.data(5 downto 0);
                                    when setting_pressure_reference =>
                                        pressure_ref      <= comms_storage_request.data(7 downto 0);
                                    when setting_device_name =>
                                        comms_btname <= v2str(comms_storage_request.data);
                                    when others => NULL;
                                end case;
                            end if;
                            comms_storage_response.error     <= strg_error;
                            comms_storage_response.overflow  <= strg_overflow;
                            comms_storage_response.timestamp <= strg_timestamp;
                        end if;
                        -- reset internal flag
                        comms_storage_req_fired := false;
                        -- let comms know
                        comms_ack <= '1';
                    end if;
                when STORAGE =>
                    if std2bool(strg_enable) xor std2bool(strg_ready) then
                        if std2bool(strg_enable) then
                            strg_enable <= '0';
                        else
                            state <= return_state;
                        end if;
                    end if;
                -- more states or less states?
            end case;

            -- the "Async" reset section (it's clock synchronous but not state synchronous)
            -- Scheduler ready flag reset
            if schd_ready = '0' and process_reading_fired then
                store_reading_fired   := false;
                process_reading_fired := false;
            end if;
            -- DataProcessor signal reset
            if dproc_ready = '0' then
                dproc_enable <= '0';
            elsif process_reading_running then
                process_reading_running := false;
            end if;
            -- Display signal reset
            if disp_ready = '0' and display_reading_fired then
                disp_enable <= '0';
                display_reading_fired := false;
                delayed_keypress <= (others => '0');
            end if;
            -- store a keypress in case we miss it due to other processing
            if unsigned(KEYS) > unsigned(delayed_keypress) then
                delayed_keypress <= KEYS;
            end if;
            -- ack reset
            if comms_syn = '0' and comms_ack = '1' then
                comms_ack <= '0';
            end if;

            -- Debugging
            LED(7) <= comms_busy;
            if disp_displaying = '1' or DIPSW(0) = '1' then
                -- LED Status indicators
                LED(0) <= schd_ready;
                LED(1) <= strg_ready;
                LED(2) <= dproc_ready;
                LED(3) <= disp_ready;
                LED(4) <= comms_ready;
                LED(5) <= bool2std(store_reading_fired);
                LED(6) <= comms_sleep;
                -- LED(6) <= comms_in.BT_CONNECTED;
            else
                LED(6 downto 0) <= (others => '0');
            end if;
        end if;
    end process;
end arch;
