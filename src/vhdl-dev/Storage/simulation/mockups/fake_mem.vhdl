library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.all;
library utils;
    use utils.utils.all;

package fake_mem is
    constant fake_sdram_size : integer := 71;

    subtype bt_row is std_logic_vector(159 downto 0);
    type bt_mem is array (1 to 9) of bt_row;
    subtype sdram_pack is std_logic_vector(15 downto 0);
    type sdram_mem is array (0 to fake_sdram_size * 4 - 1) of sdram_pack;

    function get_fake_data(constant I: in Integer) return std_logic_vector;
end package;

package body fake_mem is
    function get_fake_data(constant I: in Integer) return std_logic_vector is
        variable result : std_logic_vector(39 downto 0) := (others => '0');
    begin
        result(10 downto  0) := i2v(I + 1, 11);
        result(19 downto 11) := i2v(I + 1,  9);
        result(26 downto 20) := i2v(I + 1,  7);
        result(33 downto 27) := i2v(I + 1,  7);
        result(39 downto 34) := i2v(4 * (I + 1) mod 61, 6);
        return result;
    end function;
end package body;
