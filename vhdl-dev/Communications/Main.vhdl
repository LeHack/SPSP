library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library drivers, modules, utils;
    use drivers.sm410564_formats.all;
    use utils.fake_mem.all;
    use utils.utils.all;

entity Main is
    GENERIC(
        HZ_DURATION  : UNSIGNED(25 downto 0) := to_unsigned(50000000, 26)
    );
    PORT (
        CLOCK_50 : IN STD_LOGIC := '1';
        KEYS     : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
        LED      : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);

        -- pass-thru wiring for internal modules
        comms_in      : IN    t_comms_in;
        comms_out     : OUT   t_comms_out;
        storage_inout : INOUT t_storage_inout;
        storage_out   : OUT   t_storage_out;
        display_out   : OUT   t_display_out
    );
END entity;
