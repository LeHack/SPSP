architecture arch of Main is
    type t_local_state is (SLEEP, STORAGE);
    signal state : t_local_state := SLEEP;

    -- Clocks
    signal clocks : t_clocks;
    signal seconds_cnt : unsigned(19 downto 0) := (others => '0');

    -- Storage flags
    signal strg_ready,
           strg_reset,
           strg_rw,   -- '0' Read, '1' Read/Write
           strg_enable : std_logic := '0';

    -- Storage data
    signal strg_data_type : storage_data_type;
    signal strg_timestamp : std_logic_vector(19 DOWNTO 0);
    signal strg_data_in,
           strg_data_out  : std_logic_vector(59 DOWNTO 0);

    -- Scheduler flags
    signal schd_ready : std_logic := '0';

    -- Scheduler data
    signal schd_read_freq_setting : std_logic_vector(5 DOWNTO 0) := i2v(2 ,6);
    signal schd_measurement_out   : std_logic_vector(39 DOWNTO 0);
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
        read_freq_setting => schd_read_freq_setting,
        measurement_out   => schd_measurement_out,
        REFERENCE_PRESS   => (7 | 1 => '1', others => '0'),

        -- Sensor IO lines
        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout
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
        data_in   => strg_data_in,
        data_out  => strg_data_out,

        -- I/O
        storage_inout => storage_inout, storage_out => storage_out
    );

    TIME_COUNTER: process(clocks.CLK_1HZ) begin
        if rising_edge(clocks.CLK_1HZ) then
            seconds_cnt <= seconds_cnt + 1;
        end if;
    end process;

    process(clocks.CLK_50M)
        variable scheduler_handled : boolean := false;
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_50M) then
            case state is
                when SLEEP =>
                    -- wait for scheduler ready signal
                    if not scheduler_handled and schd_ready = '1' then
                        scheduler_handled := true;
                        -- signal Storage
                        strg_rw <= '1';
                        strg_reset <= '0';
                        strg_enable <= '1';
                        strg_data_in <= (others => '0');
                        strg_data_in(CHECKSUM_OFFSET downto 0) <= schd_measurement_out;
                        strg_timestamp <= std_logic_vector(seconds_cnt);
                        strg_data_type <= data_record;
                        state <= STORAGE;
                    end if;
                when STORAGE =>
                    if std2bool(strg_enable) xor std2bool(strg_ready) then
                        if std2bool(strg_enable) then
                            strg_enable <= '0';
                        else
                            state <= SLEEP;
                        end if;
                    end if;
            end case;
            if scheduler_handled and schd_ready = '0' then
                scheduler_handled := false;
            end if;
        end if;
    end process;
end arch;
