library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, utils;
    use utils.utils.all;

entity lps331ap is
    PORT (
        clocks     : IN t_clocks;
        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';

        PRESS_SDA,
        PRESS_SCL  : INOUT STD_LOGIC;
        PRESS_SDO,
        PRESS_CS   : OUT STD_LOGIC;
        out_temperature : OUT UNSIGNED( 6 downto 0) := (others => '0');
        out_pressure    : OUT UNSIGNED(10 downto 0) := (others => '0')
    );
END entity;
