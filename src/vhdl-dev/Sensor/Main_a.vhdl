architecture arch of Main is
    -- Clock structure
    signal clocks    : t_clocks;

    -- Sensor flags
    signal sens_ready,
           sens_enable   : std_logic := '0';
    signal sens_temp,
           sens_hum   : std_logic_vector( 6 downto 0) := (others => '0');
    signal sens_press : std_logic_vector(10 downto 0) := (others => '0');
    signal sens_pm10  : std_logic_vector( 8 downto 0) := (others => '0');

    -- flags
    signal disp_val : unsigned(15 downto 0) := (others => '0');
    signal mltplx_translated : std_logic_vector(3 downto 0) := (others => '0');
    signal mltplx_reduced : std_logic_vector(1 downto 0) := (others => '0');
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

    display_drv: entity drivers.sm410564 PORT MAP (
        clocks => clocks, enable => '1',

        MLTPLX_CH => mltplx_reduced,
        REG_CLK => display_out.REG_CLK, REG_LATCH => display_out.REG_LATCH, REG_DATA => display_out.REG_DATA,
        dvalue => disp_val, data_format => mixed
    );
    display_out.MLTPLX_CH <= mltplx_translated;

    sensor_mod : entity modules.Sensor PORT MAP (
        clocks => clocks,

        -- Data/Flags
        enable => sens_enable, ready => sens_ready,
        temperature => sens_temp, humidity => sens_hum,
        pressure => sens_press, pm10_reading => sens_pm10,
        REFERENCE_PRESS => i2v(1, 8),

        -- Sensor IO lines
        sensors_in => sensors_in,
        sensors_out => sensors_out,
        sensors_inout => sensors_inout
    );

    DISPLAY_MANAGER: process(clocks.CLK_0M5) begin
        if rising_edge(clocks.CLK_0M5) then
            mltplx_translated <= (others => '0');
            mltplx_translated(to_integer(unsigned(mltplx_reduced))) <= '1';
        end if;
    end process;

    process(clocks.CLK_0HZ1)
        variable prev_val : unsigned(19 downto 0) := (others => '0');
        variable sleep : unsigned(2 downto 0) := (1 => '0', others => '1');
        variable switch_display, switch_timeout : unsigned(1 downto 0) := (others => '0');
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_0HZ1) then
            if sleep > 0 and sens_enable = '1' then
                sens_enable <= '0';
            end if;
            sleep := sleep + 1;
            if sens_ready = '1' and sleep = 0 then
                sens_enable <= '1';
                case to_integer(switch_display) is
                    when 0 => disp_val <= to_unsigned(12000, 16) + unsigned(sens_temp);
                    when 1 => disp_val <= "00000" & unsigned(sens_press);
                    when 2 => disp_val <= to_unsigned(16000, 16) + unsigned(sens_hum);
                    when others => disp_val <= to_unsigned(13000, 16) + unsigned(sens_pm10);
                end case;
                -- change display every 2.4s
                if switch_timeout = 2 then
                    switch_display := switch_display + 1;
                    switch_timeout := (others => '0');
                end if;
                switch_timeout := switch_timeout + 1;
            end if;
        end if;
    end process;
end arch;
