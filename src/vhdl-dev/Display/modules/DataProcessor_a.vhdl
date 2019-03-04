architecture arch of DataProcessor is
    signal state : common_state_type := idle;
    signal div_number, div_quotient       : STD_LOGIC_VECTOR (23 DOWNTO 0) := (others => '0');
    signal div_denominator, div_remainder : STD_LOGIC_VECTOR (11 DOWNTO 0) := (others => '0');
    signal mult_a         : STD_LOGIC_VECTOR(16 DOWNTO 0) := (others => '0');
    signal mult_b         : STD_LOGIC_VECTOR( 6 DOWNTO 0) := (others => '0');
    signal mult_result    : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
    signal sample_half    : STD_LOGIC_VECTOR( 4 downto 0);
    signal pm10_norm_half : STD_LOGIC_VECTOR( 6 downto 0);
begin
    div_inst : entity ext.div24 PORT MAP (
        clock    => clocks.CLK_1M19,
		numer	 => div_number,
		denom	 => div_denominator,
		quotient => div_quotient,
        remain   => div_remainder
	);

    mult_inst : entity ext.mult24 PORT MAP (
        clock    => clocks.CLK_1M19,
		dataa	 => mult_a,
		datab	 => mult_b,
		result   => mult_result
	);

    sample_half    <= sample_size(5 downto 1);
    pm10_norm_half <= pm10_norm(7 downto 1);

    DATA_PROCESSOR: process(clocks.CLK_0M5)
        alias    DATA_TEMP_MSB  is DATA_TEMP_OFFSET;
        constant DATA_TEMP_LSB  : integer := DATA_TEMP_OFFSET  + 1 - DATA_TEMP_LEN;
        alias    DATA_HUM_MSB   is DATA_HUM_OFFSET;
        constant DATA_HUM_LSB   : integer := DATA_HUM_OFFSET   + 1 - DATA_HUM_LEN;
        alias    DATA_PM10_MSB  is DATA_PM10_OFFSET;
        constant DATA_PM10_LSB  : integer := DATA_PM10_OFFSET  + 1 - DATA_PM10_LEN;
        alias    DATA_PM10P_MSB is DATA_PM10P_OFFSET;
        constant DATA_PM10P_LSB : integer := DATA_PM10P_OFFSET + 1 - DATA_PM10P_LEN;
        alias    DATA_PRESS_MSB is DATA_PRESS_OFFSET;
        constant DATA_PRESS_LSB : integer := DATA_PRESS_OFFSET + 1 - DATA_PRESS_LEN;

        alias temp_in       is data_in (DATA_TEMP_MSB  downto DATA_TEMP_LSB);
        alias temp_out      is data_out(DATA_TEMP_MSB  downto DATA_TEMP_LSB);
        alias hum_in        is data_in (DATA_HUM_MSB   downto DATA_HUM_LSB);
        alias hum_out       is data_out(DATA_HUM_MSB   downto DATA_HUM_LSB);
        alias pm10_in       is data_in (DATA_PM10_MSB  downto DATA_PM10_LSB);
        alias pm10_out      is data_out(DATA_PM10_MSB  downto DATA_PM10_LSB);
        alias press_in      is data_in (DATA_PRESS_MSB downto DATA_PRESS_LSB);
        alias press_out     is data_out(DATA_PRESS_MSB downto DATA_PRESS_LSB);
        alias pm10_perc_out is data_out(DATA_PM10P_MSB downto DATA_PM10P_LSB);

        -- add X bits to every variable, to account for fractions
        constant FRBIT : integer := 6; -- if changed, please also choose a division module with a wider I/O
        variable temp_prev,  temp_avg,  temp_cached  : unsigned(DATA_TEMP_LEN  + FRBIT - 1 downto 0) := (others => '0');
        variable hum_prev,   hum_avg,   hum_cached   : unsigned(DATA_HUM_LEN   + FRBIT - 1 downto 0) := (others => '0');
        variable pm10_prev,  pm10_avg,  pm10_cached  : unsigned(DATA_PM10_LEN  + FRBIT - 1 downto 0) := (others => '0');
        variable press_prev, press_avg, press_cached : unsigned(DATA_PRESS_LEN + FRBIT - 1 downto 0) := (others => '0');
        variable pm10_perc : unsigned(DATA_PM10P_LEN + FRBIT - 1 downto 0) := (others => '0');

        -- final value store just before output, for checksum calc
        variable temp_rdy  : std_logic_vector(DATA_TEMP_LEN  - 1 downto 0) := (others => '0');
        variable hum_rdy   : std_logic_vector(DATA_HUM_LEN   - 1 downto 0) := (others => '0');
        variable pm10_rdy  : std_logic_vector(DATA_PM10_LEN  - 1 downto 0) := (others => '0');
        variable press_rdy : std_logic_vector(DATA_PRESS_LEN - 1 downto 0) := (others => '0');

        constant PM10MULT        : std_logic_vector(6 downto 0) := i2v(100, 7);
        constant STEP_AVG_CALC   : integer := 2;
        constant STEP_CACHE_CALC : integer := STEP_AVG_CALC   + 5;
        constant STEP_PM10_CALC  : integer := STEP_CACHE_CALC + 9;
        constant STEP_OUTPUT     : integer := STEP_PM10_CALC  + 3;
        constant STEP_FINAL      : integer := STEP_OUTPUT     + 1;
        variable step : integer range 1 to STEP_FINAL := 1;

        function calc_avg(
                signal input, div_q, div_r, smpl_half : in STD_LOGIC_VECTOR;
                constant len : in integer;
                constant cached, prev : in unsigned
            ) return unsigned is
            constant hi_bit : integer := len + FRBIT - 1;
            variable avg : unsigned(hi_bit downto 0);
        begin
            avg := unsigned(div_q(hi_bit downto 0)) + cached;
            if prev(hi_bit downto FRBIT) = avg(hi_bit downto FRBIT) and avg(hi_bit downto FRBIT) /= unsigned(input) then
                -- knock it off balance
                if avg(hi_bit downto FRBIT) > unsigned(input) then
                    avg := avg - 32;
                else
                    avg := avg + 32;
                end if;
            elsif unsigned(div_r) > unsigned(smpl_half) then
                avg := avg + 1;
            end if;
            return avg;
        end function;

        function round(constant input : in unsigned; constant len : in integer) return std_logic_vector is
            constant hi_bit : integer := len + FRBIT - 1;
            variable cl : unsigned(hi_bit downto FRBIT);
        begin
            cl := input(hi_bit downto FRBIT);
            if input(FRBIT - 1 downto 0) > 32 then
                cl := cl + 1;
            end if;
            return std_logic_vector(cl);
        end function;

        procedure run_processing is
            -- steps required to perform the data processing
            -- 1. check for sample_size <= 1, if true empty the cache and jump to pt 5
            -- 2. check for cached values or
            --     if true: store the split data in avg and jump to pt 4
            -- 3. for every variable (temp, hum, pm10, press):
            --     - divide the input value by sample_size (to get single sample value)
            --     - add *_cached to the result and store under *_avg
            --     - if the remainder is >= 0.5 sample size, round up
            --     - perform additional stabilization check
            --       (if the calculations reach a deadend, nudge them in the correct direction)
            -- 4. in order to calculate the new *_cached values:
            --     - muliply each *_avg value by sample_size - 1 and divide it by sample_size
            --     - store the result under *_cached
            --     - if the remainder is >= 0.5 sample size, round up
            -- 5. multiply the pm10_avg by 100 and divide the result by pm10_norm
            -- 6. store the result under pm10_perc and round it if required
            -- 7. store the avg and pm10 percentage values in the output struct
            --    perform additional rounding when cutting of the extra 6 bits
            variable init_avg : boolean := false;
        begin
            -- reset div_number at every run
            div_number <= (others => '0');
            case step is
                when 1 =>
                    if unsigned(sample_size) <= 1 then
                        init_avg := true;
                        -- reset cached
                        temp_cached  := (others => '0');
                        hum_cached   := (others => '0');
                        pm10_cached  := (others => '0');
                        press_cached := (others => '0');
                        -- go to final steps (calculate PM10 norm percentage)
                        step := STEP_PM10_CALC - 1;
                    elsif press_cached = (0 to DATA_PRESS_LEN + FRBIT - 1 => '0') then
                        init_avg := true;
                        -- skip directly to the cache calculation step
                        step := STEP_CACHE_CALC - 1;
                    else
                        -- store the previous version for stabilization detection
                        temp_prev  := temp_avg;
                        hum_prev   := hum_avg;
                        pm10_prev  := pm10_avg;
                        press_prev := press_avg;
                    end if;
                    if init_avg then
                        temp_avg  := unsigned(temp_in)  & (1 to FRBIT => '0');
                        hum_avg   := unsigned(hum_in)   & (1 to FRBIT => '0');
                        pm10_avg  := unsigned(pm10_in)  & (1 to FRBIT => '0');
                        press_avg := unsigned(press_in) & (1 to FRBIT => '0');
                    end if;
                when STEP_AVG_CALC =>
                    div_denominator <= "000000" & sample_size;
                    div_number(DATA_TEMP_LEN + FRBIT - 1 downto 0) <= temp_in & (1 to FRBIT => '0');
                when STEP_AVG_CALC + 1 =>
                    temp_avg := calc_avg(temp_in, div_quotient, div_remainder, sample_half, DATA_TEMP_LEN, temp_cached, temp_prev);
                    div_number(DATA_HUM_LEN + FRBIT - 1 downto 0) <= hum_in & (1 to FRBIT => '0');
                when STEP_AVG_CALC + 2 =>
                    hum_avg := calc_avg(hum_in, div_quotient, div_remainder, sample_half, DATA_HUM_LEN, hum_cached, hum_prev);
                    div_number(DATA_PM10_LEN + FRBIT - 1 downto 0) <= pm10_in & (1 to FRBIT => '0');
                when STEP_AVG_CALC + 3 =>
                    pm10_avg := calc_avg(pm10_in, div_quotient, div_remainder, sample_half, DATA_PM10_LEN, pm10_cached, pm10_prev);
                    div_number(DATA_PRESS_LEN + FRBIT - 1 downto 0) <= press_in & (1 to FRBIT => '0');
                when STEP_AVG_CALC + 4 =>
                    press_avg := calc_avg(press_in, div_quotient, div_remainder, sample_half, DATA_PRESS_LEN, press_cached, press_prev);
                when STEP_CACHE_CALC =>
                    mult_a <= (others => '0');
                    mult_a(DATA_TEMP_LEN + FRBIT - 1 downto 0) <= std_logic_vector(temp_avg);
                    mult_b <= "0" & std_logic_vector(unsigned(sample_size) - 1);
                when STEP_CACHE_CALC + 1 =>
                    -- reset the denominator (in case of a jump)
                    div_denominator <= "000000" & sample_size;
                    div_number <= mult_result;
                when STEP_CACHE_CALC + 2 =>
                    temp_cached := unsigned(div_quotient(DATA_TEMP_LEN + FRBIT - 1 downto 0));
                    if unsigned(div_remainder) >= unsigned(sample_half) then
                        temp_cached := temp_cached + 1;
                    end if;
                    mult_a <= (others => '0');
                    mult_a(DATA_HUM_LEN + FRBIT - 1 downto 0) <= std_logic_vector(hum_avg);
                when STEP_CACHE_CALC + 3 =>
                    div_number <= mult_result;
                when STEP_CACHE_CALC + 4 =>
                    hum_cached := unsigned(div_quotient(DATA_HUM_LEN + FRBIT - 1 downto 0));
                    if unsigned(div_remainder) >= unsigned(sample_half) then
                        hum_cached := hum_cached + 1;
                    end if;
                    mult_a <= (others => '0');
                    mult_a(DATA_PM10_LEN + FRBIT - 1 downto 0) <= std_logic_vector(pm10_avg);
                when STEP_CACHE_CALC + 5 =>
                    div_number <= mult_result;
                when STEP_CACHE_CALC + 6 =>
                    pm10_cached := unsigned(div_quotient(DATA_PM10_LEN + FRBIT - 1 downto 0));
                    if unsigned(div_remainder) >= unsigned(sample_half) then
                        pm10_cached := pm10_cached + 1;
                    end if;
                    mult_a <= (others => '0');
                    mult_a(DATA_PRESS_LEN + FRBIT - 1 downto 0) <= std_logic_vector(press_avg);
                when STEP_CACHE_CALC + 7 =>
                    div_number <= mult_result;
                when STEP_CACHE_CALC + 8 =>
                    press_cached := unsigned(div_quotient(DATA_PRESS_LEN + FRBIT - 1 downto 0));
                    if unsigned(div_remainder) >= unsigned(sample_half) then
                        press_cached := press_cached + 1;
                    end if;
                when STEP_PM10_CALC =>
                    mult_a <= (others => '0');
                    mult_a(DATA_PM10_LEN + FRBIT - 1 downto 0) <= std_logic_vector(pm10_avg);
                    mult_b <= PM10MULT;
                when STEP_PM10_CALC + 1 =>
                    div_number <= mult_result;
                    div_denominator <= "0000" & pm10_norm;
                when STEP_PM10_CALC + 2 =>
                    pm10_perc := unsigned(div_quotient(DATA_PM10P_LEN + FRBIT - 1 downto 0));
                    if unsigned(div_remainder) >= unsigned(pm10_norm_half) then
                        pm10_perc := pm10_perc + 1;
                    end if;
                when STEP_OUTPUT =>
                    temp_rdy      := round(temp_avg,  DATA_TEMP_LEN);
                    hum_rdy       := round(hum_avg,   DATA_HUM_LEN);
                    pm10_rdy      := round(pm10_avg,  DATA_PM10_LEN);
                    press_rdy     := round(press_avg, DATA_PRESS_LEN);

                    -- finally calculate the up-to-date checksum
                    div_number(DATA_PRESS_LEN - 1 downto 0) <= std_logic_vector(
                          unsigned(temp_rdy) + unsigned(hum_rdy)
                        + unsigned(pm10_rdy) + unsigned(press_rdy)
                        + to_unsigned(42, DATA_PRESS_LEN)
                    );
                    div_denominator <= i2v(61, 12);
                when STEP_OUTPUT + 1 =>
                    temp_out      <= temp_rdy;
                    hum_out       <= hum_rdy;
                    pm10_out      <= pm10_rdy;
                    press_out     <= press_rdy;
                    pm10_perc_out <= round(pm10_perc, DATA_PM10P_LEN);
                    checksum      <= div_remainder(CHECKSUM_LEN - 1 DOWNTO 0);
            end case;

            if step < STEP_FINAL then
                step := step + 1;
            else
                step := 1;
            end if;
        end procedure;
    begin
        if rising_edge(clocks.CLK_0M5) then
            case state is -- initialize, idle, busy, error
                when idle =>
                    ready <= '1';
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                    end if;
                when busy =>
                    run_processing;
                    -- back to beginning?
                    if step = 1 then
                        state <= idle;
                    end if;
                when others => state <= idle;
            end case;
        end if;
    end process;
end arch;
