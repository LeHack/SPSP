architecture main of sm410564 is
    signal reg_enable,
           reg_ready  : STD_LOGIC := '0';
    signal reg_input  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal div_number, div_quotient       : STD_LOGIC_VECTOR (15 DOWNTO 0);
    signal div_denominator, div_remainder : STD_LOGIC_VECTOR ( 9 DOWNTO 0);
begin
    shift_register : entity segdispl.shift_reg PORT MAP (
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

    DISPLAY_DRV: process(clocks.CLK_1M19)
        -- 11 bits sould give each digit ~200Hz
        variable ref_sleep : unsigned(10 downto 0)  := (others => '0');
        variable digit, next_digit : Integer range 0 to 3 := 0;
        type digitsArr is array(3 downto 0) of Integer range 0 to 17;
        variable digits   : digitsArr := (others => 0);
        variable dividing : Boolean := false;
        variable pval     : Unsigned(15 downto 0) := (others => '0');

        procedure division(step : in unsigned) is begin
            case to_integer(step) is
                when 0 =>
                    dividing := true;
                    -- val / 1000
                    div_number <= std_logic_vector(dvalue);
                    div_denominator <= i2v(1000, 10);
                when 1 =>
                    -- rem / 100
                    digits(3) := to_integer(unsigned(div_quotient));
                    if data_format = decimal and digits(3) > 9 then
                        digits(3) := digits(3) - 10;
                    end if;
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
                    dividing := false;
                when others => NULL;
            end case;
        end procedure;

        procedure split_to_digits(step : in unsigned) is begin
            -- special case, value not set
            if dvalue = "1111111111111111" then
                pval := dvalue;
                digits := (others => 17);
            elsif data_format = hexadecimal then
                pval := dvalue;
                digits(3) := to_integer(dvalue(15 downto 12));
                digits(2) := to_integer(dvalue(11 downto  8));
                digits(1) := to_integer(dvalue( 7 downto  4));
                digits(0) := to_integer(dvalue( 3 downto  0));
            else -- mixed & decimal
                if step = 0 then
                    pval := dvalue;
                end if;
                division(step);
            end if;
        end procedure;

    begin
        if rising_edge(clocks.CLK_1M19) then
            if ref_sleep < 4 and next_digit = 0 and (dividing or pval /= dvalue) then
                -- run a 4 step division to get prepare a digit for each segment
                split_to_digits(ref_sleep);
            elsif ref_sleep = 4 and reg_ready = '1' then
                -- update the value in the registry to contain the next digit
                reg_input <= Int_to_Seg(digits(next_digit), (dpoint(next_digit) = '1'));
                reg_enable <= '1';
            elsif reg_ready = '0' then
                reg_enable <= '0';
            -- storing the value in the registry takes 6 virt_clk ticks
            elsif ref_sleep = 10 then
                -- disable the previous segment
                MLTPLX_CH(digit) <= '0';
                -- enable the current segment (registry must be set by now)
                MLTPLX_CH(next_digit) <= '1';
                -- increment selected and last digits
                digit := next_digit;
                if next_digit = 3 then
                    next_digit := 0;
                else
                    next_digit := digit + 1;
                end if;
            end if;
            ref_sleep := ref_sleep + 1;
        end if;
    end process;
end main;
