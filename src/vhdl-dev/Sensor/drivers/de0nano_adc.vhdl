library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, utils;
    use utils.utils.all;

entity de0nano_adc is
    PORT (
        clocks     : IN t_clocks;

        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';
        input      : IN  STD_LOGIC_VECTOR(15 downto 0);
        output     : OUT STD_LOGIC_VECTOR(15 downto 0);

        ADC_SDAT   : IN STD_LOGIC;
        ADC_SCLK,
        ADC_SADDR,
        ADC_CS_N   : OUT STD_LOGIC
    );
END entity;
