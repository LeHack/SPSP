library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;
    use utils.fake_mem.all;

entity sdram is
    PORT (
        clocks     : IN t_clocks;
        rw,         -- '0' Read, '1' Read/Write
        enable      : IN  STD_LOGIC := '0';
        ready       : OUT STD_LOGIC := '0';
        addr        : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        data_in     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        data_out    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        
        -- SDRAM interface
        SDRAM_addr            : OUT STD_LOGIC_VECTOR(12 DOWNTO 0) := (others => '0');
        SDRAM_data            : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
        SDRAM_data_mask,
        SDRAM_bank_addr       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');

        SDRAM_clk,
        SDRAM_clock_enable,
        SDRAM_we_n,
        SDRAM_cas_n,
        SDRAM_ras_n,
        SDRAM_cs_n            : OUT STD_LOGIC := '0'
    );
END entity;

architecture arch of sdram is
    signal fake_memory : sdram_mem := (others => (others => '1'));
begin
    SDRAM_MOCK: process(clocks.CLK_1M19)
        constant last_write  : integer := fake_sdram_size - 2;
        constant last_row    : integer := fake_sdram_size * 4 - 1;    

        variable rw_mode    : STD_LOGIC;
        variable addr_i     : integer range 0 to last_row := 0;
        variable init_delay : unsigned(1 downto 0) := (others => '0');
        variable counter    : unsigned(1 downto 0) := (others => '0');
        variable addr_based_val : STD_LOGIC_VECTOR(15 downto 0);
        variable fake_rows  : std_logic_vector(39 downto 0);
        variable fired, init : boolean := false;
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_1M19) then
            if not init then
                init_delay := init_delay + 1;
                if init_delay = 0 then
                    init := true;
                end if;
            elsif not fired and ready = '1' and enable = '1' then
                ready <= '0';
                rw_mode := rw;
                addr_i  := to_integer(unsigned(addr));
                assert addr_i <= last_row report "Address out of range!" severity failure;
            elsif ready = '0' then
                counter := counter + 1;
                if counter = 0 then
                    if rw_mode = '0' then
                        data_out <= fake_memory(addr_i);
                    else
                        fake_memory(addr_i) <= data_in;
                    end if;
                    ready <= '1';
                end if;
            end if;
            if enable = '0' then
                fired := false;
            end if;
        end if;
    end process;

    -- blank signals to get rid of warnings
    SDRAM_data <= (others => '0');

    SDRAM_clk <= '0';
    SDRAM_clock_enable <= '0';
    SDRAM_we_n <= '0';
    SDRAM_cas_n <= '0';
    SDRAM_ras_n <= '0';
    SDRAM_cs_n <= '0';
    SDRAM_addr <= (others => '0');
    SDRAM_bank_addr <= (others => '0');
    SDRAM_data_mask <= (others => '0');
end arch;
