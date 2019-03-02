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
        result(DATA_PRESS_OFFSET downto DATA_PRESS_OFFSET + 1 - DATA_PRESS_LEN) := i2v(I + 1, DATA_PRESS_LEN);
        result(DATA_PM10_OFFSET  downto DATA_PM10_OFFSET  + 1 - DATA_PM10_LEN ) := i2v(I + 1, DATA_PM10_LEN);
        result(DATA_HUM_OFFSET   downto DATA_HUM_OFFSET   + 1 - DATA_HUM_LEN  ) := i2v(I + 1, DATA_HUM_LEN);
        result(DATA_TEMP_OFFSET  downto DATA_TEMP_OFFSET  + 1 - DATA_TEMP_LEN ) := i2v(I + 1, DATA_TEMP_LEN);
        result(CHECKSUM_OFFSET   downto CHECKSUM_OFFSET   + 1 - CHECKSUM_LEN  ) := i2v(4 * (I + 1) mod 61, CHECKSUM_LEN);
        return result;
    end function;
end package body;
