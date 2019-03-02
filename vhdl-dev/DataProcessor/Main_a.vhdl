architecture arch of Main is
    -- Clock structure
    signal clocks    : t_clocks;
    signal timestamp : unsigned(19 DOWNTO 0);

    -- Scheduler control
    signal schd_ready : std_logic := '0';
    -- Scheduler Data
    signal schd_measurement_out : std_logic_vector(CHECKSUM_OFFSET DOWNTO 0);

    -- DataProcessor control
    signal dproc_enable, dproc_ready : std_logic := '0';
    -- DataProcessor output
    signal dproc_measurement_out : STD_LOGIC_VECTOR(DATA_TEMP_OFFSET + 10 DOWNTO 0);
    signal pressure_ref : std_logic_vector(7 downto 0) := i2v(-35, 8);

    -- Storage State/Flags
    signal strg_reset,
           strg_overflow,
           strg_rw,   -- '0' Read, '1' Read/Write
           strg_ready,
           strg_enable : std_logic := '0';

    -- Storage Data
    signal strg_data_type : storage_data_type;
    signal strg_timestamp : std_logic_vector(19 DOWNTO 0);
    signal strg_data_in,
           strg_data_out  : std_logic_vector(59 DOWNTO 0);
    signal strg_debug : UNSIGNED(6 downto 0);
    -- Settings
    signal pm10_norm         : std_logic_vector(7 DOWNTO 0);

    -- Display
    signal disp_val : unsigned(15 downto 0) := (others => '0');

    -- State
    signal state       : handler_state_type := INIT;
    signal seconds_cnt : unsigned (19 downto 0) := (others => '0');
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

    storage_mod : entity modules.Storage PORT MAP (
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

    display_mod: entity segdispl.sm410564 PORT MAP (
        clocks => clocks,

        MLTPLX_CH => display_out.MLTPLX_CH,
        REG_CLK => display_out.REG_CLK, REG_LATCH => display_out.REG_LATCH, REG_DATA => display_out.REG_DATA,
        dvalue => disp_val, data_format => decimal
    );

    seconds_counter: process(clocks.CLK_1HZ) begin
        if rising_edge(clocks.CLK_1HZ) then
            seconds_cnt <= seconds_cnt + 1;
        end if;
    end process;

    event_handler: process(clocks.CLK_0M5)
        variable return_state : handler_state_type := INIT;
        variable fetch_step   : integer range 1 to 2 := 1;
        variable fetch_fired,
                 store_reading_fired,
                 process_reading_fired,
                 display_fired : boolean := false;

        -- events
        constant EV_MAX : integer := 6;
        variable events : unsigned (0 to EV_MAX) := (others => '0');
        constant EV_STORE_READING   : unsigned (0 to EV_MAX) := (0 to 1 => '1', 5 => '0', others => '-');
        constant EV_PROCESS_READING : unsigned (0 to EV_MAX) := (0 | 2 | 5 => '1', 6 => '0', others => '-');

        procedure read_events is begin
            events(0) := schd_ready;
            events(1) := strg_ready;
            events(2) := dproc_ready;
            events(3) := '0'; -- stub for display
            events(4) := '0'; -- stub for comms
            events(5) := bool2std(store_reading_fired);
            events(6) := bool2std(process_reading_fired);
        end procedure;

    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_0M5) then
            case state is
                when INIT =>
                    if strg_ready = '1' then
                        -- get all the settings!
                        if fetch_fired then
                            case fetch_step is
                                when 1 => pm10_norm <= strg_data_out(7 downto 0); state <= READY;
                                when others => NULL;
                            end case;
                            fetch_fired := false;
                        elsif not fetch_fired then
                            strg_rw <= '0';
                            strg_reset <= '0';
                            strg_enable <= '1';
                            case fetch_step is
                                when 1 => strg_data_type <= setting_pm10_norm;
                                when others => NULL;
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
                            -- strg_enable <= '1';
                            strg_data_in <= (others => '0');
                            strg_data_in(CHECKSUM_OFFSET downto 0) <= schd_measurement_out;
                            strg_timestamp <= std_logic_vector(seconds_cnt);
                            strg_data_type <= data_record;
                            -- state <= STORAGE;
                            return_state := READY;
                        when EV_PROCESS_READING =>
                            -- signal DataProcessor
                            process_reading_fired := true;
                            dproc_enable <= '1';
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
            end if;
        end if;
    end process;
end arch;
