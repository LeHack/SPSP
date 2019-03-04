library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library drivers, utils;
    use utils.utils.all;

entity Storage is
    PORT (
        clocks      : IN t_clocks;

        -- Flags
        reset_settings,
        rw,         -- '0' Read, '1' Read/Write
        enable      : IN  STD_LOGIC := '0';
        overflow,
        error,
        ready       : OUT STD_LOGIC := '0';

        -- Data
        data_type   : IN storage_data_type;
        timestamp   : IN  STD_LOGIC_VECTOR(19 DOWNTO 0) := (others => '0');
        data_in     : IN  STD_LOGIC_VECTOR(59 DOWNTO 0) := (others => '0');
        data_out    : OUT STD_LOGIC_VECTOR(59 DOWNTO 0) := (others => '0');

        -- I/O
        storage_inout : INOUT t_storage_inout;
        storage_out   : OUT   t_storage_out
    );
END entity;
