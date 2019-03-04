library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity clock_divider is
    GENERIC (
        denominator : UNSIGNED(25 downto 0) := to_unsigned(42, 26) -- 50 MHz -> 1.19 MHz
    );
    PORT (
        clk_in  : IN  STD_LOGIC;
        clk_out : OUT STD_LOGIC := '0'
    );
END entity;
