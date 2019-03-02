library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library drivers, ext, utils;
    use utils.utils.all;

entity gp2y1010 is
    PORT (
        clocks     : IN t_clocks;

        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';
        output     : OUT UNSIGNED(8 downto 0); -- ug/m3

        ADC_SDAT   : IN STD_LOGIC;
        ADC_SADDR,
        ADC_CS_N,
        ADC_SCLK,
        PM_ILED    : OUT STD_LOGIC
    );
END entity;
