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
        CLOCK_50   : IN STD_LOGIC;

        sensors_in      :    IN t_sensors_in;
        sensors_inout   : INOUT t_sensors_inout;
        sensors_out     :   OUT t_sensors_out;
        storage_inout   : INOUT t_storage_inout;
        storage_out     :   OUT t_storage_out
    );
END entity;
