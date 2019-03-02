architecture arch of Main is
    -- Clock structure
    signal clocks    : t_clocks;

    -- Scheduler flags
    signal schd_ready : std_logic := '0';

    -- Scheduler Data
    signal schd_read_freq_setting : std_logic_vector(5 DOWNTO 0) := i2v(3, 6);
    signal schd_measurement_out   : std_logic_vector(39 DOWNTO 0);
    signal pressure_ref : std_logic_vector(7 downto 0) := (others => 'U');
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
        REFERENCE_PRESS   => pressure_ref,

        -- Sensor IO lines
        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout
    );

    process (clocks.CLK_0HZ1)
        variable sleep : unsigned(4 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_0HZ1) then
            sleep := sleep + 1;
            if sleep = 20 then
                pressure_ref <= (7 | 1 => '1', others => '0');
            end if;
        end if;
    end process;
end arch;
