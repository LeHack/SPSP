library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, segdispl;
    use segdispl.sm410564_formats.all;
library utils;
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
