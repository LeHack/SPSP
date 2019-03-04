architecture arch of Main is
    -- Clock structure
    signal clocks    : t_clocks;
    signal timestamp : unsigned(19 downto 0);

    -- Display control
    signal disp_ready,
           disp_enable  : std_logic := '0';
    signal disp_dpoint  : std_logic_vector(3 downto 0) := (others => '0');
    -- signal disp_timeout : unsigned(5 downto 0) := (others => '0');
    signal delayed_keypress : std_logic_vector(1 downto 0) := (others => '1');

    -- Scheduler control
    signal schd_ready : std_logic := '0';
    -- Scheduler Data
    signal schd_measurement_out : std_logic_vector(CHECKSUM_OFFSET downto 0) := (others => '0');
    signal pressure_ref : std_logic_vector(7 downto 0) := i2v(-35, 8);

    -- DataProcessor control
    signal dproc_enable, dproc_ready : std_logic := '0';
    -- DataProcessor output
    signal dproc_measurement_out : std_logic_vector(DATA_PM10P_OFFSET downto 0) := (others => '0');

    -- Storage State/Flags
    signal strg_reset,
           strg_overflow,
           strg_rw,   -- '0' Read, '1' Read/Write
           strg_ready,
           strg_enable : std_logic := '0';

    -- Storage Data
    signal strg_data_type : storage_data_type;
    signal strg_timestamp : std_logic_vector(19 downto 0);
    signal strg_data_in,
           strg_data_out  : std_logic_vector(59 downto 0) := (others => '0');
    signal strg_debug : unsigned(6 downto 0);
    -- Settings
    signal sample_size       : std_logic_vector(5 downto 0);
    signal pm10_norm         : std_logic_vector(7 downto 0);

    -- State
    signal state       : handler_state_type := INIT;
    signal seconds_cnt : unsigned(19 downto 0) := (others => '0');
begin
    clk_map : clocks.CLK_50M <= CLOCK_50;
    vclock : entity utils.clock_divider -- default denominator is 42
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_1M19);
    khz_clock : entity utils.clock_divider -- 500kHz
        GENERIC MAP (denominator => to_unsigned(100, 26))
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_0M5);
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
        data_out    => dproc_measurement_out
    );

    storage_mod : entity modules.Storage GENERIC MAP (
        default_read_freq_setting => RD_FREQ_SET
    ) PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Control
        enable          => strg_enable,
        ready           => strg_ready,
        rw              => strg_rw,
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

        -- IO lines
        display_out => display_out, keys => delayed_keypress
    );

    seconds_counter: process(clocks.CLK_1HZ) begin
        if rising_edge(clocks.CLK_1HZ) then
            seconds_cnt <= seconds_cnt + 1;
        end if;
    end process;

    event_handler: process(clocks.CLK_0M5)
        variable return_state : handler_state_type := INIT;
        variable fetch_step   : integer range 1 to 3 := 1;
        variable fetch_fired,
                 store_reading_fired,
                 process_reading_fired,
                 process_reading_running,
                 display_reading_fired,
                 display_boot_flash     : boolean := false;

        -- events
        constant EV_MAX : integer := 10;
        variable events : unsigned (0 to EV_MAX) := (others => '0');
        constant EV_STORE_READING   : unsigned (0 to EV_MAX) := (0 to 1 => '1', 5 => '0', others => '-');
        constant EV_PROCESS_READING : unsigned (0 to EV_MAX) := (0 | 2 | 5 => '1', 6 => '0', others => '-');
        constant EV_DISPLAY_READING : unsigned (0 to EV_MAX) := (2 to 3 | 5 to 6 | 9 to 10 => '1', 7 | 8 => '0', others => '-');

        procedure read_events is begin
            events( 0) := schd_ready;
            events( 1) := strg_ready;
            events( 2) := dproc_ready;
            events( 3) := disp_ready;
            events( 4) := '0'; -- stub for comms
            events( 5) := bool2std(store_reading_fired);
            events( 6) := bool2std(process_reading_fired);
            events( 7) := bool2std(process_reading_running);
            events( 8) := bool2std(display_reading_fired);
            events( 9) := bool2std(unsigned(delayed_keypress) < 3 or not display_boot_flash);
                         -- any key pressed or if boot flash was not done yet
            events(10) := bool2std(unsigned(dproc_measurement_out) > 0);

            -- show the first 8 events using LEDs for debuging purposes
            LED <= std_logic_vector(events(0 to 7));
        end procedure;

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
                                when 1 => pm10_norm         <= strg_data_out(7 downto 0); fetch_step := 2; 
                                when 2 => sample_size       <= strg_data_out(5 downto 0); fetch_step := 3;
                                when 3 => state <= READY; -- ignore the value for our tests
                                          disp_dpoint(1) <= '1';
                            end case;
                            fetch_fired := false;
                        elsif not fetch_fired then
                            strg_rw <= '0';
                            strg_reset <= '0';
                            strg_enable <= '1';
                            case fetch_step is
                                when 1 => strg_data_type <= setting_pm10_norm;
                                when 2 => strg_data_type <= setting_avg_sample_size;
                                when 3 => strg_data_type <= setting_display_timeout;
                            end case;
                            fetch_fired := true;
                            state <= STORAGE;
                        end if;
                    end if;
                when READY =>
                    -- detect and handle events
                    read_events;

                    case? events is
                        when EV_STORE_READING =>
                            store_reading_fired := true;
                            strg_rw <= '1';
                            strg_reset <= '0';
                            strg_enable <= '1';
                            strg_data_in <= (others => '0');
                            strg_data_in(CHECKSUM_OFFSET downto 0) <= schd_measurement_out;
                            strg_timestamp <= std_logic_vector(seconds_cnt);
                            strg_data_type <= data_record;
                            state <= STORAGE;
                            return_state := READY;
                            if not display_boot_flash then
                                disp_dpoint(0) <= '1';
                            end if;
                        when EV_PROCESS_READING =>
                            -- signal DataProcessor
                            process_reading_fired   := true;
                            process_reading_running := true;
                            dproc_enable <= '1';
                        when EV_DISPLAY_READING =>
                            -- this means that the display can be interacted with (but it may still be displaying)
                            -- and we got a key press (any)
                            display_reading_fired := true;
                            disp_enable <= '1';
                            if not display_boot_flash then
                                disp_dpoint <= (others => '0');
                                display_boot_flash := true;
                            end if;
                        when others => NULL;
                    end case?;
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
            if schd_ready = '0' and store_reading_fired then
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
                delayed_keypress <= (others => '1');
            end if;
            -- store a keypress in case we miss it due to other processing
            if unsigned(KEYS) < unsigned(delayed_keypress) then
                delayed_keypress <= KEYS;
            end if;
        end if;
    end process;
end arch;
