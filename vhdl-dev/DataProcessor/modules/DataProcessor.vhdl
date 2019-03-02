library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext, utils;
    use utils.utils.all;

entity DataProcessor is
    PORT (
        clocks    :  IN t_clocks;
        enable    :  IN STD_LOGIC := '0';
        ready     : OUT STD_LOGIC := '0';

        -- Settings
        pm10_norm   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        sample_size : IN STD_LOGIC_VECTOR(5 DOWNTO 0);

        -- I/O
        data_in   :  IN STD_LOGIC_VECTOR(DATA_TEMP_OFFSET  DOWNTO 0);
        data_out  : OUT STD_LOGIC_VECTOR(DATA_PM10P_OFFSET DOWNTO 0) := (others => '0');
        checksum  : OUT STD_LOGIC_VECTOR(CHECKSUM_LEN - 1  DOWNTO 0) := (others => '0')
    );
END entity;
