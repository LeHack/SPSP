architecture main of sm410564 is
    type t_disp_state is (calculate, send, display);
    signal state : t_disp_state := calculate;
    signal reg_enable,
           reg_ready  : STD_LOGIC := '0';
    signal reg_input  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal div_number, div_quotient       : STD_LOGIC_VECTOR (15 DOWNTO 0) := (others => '0');
    signal div_denominator, div_remainder : STD_LOGIC_VECTOR ( 9 DOWNTO 0) := (others => '0');
    signal multiplex : unsigned(1 downto 0) := (others => '0');
    signal switch_digit, enable_mltplx : std_logic := '0';
begin
    MLTPLX_CH <= std_logic_vector(multiplex);
    MLTPLX_ENA <= not enable_mltplx;

    shift_register : entity drivers.shift_reg GENERIC MAP (LATCH_ENABLED => '0') PORT MAP (
        clocks => clocks,

        -- Control
        enable => reg_enable,
        ready  => reg_ready,

        -- I/O
        input => reg_input,
        REG_CLK => REG_CLK, REG_LATCH => REG_LATCH, REG_DATA => REG_DATA
    );

    div_inst : entity ext.div16 PORT MAP (
        clock    => clocks.CLK_50M,
		numer	 => div_number,
		denom	 => div_denominator,
		quotient => div_quotient,
		remain	 => div_remainder
	);

    CYCLE_DRV: process(clocks.CLK_0M5)
        variable cnt : unsigned(8 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_0M5) then
            cnt := cnt + 1;
            if cnt = 0 then
                switch_digit <= '1';
            elsif switch_digit = '1' then
                switch_digit <= '0';
            end if;
        end if;
    end process;

    DISPLAY_DRV: process(clocks.CLK_1M19)
        type digitsArr is array(3 downto 0) of Integer range 0 to 31;
        variable digits   : digitsArr := (others => 0);
        variable pval     : Unsigned(15 downto 0) := (others => '0');

        procedure division(variable step : inout integer range 0 to 4) is begin
            case step is
                when 0 =>
                    -- val / 1000
                    div_number <= std_logic_vector(dvalue);
                    div_denominator <= i2v(1000, 10);
                when 1 =>
                    -- rem / 100
                    digits(3) := to_integer(unsigned(div_quotient));
                    div_number <= "000000" & div_remainder;
                    div_denominator <= i2v(100, 10);
                when 2 =>
                    -- rem / 10
                    digits(2) := to_integer(unsigned(div_quotient));
                    div_number <= "000000" & div_remainder;
                    div_denominator <= i2v(10, 10);
                when 3 =>
                    -- rem / 10, rem mod 10
                    digits(1) := to_integer(unsigned(div_quotient));
                    digits(0) := to_integer(unsigned(div_remainder));
                    if data_format = decimal and digits(3) > 9 then
                        div_number <= std_logic_vector(to_unsigned(digits(3), 16));
                    else
                        step := 4;
                        -- special case, negative temperature
                        if digits(3) = 20 then
                            digits(3) := 12; -- normal C
                            digits(2) := 17; -- minus
                        end if;
                    end if;
                when 4 =>
                    digits(3) := to_integer(unsigned(div_remainder));
            end case;
        end procedure;

        procedure split_to_digits(variable step : inout integer range 0 to 4) is begin
            -- special case, value not set
            if dvalue = (0 to 15 => '1') then
                digits := (others => 17);
                step := 4;
            elsif data_format = hexadecimal then
                digits(3) := to_integer(dvalue(15 downto 12));
                digits(2) := to_integer(dvalue(11 downto  8));
                digits(1) := to_integer(dvalue( 7 downto  4));
                digits(0) := to_integer(dvalue( 3 downto  0));
                step := 4;
            else -- mixed & decimal
                division(step);
            end if;
        end procedure;

        function has_digit(
                constant curval : in digitsArr;
                constant digit  : in unsigned(1 downto 0);
                constant format : in data_display_formats
            ) return boolean is
            constant i : integer range 0 to 3 := to_integer(digit);
            variable ret : boolean := false;
        begin
            if format = hexadecimal and i > 1 and curval(2) = 0 and curval(3) = 0 then
                return false;
            end if;

            case i is
                when 0 => ret := true;
                when 1 => ret := ((curval(3) > 0 and curval(3) < 10) or curval(2) > 0 or curval(1) > 0);
                when 2 => ret := ((curval(3) > 0 and curval(3) < 10) or curval(2) > 0);
                when 3 => ret := (curval(3) > 0);
            end case;

            return ret;
        end function;

        variable split_stage : integer range 0 to 4 := 0;
        variable send_fired,
                 switch_digit_fired : boolean := false;
        variable digit       : Integer range 0 to 3 := 0;
    begin
        if rising_edge(clocks.CLK_1M19) then
            if enable = '0' then
                -- reset all flags
                multiplex <= (others => '0');
                enable_mltplx <= '0';
                pval := (others => '0');
                switch_digit_fired := false;
                send_fired := false;
                split_stage := 0;
                reg_enable <= '0';
                state <= calculate;
            else
                case state is
                    -- run on new input
                    when calculate =>
                        split_to_digits(split_stage);
                        if split_stage < 4 then
                            split_stage := split_stage + 1;
                        else
                            split_stage := 0;
                            state <= send;
                        end if;
                    when send =>
                        -- push next digit to registry
                        if reg_ready = '1' and not send_fired then
                            -- update the value in the registry to contain the next digit
                            digit := to_integer(multiplex);
                            reg_input <= Int_to_Seg(digits(digit), (dpoint(digit) = '1'));
                            reg_enable <= '1';
                            send_fired := true;
                        elsif reg_ready = '0' then
                            reg_enable <= '0';
                        elsif reg_ready = '1' and reg_enable = '0' then
                            send_fired := false;
                            state <= display;
                        end if;
                    when display =>
                        if switch_digit = '1' and not switch_digit_fired then
                            -- send the next digit
                            state <= send;
                            switch_digit_fired := true;
                            multiplex <= multiplex + 1;
                            if leading_zeroes = '1' or has_digit(digits, multiplex + 1, data_format) then
                                enable_mltplx <= enable;
                            else
                                enable_mltplx <= '0';
                            end if;
                        elsif pval /= dvalue then
                            -- if new value is seen, reset to calculate
                            multiplex <= (others => '0');
                            digit := 0;
                            pval := dvalue;
                            state <= calculate;
                        end if;
                end case;
                if switch_digit = '0' and switch_digit_fired then
                    switch_digit_fired := false;
                end if;
            end if;
        end if;
    end process;
end main;
