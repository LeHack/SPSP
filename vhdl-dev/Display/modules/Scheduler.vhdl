library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, modules, utils;
    use utils.utils.all;

entity Scheduler is
    PORT (
        clocks    :  IN t_clocks;
        ready     : OUT STD_LOGIC := '0';

        -- Settings
        REFERENCE_PRESS     :  IN STD_LOGIC_VECTOR( 7 downto 0);
        read_freq_setting   :  IN STD_LOGIC_VECTOR( 5 DOWNTO 0);
        measurement_out     : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);

        -- I/O
        sensors_in          :    IN t_sensors_in;
        sensors_out         :   OUT t_sensors_out;
        sensors_inout       : INOUT t_sensors_inout
    );
END entity;
