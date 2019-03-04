library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ext;
library utils;
use utils.utils.all;

entity eeprom is
    PORT (
        clocks     : IN t_clocks;
        rw,         -- '0' Read, '1' Read/Write
        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';

        addr,
        data_in    : IN STD_LOGIC_VECTOR(7 downto 0);
        data_out   : OUT STD_LOGIC_VECTOR(7 downto 0);

        SDA, SCL   : INOUT STD_LOGIC
    );
END entity;
