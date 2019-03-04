library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library drivers, utils;
    use utils.utils.all;

entity Sensor is
    PORT (
        clocks : IN t_clocks;

        enable :  IN STD_LOGIC := '0'; -- single fire mode, to init another reading it needs to be toggled
        ready  : OUT STD_LOGIC := '0';

        -- Settings
        REFERENCE_PRESS : IN STD_LOGIC_VECTOR( 7 downto 0);

        -- Output data
        temperature,
        humidity      : OUT STD_LOGIC_VECTOR( 6 downto 0) := (others => '0');
        pressure      : OUT STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
        pm10_reading  : OUT STD_LOGIC_VECTOR( 8 downto 0) := (others => '0');

        -- I/O
        sensors_in    :    IN t_sensors_in;
        sensors_out   :   OUT t_sensors_out;
        sensors_inout : INOUT t_sensors_inout
    );
END entity;
