library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library drivers, ext, utils;
    use drivers.rn4020_utils.all;
    use utils.utils.all;

entity rn4020 is
    GENERIC(
        MAX_BUF_BYTE : INTEGER := 20 -- 20 bytes
    );
    PORT (
        clocks        :  IN t_clocks;
        rw, enable    :  IN STD_LOGIC := '0';
        ready         : OUT STD_LOGIC := '0';
        addr          :  IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        data_in       :  IN STD_LOGIC_VECTOR(MAX_BUF_BYTE * 8 - 1 DOWNTO 0);
        data_out      : OUT STD_LOGIC_VECTOR(MAX_BUF_BYTE * 8 - 1 DOWNTO 0);
        device_name   :  IN STRING := "";

        WAKE_SW,
        WAKE_HW,
        TX            : OUT STD_LOGIC;
        RX            :  IN STD_LOGIC;
        init_progress : OUT UNSIGNED( 3 downto 0) -- can be used to monitor the initialization
    );
END entity;
