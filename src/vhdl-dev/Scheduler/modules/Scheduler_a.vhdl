architecture arch of Scheduler is
    type scheduler_state_type is (idle, gather_data, set_checksum);
    signal state : scheduler_state_type := idle;

    -- Sensor state/flags
    signal sens_ready,
           sens_enable : std_logic := '0';
    signal sens_temp,
           sens_hum   : std_logic_vector( 6 downto 0) := (others => '0');
    signal sens_press : std_logic_vector(10 downto 0) := (others => '0');
    signal sens_pm10  : std_logic_vector( 8 downto 0) := (others => '0');

    signal div_number    : STD_LOGIC_VECTOR (15 DOWNTO 0) := (others => '0');
    signal div_remainder : STD_LOGIC_VECTOR ( 9 DOWNTO 0) := (others => '0');
    signal trigger : unsigned(9 downto 0) := (others => '0');
    signal trigger_run : std_logic := '0';
begin
    div_inst : entity ext.div16 PORT MAP (
        clock    => clocks.CLK_50M,
		numer	 => div_number,
		denom	 => i2v(61, 10),
		remain	 => div_remainder
	);

    sensor_mod : entity modules.Sensor PORT MAP (
        clocks => clocks,

        -- Data/Flags
        enable => sens_enable, ready => sens_ready,
        temperature => sens_temp, humidity => sens_hum,
        pressure => sens_press, pm10_reading => sens_pm10,
        REFERENCE_PRESS => REFERENCE_PRESS,

        -- Sensor IO lines
        sensors_in => sensors_in,
        sensors_out => sensors_out,
        sensors_inout => sensors_inout
    );

    SCHEDULER_TRIGGER: process(clocks.CLK_0HZ1)
        constant MULT : unsigned(3 downto 0) := to_unsigned(10, 4);
    begin
        if rising_edge(clocks.CLK_0HZ1) and trigger_run = '1' and unsigned(read_freq_setting) > 0 then
            if trigger > 0 then
                trigger <= trigger - 1;
            else
                trigger <= unsigned(read_freq_setting) * MULT - 1;
            end if;
        end if;
    end process;

    SCHEDULER_SENSORS: process(clocks.CLK_1M19)
        variable sens_fired, trigger_handled : boolean := false;
    begin
        -- do nothing until the required settings are available
        if rising_edge(clocks.CLK_1M19) and REFERENCE_PRESS /= (0 to 7 => 'U')  then
           case state is
                when idle =>
                    -- use trigger_handled to prohibit double fire (due to clock speed difference)
                    if trigger = 0 and not trigger_handled and sens_ready = '1' and not sens_fired then
                        -- init the readout process
                        sens_enable <= '1';
                        ready <= '0';
                        sens_fired := true;
                    end if;
                    if sens_ready = '0' and sens_fired then
                        -- wait for sens_ready to go down
                        sens_enable <= '0';
                        sens_fired := false;
                        trigger_handled := true;
                        state <= gather_data;
                        trigger_run <= '1';
                    end if;
                when gather_data =>
                    if sens_ready = '1' then
                        -- when the readout process is done
                        measurement_out(DATA_TEMP_OFFSET downto 0) <= sens_temp & sens_hum & sens_pm10 & sens_press;
                        div_number(10 downto 0) <= std_logic_vector(
                              unsigned(sens_temp) + unsigned(sens_hum)
                            + unsigned(sens_pm10) + unsigned(sens_press)
                            + to_unsigned(42, DATA_PRESS_LEN)
                        );
                        state <= set_checksum;
                    end if;
                when set_checksum =>
                    measurement_out(CHECKSUM_OFFSET downto CHECKSUM_OFFSET - 5) <= div_remainder(5 downto 0);
                    state <= idle;
                    ready <= '1';
            end case;
            if trigger > 0 and trigger_handled then
                trigger_handled := false;
            end if;
        end if;
    end process;
end arch;
