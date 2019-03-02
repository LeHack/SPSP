library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library drivers, modules, utils;
    use drivers.sm410564_formats.all;
    use utils.utils.all;

entity Main is
    GENERIC(
        HZ_DURATION  : UNSIGNED(25 downto 0) := to_unsigned(50000000, 26)
    );
    PORT (
        CLOCK_50   : IN STD_LOGIC;
        KEY        : IN STD_LOGIC_VECTOR(1 downto 0);
        DIPSW      : IN STD_LOGIC_VECTOR(3 downto 0);
        EXT_VALUE  : IN STD_LOGIC_VECTOR(3 downto 0) := (others => 'U');

        -- Component connections
        display_out   :   OUT t_display_out;
        storage_inout : INOUT t_storage_inout;
        storage_out   :   OUT t_storage_out
    );
END entity;
