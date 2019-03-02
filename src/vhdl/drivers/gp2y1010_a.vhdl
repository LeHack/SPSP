architecture arch of gp2y1010 is
    signal state : common_state_type := idle;
    signal adc_enable, adc_ready : STD_LOGIC := '0';
    signal adc_data              : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal div_number, div_quotient : STD_LOGIC_VECTOR (23 DOWNTO 0);
    signal div_denominator          : STD_LOGIC_VECTOR (11 DOWNTO 0);
begin
    adc : entity drivers.de0nano_adc PORT MAP (
        clocks => clocks,
        enable => adc_enable, ready => adc_ready,

        input => (others => '0'), output => adc_data,
        ADC_SADDR => ADC_SADDR, ADC_SDAT => ADC_SDAT,
        ADC_CS_N => ADC_CS_N, ADC_SCLK => ADC_SCLK
    );

    div_inst : entity ext.div24 PORT MAP (
        clock    => clocks.CLK_50M,
		numer	 => div_number,
		denom	 => div_denominator,
		quotient => div_quotient
	);

    GP2Y1010_DRV: process(clocks.CLK_1M19)
        -- the complete PM10 sampling cycle is 0.32ms
        -- virt_clk is 1.19MHz
        -- so with our vclock we need to count 382 cycles
        -- from that:
        --  * 0.28ms - 334 cycles - for the device to stabilize
        --  * 0.04ms -  48 cycles - for the readout
        -- after that we should wait 10ms before the next read (11906 cycles)
        constant READ_START  : integer := 334 + 10; -- wait a little bit more, since we only really need 7 cycles for the ADC reading
        constant READ_END    : integer := READ_START + 38;
        constant WAIT_CYCLES : integer := READ_END + 11906;
        -- to correctly calculate the sensor output voltage level, we need to
        constant PM10_BASE_V : std_logic_vector( 9 downto 0) := i2v(400,  10);   -- 400mV base voltage
        constant PM10_CONV_F : std_logic_vector( 4 downto 0) := i2v(17,    5);   -- 17/100 - mV to um/m3 rate
        constant ADC_VREF    : std_logic_vector(11 downto 0) := i2v(3300, 12);   -- 3.3V voltage reference
        constant ADC_RES     : std_logic_vector(11 downto 0) := (others => '1'); -- 12 bit resolution
        variable step        : integer range 0 to 3 := 0;

        procedure calc_pm10 is
        -- converts 12bit ADC value into mV and then to um/m3
            variable tmpV : unsigned(11 downto 0) := (others => '0');
        begin
            case step is
                when 1 =>
                    -- div_number <= mul_result; -- 24 bits
                    div_number <= std_logic_vector(unsigned(adc_data(11 downto 0)) * unsigned(ADC_VREF));
                    div_denominator <= ADC_RES; -- 12 bits
                when 2 =>
                    -- then take the result and convert into ug/m3 according to the sensor docs
                    -- we're dividing by full 12bits, so won't get more than 12 bits at the output
                    tmpV := unsigned(div_quotient(11 downto 0));
                    -- if the voltage is smaller than minimum, ignore the reading
                    if tmpV > unsigned(PM10_BASE_V) then
                        div_number <= "0000000" & std_logic_vector(tmpV * unsigned(PM10_CONV_F));
                        div_denominator <= i2v(100, 12);
                    else
                        output <= (others => '0');
                        step := 0; -- stop the calculation
                    end if;
                when 3 =>
                    -- store the calculated value in the output
                    output <= unsigned( div_quotient(8 downto 0) );
                when others => NULL;
            end case;

            if step > 0 then
                if step < 3 then
                    step := step + 1;
                else
                    step := 0;
                end if;
            end if;
        end procedure;

        variable iter    : unsigned(13 downto 0) := (3 => '1', others => '0');
        variable iled_on : boolean := false;

        procedure read_pm10_sensor is begin
            iter := iter + 1;
            -- handle PM10 reading via ADC
            if adc_ready = '1' and adc_enable = '0' then
                -- first iteration is skipped
                if iter = 1 then
                    -- set ILED to low
                    PM_ILED <= '0';
                    iled_on := true;
                elsif iled_on and iter = READ_START then
                    adc_enable <= '1';
                elsif iled_on and iter = READ_END then
                    -- set ILED to high and read the data retrieved from the ADC
                    PM_ILED <= '1';
                    iled_on := false;
                    -- start the calculation
                    step := 1;
                    calc_pm10;
                elsif step > 0 then
                    -- next stages
                    calc_pm10;
                elsif iter = WAIT_CYCLES then
                    iter := (others => '0');
                end if;
            elsif adc_ready = '0' then
                -- reset control signals
                adc_enable <= '0';
            end if;
        end procedure;

    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when idle =>
                    ready <= '1';
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                        read_pm10_sensor;
                    end if;
                when busy =>
                    read_pm10_sensor;
                    if iter = 0 then
                      state <= idle;
                    end if;
                when others => state <= idle;
            end case;
        end if;
    end process;
end arch;
