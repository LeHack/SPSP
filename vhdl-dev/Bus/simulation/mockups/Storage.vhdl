-- Storage mockup
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;

entity Storage is
    PORT (
        clocks      : IN t_clocks;

        -- Flags
        reset_settings,
        rw,         -- '0' Read, '1' Read/Write
        enable      : IN  STD_LOGIC := '0';
        overflow,
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

architecture arch of Storage is
    signal fake_mem : STD_LOGIC_VECTOR(47 DOWNTO 0);
    signal state : common_state_type := initialize;
begin
    process(clocks.CLK_50M)
        variable drv_state_ready : boolean := false;
        variable sleep, data_row : unsigned(3 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_50M) then
            case state is
                when initialize =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        state <= idle;
                        ready <= '1';
                    end if;
                when idle =>
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                    end if;
                when busy =>
                    if enable = '0' then
                        -- switch state to busy
                        state <= busy;
                        sleep := sleep + 1;
                        if sleep = 0 then
                            case data_type is
                                when data_record =>
                                    if data_row < 3 then
                                        if rw = '1' then
                                            case data_row is
                                                when "0000" => fake_mem(15 downto  0) <= data_in(15 downto 0);
                                                when "0001" => fake_mem(31 downto 16) <= data_in(31 downto 16);
                                                when "0010" =>
                                                    fake_mem(47 downto 34) <= (others => '0');
                                                    fake_mem(33 downto 32) <= data_in(33 downto 32);
                                                when others => NULL;
                                            end case;
                                        end if;
                                        data_row := data_row + 1;
                                    else
                                        data_row := (others => '0');
                                        state <= idle;
                                        ready <= '1';
                                    end if;
                                when others =>
                                    data_out <= (4 => '1', others => '0');
                                    state <= idle;
                                    ready <= '1';
                            end case;
                        end if;
                    end if;
                when others => NULL;
            end case;
        end if;
    end process;

    -- blank signals to get rid of warnings
    storage_inout.SDRAM_data <= (others => '0');

    storage_out.SDRAM_clk <= '0';
    storage_out.SDRAM_clock_enable <= '0';
    storage_out.SDRAM_we_n <= '0';
    storage_out.SDRAM_cas_n <= '0';
    storage_out.SDRAM_ras_n <= '0';
    storage_out.SDRAM_cs_n <= '0';
    storage_out.SDRAM_addr <= (others => '0');
    storage_out.SDRAM_bank_addr <= (others => '0');
    storage_out.SDRAM_data_mask <= (others => '0');

    storage_inout.EEPROM_SCL <= '0';
    storage_inout.EEPROM_SDA <= '0';
end arch;
