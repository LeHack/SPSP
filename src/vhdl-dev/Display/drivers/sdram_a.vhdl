architecture arch of sdram is
    -- As defined for IS42S16160G
    CONSTANT SDR_ROW_WIDTH      : INTEGER := 13;
    CONSTANT SDR_COL_WIDTH      : INTEGER := 9;
    CONSTANT SDR_BANK_WIDTH     : INTEGER := 2;
    CONSTANT SDR_HADDR_WIDTH    : INTEGER := SDR_BANK_WIDTH + SDR_ROW_WIDTH + SDR_COL_WIDTH;
    -- SDR_ROW_WIDTH > SDR_COL_WIDTH ? SDR_ROW_WIDTH : SDR_COL_WIDTH;
    CONSTANT SDR_SDRADDR_WIDTH  : INTEGER := SDR_ROW_WIDTH;
    CONSTANT SDR_CLK_FREQUENCY  : INTEGER := 100;
    CONSTANT SDR_REFRESH_TIME   : INTEGER := 32;
    CONSTANT SDR_REFRESH_COUNT  : INTEGER := 8192;

    signal state : common_state_type := initialize;
    -- SDRAM controller
    signal wr_addr, rd_addr : STD_LOGIC_VECTOR(SDR_HADDR_WIDTH - 1 DOWNTO 0);
    signal wr_data, rd_data : STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal wr_enable, rd_enable, sdr_busy, sdr_rst_n, CLK_100M, CLK_100M_shifted : STD_LOGIC := '0';
begin
    -- create a speed/phase corrected SDRAM clock
    clock_doubler : entity ext.sdram_clk_pll PORT MAP (
        inclk0 => clocks.CLK_50M,
        c0     => CLK_100M, -- 100MHz
        c1     => CLK_100M_shifted -- -4ns phase shift
	);

    SDRAM_clk <= CLK_100M_shifted;
    sdram_ctrl: component sdram_controller GENERIC MAP (
        ROW_WIDTH       => SDR_ROW_WIDTH,
        COL_WIDTH       => SDR_COL_WIDTH,
        BANK_WIDTH      => SDR_BANK_WIDTH,
        HADDR_WIDTH     => SDR_HADDR_WIDTH,
        SDRADDR_WIDTH   => SDR_SDRADDR_WIDTH,
        CLK_FREQUENCY   => SDR_CLK_FREQUENCY,
        REFRESH_TIME    => SDR_REFRESH_TIME,
        REFRESH_COUNT   => SDR_REFRESH_COUNT
    ) PORT MAP (
        wr_addr => wr_addr, rd_addr => rd_addr,
        wr_data => wr_data, rd_data => rd_data,
        wr_enable => wr_enable, rd_enable => rd_enable,
        busy => sdr_busy, rst_n => sdr_rst_n,

        clk => CLK_100M_shifted, clock_enable => SDRAM_clock_enable,

        -- SDRAM data/signal lines
        addr => SDRAM_addr, bank_addr => SDRAM_bank_addr, data => SDRAM_data,
        data_mask_low => SDRAM_data_mask(0), data_mask_high => SDRAM_data_mask(1),
        we_n => SDRAM_we_n, cas_n => SDRAM_cas_n, ras_n => SDRAM_ras_n, cs_n => SDRAM_cs_n
    );

    SDRAM_DRV: process(CLK_100M)
        type sdram_state_type is (idle, processing, done);
        variable sdram_state : sdram_state_type := idle;
        variable sdram_err_cnt : unsigned(19 downto 0) := (others => '0');
        -- 100us delay for RAM initialization
        variable init_delay : unsigned(13 downto 0) := (others => '0');

        procedure sdram_transaction(
            constant rw   : IN STD_LOGIC;
            constant addr : IN STD_LOGIC_VECTOR(23 downto 0);
            variable data : INOUT STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            -- check after write and retry once
            case sdram_state is
                when idle =>
                    if sdr_busy = '0' then
                        sdram_state := processing;
                        if rw = '0' then
                            rd_addr <= addr;
                            rd_enable <= '1';
                        else
                            wr_addr <= addr;
                            wr_data <= data;
                            wr_enable <= '1';
                        end if;
                    end if;
                when processing =>
                    if rd_enable = '1' or wr_enable = '1' then
                        if sdr_busy = '1' then
                            rd_enable <= '0';
                            wr_enable <= '0';
                            init_delay := (others => '0');
                        end if;
                    elsif sdr_busy = '0' then
                        if rw = '0' then
                            sdram_state := done;
                        else
                            -- introduce a small delay after each write operation
                            init_delay := init_delay + 1;
                            if init_delay > 1024 then
                                sdram_state := done;
                            end if;
                        end if;
                        -- the state below will be handled on the same clock cycle
                    end if;
                when done =>
                    if rw = '0' then
                        data := rd_data;
                    end if;
                    sdram_state := idle;
            end case;
        end procedure;

        -- make sure we start and finish each transaction with the same mode
        -- and since the signal may change during time, we copy it to a local variable
        variable data : STD_LOGIC_VECTOR(15 DOWNTO 0);
        variable fired : boolean := false;
    begin
        -- check if state allows us to do anything
        if rising_edge(CLK_100M) then
            case state is
                when initialize =>
                    init_delay := init_delay + 1;
                    if init_delay = 0 then
                        ready <= '1';
                        state <= idle;
                    elsif init_delay = 5 then
                        -- disable reset after the five two ticks
                        sdr_rst_n <= '1';
                    end if;
                when idle =>
                    -- dont signal ready until the fired lock is dropped (enable is low)
                    if ready = '0' and not fired then
                        ready <= '1';
                    elsif enable = '1' and not fired then
                        fired := true;
                        ready <= '0';
                        state <= busy;
                        if rw = '1' then
                            data := data_in;
                            sdram_transaction(rw, addr, data);
                        end if;
                    end if;
                when busy =>
                    sdram_transaction(rw, addr, data);
                    if sdram_state = done then
                        sdram_transaction(rw, addr, data);
                        data_out <= data;
                        state <= idle;
                    end if;
                when others => state <= idle; ready <= '1';
            end case;
            if enable = '0' and fired then
                fired := false;
            end if;
        end if;
    end process;
end arch;
