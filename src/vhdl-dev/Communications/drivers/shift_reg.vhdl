library ieee;
    use ieee.std_logic_1164.all;
library ext, utils;
    use utils.utils.all;

entity shift_reg is
    PORT (
        clocks      :  IN t_clocks;
        enable      :  IN STD_LOGIC := '0';
        ready       : OUT STD_LOGIC := '1';
        input       :  IN STD_LOGIC_VECTOR(7 downto 0);
        REG_CLK,
        REG_LATCH,
        REG_DATA    : OUT STD_LOGIC
    );
END entity;
