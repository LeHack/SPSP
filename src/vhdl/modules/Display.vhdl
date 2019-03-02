library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library drivers, utils;
    use drivers.sm410564_formats.all;
    use utils.utils.all;

entity Display is
    PORT (
        clocks      :  IN t_clocks;

        -- flags
        enable      :  IN STD_LOGIC := '0';
        ready       : OUT STD_LOGIC := '0';
        displaying  : OUT STD_LOGIC := '0';

        -- settings and data
        timeout     :  IN STD_LOGIC_VECTOR(5 downto 0) := i2v(10, 6);
        data        :  IN STD_LOGIC_VECTOR(DATA_TEMP_OFFSET + 10 DOWNTO 0);
        dpoint      :  IN STD_LOGIC_VECTOR(3 downto 0);
        keys        :  IN STD_LOGIC_VECTOR(1 downto 0);

        -- I/O
        display_out : OUT t_display_out
    );
END entity;
