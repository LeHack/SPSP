library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, utils;
    use utils.utils.all;

entity dht11 is
    PORT (
        clocks     : IN t_clocks;
        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';

        HUM_DAT         : INOUT STD_LOGIC;
        out_humidity,
        out_temperature : OUT UNSIGNED(6 downto 0) := (others => '0')
    );
END entity;
