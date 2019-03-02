library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package sdram_controller_wrapper is
    -- Verilog component mapping
    COMPONENT sdram_controller 
        GENERIC (
            ROW_WIDTH       : INTEGER;
            COL_WIDTH       : INTEGER;
            BANK_WIDTH      : INTEGER;
            HADDR_WIDTH     : INTEGER;
            SDRADDR_WIDTH   : INTEGER;
            CLK_FREQUENCY   : INTEGER;
            REFRESH_TIME    : INTEGER;
            REFRESH_COUNT   : INTEGER
        );
        PORT (
            wr_addr         : IN STD_LOGIC_VECTOR(HADDR_WIDTH-1 DOWNTO 0);
            wr_data         : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            wr_enable       : IN STD_LOGIC;
            rd_addr         : IN STD_LOGIC_VECTOR(HADDR_WIDTH-1 DOWNTO 0);
            rd_data         : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            rd_ready        : OUT STD_LOGIC;
            rd_enable       : IN STD_LOGIC;
            busy            : OUT STD_LOGIC;
            rst_n           : IN STD_LOGIC;
            clk             : IN STD_LOGIC;
            addr            : OUT STD_LOGIC_VECTOR(SDRADDR_WIDTH-1 DOWNTO 0);
            bank_addr       : OUT STD_LOGIC_VECTOR(BANK_WIDTH-1 DOWNTO 0);
            data            : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            clock_enable    : OUT STD_LOGIC;
            cs_n            : OUT STD_LOGIC;
            ras_n           : OUT STD_LOGIC;
            cas_n           : OUT STD_LOGIC;
            we_n            : OUT STD_LOGIC;
            data_mask_low   : OUT STD_LOGIC;
            data_mask_high  : OUT STD_LOGIC
        );
    END COMPONENT;
end package;
