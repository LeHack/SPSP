library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, utils;
    use utils.utils.all;

entity shift_reg is
    PORT (
        clocks      :  IN t_clocks;
        enable      :  IN STD_LOGIC := '0';
        ready       : OUT STD_LOGIC := '0';
        input       :  IN STD_LOGIC_VECTOR(7 downto 0);
        REG_CLK,
        REG_LATCH,
        REG_DATA    : OUT STD_LOGIC
    );
END entity;

architecture SPI of shift_reg is begin
    DISPLAY_REG_DRV: process(clocks.CLK_1M19)
        variable sleep : unsigned(3 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_1M19) then
            sleep := sleep + 1;
            if sleep = 0 then
                ready <= '0' when enable = '1' else '1';
            end if;
        end if;
    end process;

    REG_CLK   <= '0';
    REG_LATCH <= '0';
    REG_DATA  <= '0';
end architecture;
