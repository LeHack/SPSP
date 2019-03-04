
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library modules, utils;
    use utils.utils.all;

entity Main is
    GENERIC (
        HZ_DURATION  : UNSIGNED(25 downto 0) := to_unsigned(50000000, 26)
    );
    PORT (
        CLOCK_50 :  IN STD_LOGIC;
        KEYS     :  IN STD_LOGIC_VECTOR(1 downto 0);
        LED      : OUT STD_LOGIC_VECTOR(7 downto 0);
        read_freq_setting : IN STD_LOGIC_VECTOR( 5 downto 0);
        disp_timeout      : IN STD_LOGIC_VECTOR( 5 downto 0);

        storage_inout   : INOUT t_storage_inout;
        storage_out     : OUT   t_storage_out;
        sensors_in      : IN    t_sensors_in;
        sensors_inout   : INOUT t_sensors_inout;
        sensors_out     : OUT   t_sensors_out;
        display_out     : OUT   t_display_out
    );
END entity;
