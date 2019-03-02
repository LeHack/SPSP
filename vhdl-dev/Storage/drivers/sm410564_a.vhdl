architecture main of sm410564 is
    type t_disp_state is (calculate, send, display, sleep);
    signal state : t_disp_state := calculate;
    signal reg_enable,
           reg_ready  : STD_LOGIC := '0';
    signal reg_input  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal div_number, div_quotient       : STD_LOGIC_VECTOR (15 DOWNTO 0) := (others => '0');
    signal div_denominator, div_remainder : STD_LOGIC_VECTOR ( 9 DOWNTO 0) := (others => '0');
begin
    shift_register : entity drivers.shift_reg PORT MAP (
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
        type digitsArr is array(3 downto 0) of Integer range 0 to 31;
        variable digits   : digitsArr := (others => 0);
        variable pval     : Unsigned(15 downto 0) := (others => '0');

        procedure division(constant step : in integer range 0 to 3) is begin
            case step is
                when 0 =>
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
            end case;
        end procedure;

        procedure split_to_digits(constant step : in integer range 0 to 3) is begin
            -- special case, value not set
            if dvalue = "1111111111111111" then
                digits := (others => 17);
            elsif data_format = hexadecimal then
                digits(3) := to_integer(dvalue(15 downto 12));
                digits(2) := to_integer(dvalue(11 downto  8));
                digits(1) := to_integer(dvalue( 7 downto  4));
                digits(0) := to_integer(dvalue( 3 downto  0));
            else -- mixed & decimal
                division(step);
            end if;
        end procedure;

        variable split_stage : integer range 0 to 3 := 0;
        variable send_fired  : boolean := false;
        -- 11 bits sould give each digit ~200Hz
        variable ref_sleep : unsigned(10 downto 0)  := (others => '0');
        variable digit, last_digit : Integer range 0 to 3 := 0;
    begin
        if rising_edge(clocks.CLK_1M19) then
            if enable = '0' then
                -- disable all outputs
                MLTPLX_CH  <= (others => '0');
                pval := (others => '0');
            else
                case state is
                    -- run on new input
                    when calculate =>
                        split_to_digits(split_stage);
                        if split_stage < 3 then
                            split_stage := split_stage + 1;
                        else
                            split_stage := 0;
                            state <= send;
                        end if;
                    when send =>
                        -- push next digit to registry
                        if reg_ready = '1' and not send_fired then
                            -- update the value in the registry to contain the next digit
                            reg_input <= Int_to_Seg(digits(digit), (dpoint(digit) = '1'));
                            reg_enable <= '1';
                            send_fired := true;
                        elsif reg_ready = '0' then
                            reg_enable <= '0';
                        elsif reg_ready = '1' and send_fired then
                            send_fired := false;
                            state <= display;
                        end if;
                    when display =>
                        -- disable the previous segment
                        MLTPLX_CH(last_digit) <= '0';
                        -- enable the current segment (registry must be set by now)
                        MLTPLX_CH(digit) <= '1';
                        -- loop trough digits
                        last_digit := digit;
                        if digit < 3 then
                            digit := digit + 1;
                        else
                            digit := 0;
                        end if;
                        -- wait a bit
                        state <= sleep;
                    when sleep =>
                        ref_sleep := ref_sleep + 1;
                        if ref_sleep = 0 then
                            -- send the next digit
                            state <= send;
                        elsif pval /= dvalue then
                            -- if new value is seen, reset to calculate
                            ref_sleep := (others => '0');
                            digit := 0;
                            pval := dvalue;
                            state <= calculate;
                        end if;
                end case;
            end if;
        end if;
    end process;
end main;
