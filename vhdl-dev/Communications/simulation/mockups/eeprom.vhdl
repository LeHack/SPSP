library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
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

architecture arch of eeprom is
    constant fake_mem_high : integer := 14;
    signal fake_memory : STD_LOGIC_VECTOR(fake_mem_high * 8 - 1 downto 0) := (others => '0');
    -- x"01009C1997710A3C322A" -- the memory should auto-init this part
begin
    EEPROM_MOCK: process(clocks.CLK_1M19)
        variable rw_mode        : STD_LOGIC;
        variable addr_i, a, b   : integer range 0 to 255 := 0;
        variable init_delay     : unsigned(5 downto 0) := (others => '0');
        variable counter        : unsigned(1 downto 0) := (others => '0');
        variable fired, init    : boolean := false;
    begin
        if rising_edge(clocks.CLK_1M19) then
            if not init then
                init_delay := init_delay + 1;
                if init_delay = 0 then
                    init := true;
                end if;
            elsif not fired and ready = '1' and enable = '1' then
                ready <= '0';
                fired := true;
                rw_mode := rw;
                addr_i  := to_integer(unsigned(addr));
                assert addr_i <= fake_mem_high - 1 report "Address out of range!" severity failure;
            elsif ready = '0' then
                counter := counter + 1;
                if counter = 0 then
                    ready <= '1';
                    a := addr_i * 8 + 7;
                    b := addr_i * 8;
                    if rw_mode = '0' then
                        data_out <= fake_memory(a downto b);
                    else
                        fake_memory(a downto b) <= data_in;
                    end if;
                end if;
            end if;
            if enable = '0' then
                fired := false;
            end if;
        end if;
    end process;

    -- blank signals to get rid of warnings
    SCL <= '0';
    SDA <= '0';
end arch;
