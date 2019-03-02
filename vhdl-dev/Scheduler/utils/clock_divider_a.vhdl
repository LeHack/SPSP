-- synthesis library utils
architecture arch of clock_divider is
begin
    CLK_DIVIDER: process(clk_in)
        constant div_cnt : unsigned(24 downto 0) := denominator(25 downto 1);
        variable cnt : unsigned(24 downto 0) := (others => '0');
    begin
        if rising_edge(clk_in) then
            cnt := cnt + 1;
            if cnt = div_cnt then
                cnt := (others => '0');
                clk_out <= not clk_out;
            end if;
        end if;
    end process;
end arch;
