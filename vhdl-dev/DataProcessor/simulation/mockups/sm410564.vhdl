library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library segdispl, utils;
    use segdispl.sm410564_formats.all;
    use utils.utils.all;

entity sm410564 is
    PORT (
        clocks      : IN t_clocks;
        REG_CLK,
        REG_LATCH,
        REG_DATA    : OUT STD_LOGIC := '0';
        MLTPLX_CH   : OUT STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

        -- by default we display data in mixed mode to present full 14bits on the counter 1 hex + 3 decimals
        -- this is usefull when displaying data with values < 1000 when you want to add a single letter label
        -- other modes are: decimal and hexadecimal
        data_format : data_display_formats := mixed;
        dvalue      : IN UNSIGNED(15 downto 0) := (others => '1');
        dpoint      : IN UNSIGNED( 3 downto 0) := (others => '0') -- disabled by default
    );
END entity;

architecture main of sm410564 is begin
    DISPLAY_MOCK: process(clocks.CLK_1M19)
        variable sleep : unsigned(3 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_1M19) then
            sleep := sleep + 1;
        end if;
    end process;
end main;
