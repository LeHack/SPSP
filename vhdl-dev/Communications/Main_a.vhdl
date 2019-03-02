architecture arch of Main is
    -- Clock structure
    signal clocks : t_clocks;
    -- Internal state
    signal state  : handler_state_type := INIT;
    signal seconds_cnt : unsigned(19 downto 0) := to_unsigned(42, 20);

    -- Settings
    signal read_freq_setting,
           sample_size,
           disp_timeout : std_logic_vector(5 downto 0);
    signal pressure_ref,
           pm10_norm    : std_logic_vector(7 downto 0);
    signal comms_btname : STRING(1 to 10);

    -- Sensor state/flags
    signal comms_ready,
           comms_enable,
           comms_syn,
           comms_ack   : std_logic := '0';
    signal comms_storage_request  : t_storage_request;
    signal comms_storage_response : t_storage_response;
    signal comms_debug : UNSIGNED(6 downto 0);

    -- Storage State/Flags
    signal strg_ready,
           strg_enable,
           strg_reset,
           strg_error,
           strg_overflow,
           strg_rw,   -- '0' Read, '1' Read/Write
           strg_run   : std_logic := '0';

    -- Storage Data
    signal strg_data_type : storage_data_type;
    signal strg_timestamp : std_logic_vector(19 DOWNTO 0) := (others => '0');
    signal strg_data_in,
           strg_data_out  : std_logic_vector(59 DOWNTO 0) := (others => '0');
    signal strg_debug : UNSIGNED(6 downto 0);

    -- Scheduler Data
    signal schd_timestamp       : unsigned(19 DOWNTO 0) := to_unsigned(80, 20);
    signal schd_measurement_out : std_logic_vector(39 DOWNTO 0) := (
        39 downto 37 => '1', 35 downto 34 => '1', -- checksum: 59
        31 => '1',           -- 16C
        24 downto 23 => '1', -- H24%
        16 downto 15 => '1', -- 48ug/m3
         9 downto  4 => '1', -- 1008hPa
        others => '0'
    );

    -- VirtClk and flags
    signal virt_clk : std_logic := '0';
    signal disp_val : unsigned(15 downto 0) := (others => '0');
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

    display : entity drivers.sm410564 PORT MAP (
        clocks => clocks, enable => '1', -- always on

        MLTPLX_CH => display_out.MLTPLX_CH, REG_DATA => display_out.REG_DATA,
        REG_CLK => display_out.REG_CLK, REG_LATCH => display_out.REG_LATCH,
        dvalue => disp_val, data_format => hexadecimal
    );

    communications_mod : entity modules.Communications PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Control
        enable          => comms_enable,
        ready           => comms_ready,
        storage_syn     => comms_syn,
        storage_ack     => comms_ack,

        -- Internal wiring for storage access
        storage_request => comms_storage_request,
        storage_response => comms_storage_response,

        -- Settings
        read_freq_setting => read_freq_setting,
        btname => comms_btname,
        timestamp => std_logic_vector(seconds_cnt),

        -- I/O
        comms_in => comms_in, comms_out => comms_out
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

    process(clocks.CLK_0M5)
        variable return_state : handler_state_type := INIT;
        variable init_ready,
                 fetch_fired  : boolean := False;
        variable fake_count   : integer range 0 to 69 := 0;
        variable fetch_step   : integer range 1 to 7 := 1;
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_0M5) then
            LED(7) <= bool2std(comms_ready = '1');

            case state is
                when INIT =>
                    if strg_ready = '1' then
                        -- get all the settings!
                        if fetch_fired then
                            case fetch_step is
                                when 1 => read_freq_setting <= strg_data_out(5 downto 0);
                                when 2 => pm10_norm         <= strg_data_out(7 downto 0);
                                when 3 => sample_size       <= strg_data_out(5 downto 0);
                                when 4 => disp_timeout      <= strg_data_out(5 downto 0);
                                when 5 => comms_btname      <= v2str(strg_data_out);
                                when 6 => pressure_ref      <= strg_data_out(7 downto 0);
                                when 7 =>
                                    if fake_count < 68 then
                                        fake_count := fake_count + 1;
                                    else
                                        init_ready := true;
                                    end if;
                            end case;

                            if init_ready then
                                state <= READY;
                                return_state := READY;
                                comms_enable <= '1';
                            elsif fetch_step < 7 then
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
                                when 7 =>
                                    strg_rw <= '1';
                                    strg_data_type <= data_record;
                                    strg_timestamp <= i2v(fake_count, 20);
                                    strg_data_in(39 downto 0) <= get_fake_data(fake_count);                                -- when 6 => press_ref
                            end case;
                            fetch_fired := true;
                            state <= STORAGE;
                        end if;
                    end if;
                when READY =>
                    if strg_ready = '1' and comms_syn = '1' then
                        -- skip the extra call to allow storage/comms to transition to a new state
                        if strg_enable = '0' and comms_ack = '0' then
                            if not fetch_fired and not comms_storage_request.latest then
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
                                fetch_fired := true;
                                state <= STORAGE;
                            else
                                comms_storage_response.data <= (others => '0');
                                if comms_storage_request.latest then
                                    -- just get the latest data from scheduler and return it
                                    comms_storage_response.data(39 downto 0) <= schd_measurement_out;
                                    comms_storage_response.overflow  <= '0';
                                    comms_storage_response.error     <= '0';
                                    comms_storage_response.timestamp <= std_logic_vector(schd_timestamp);
                                else
                                    -- after storage is called
                                    -- fetch data
                                    if comms_storage_request.rw_mode = '0' then
                                        comms_storage_response.data  <= strg_data_out;
                                    elsif strg_error = '0' then
                                        -- update our settings using what was written to memory
                                        -- but only if no errors were reported
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
                                                comms_btname      <= v2str(comms_storage_request.data);
                                            when others => NULL;
                                        end case;
                                    end if;
                                    comms_storage_response.error     <= strg_error;
                                    comms_storage_response.overflow  <= strg_overflow;
                                    comms_storage_response.timestamp <= strg_timestamp;
                                end if;
                                -- reset internal flag
                                fetch_fired := false;
                                -- let comms know
                                comms_ack <= '1';
                            end if;
                        end if;
                    elsif strg_ready = '1' and KEYS(0) = '0' then
                        if not fetch_fired then
                            strg_rw <= '1';
                            strg_reset <= '0';
                            strg_data_type <= data_record;
                            strg_timestamp <= i2v(2, 20);
                            strg_data_in <= (others => '0');
                            strg_data_in(10 downto  0) <= i2v(42, 11);
                            strg_data_in(19 downto 11) <= i2v(42,  9);
                            strg_data_in(26 downto 20) <= i2v(42,  7);
                            strg_data_in(33 downto 27) <= i2v(42,  7);
                            strg_data_in(39 downto 34) <= i2v(46,  6);
                            strg_enable <= '1';
                            fetch_fired := true;
                            state <= STORAGE;
                        else
                            fetch_fired := false;
                        end if;
                    end if;

                    -- ack resets
                    if comms_syn = '0' then
                        comms_ack <= '0';
                    end if;
                when STORAGE =>
                    if std2bool(strg_enable) xor std2bool(strg_ready) then
                        if std2bool(strg_enable) then
                            strg_enable <= '0';
                            strg_reset  <= '0';
                        else
                            state <= return_state;
                        end if;
                    end if;
            end case;
        end if;
    end process;
end arch;
