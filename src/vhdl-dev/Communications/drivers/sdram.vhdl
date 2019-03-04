library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ext;
    use ext.sdram_controller_wrapper.all;
library utils;
    use utils.utils.all;

-- DE0Nano RAM:
-- ISSI
-- IS42S16160G-7TLI
-- BKS4930D0X2 1525

entity sdram is
    PORT (
        clocks      : IN t_clocks;
        rw,         -- '0' Read, '1' Read/Write
        enable      : IN  STD_LOGIC := '0';
        ready       : OUT STD_LOGIC := '0';

        addr        : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        data_in     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        data_out    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        
        -- SDRAM interface
        SDRAM_addr            : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
        SDRAM_data            : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        SDRAM_data_mask,
        SDRAM_bank_addr       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        SDRAM_clk,
        SDRAM_clock_enable,
        SDRAM_we_n,
        SDRAM_cas_n,
        SDRAM_ras_n,
        SDRAM_cs_n            : OUT STD_LOGIC
    );
END entity;
