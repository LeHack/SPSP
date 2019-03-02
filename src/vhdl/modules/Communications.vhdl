library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library drivers, utils;
    use utils.utils.all;
    use drivers.rn4020_utils.all;

entity Communications is
    PORT (
        clocks      :  IN t_clocks;
        enable      :  IN STD_LOGIC := '0';
        busy, ready : OUT STD_LOGIC := '0';

        -- storage flag set
        storage_syn : OUT STD_LOGIC := '0';
        storage_ack :  IN STD_LOGIC := '0';

        -- settings
        read_freq_setting : IN STD_LOGIC_VECTOR(5 downto 0);
        btname            : IN STRING(1 to 10);
        timestamp         : IN STD_LOGIC_VECTOR(19 downto 0);

        -- I/O
        storage_request  : OUT t_storage_request;
        storage_response : IN  t_storage_response;
        comms_in         : IN  t_comms_in;
        comms_out        : OUT t_comms_out;
        sleep_led        : OUT std_logic
    );
END entity;
