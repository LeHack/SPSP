architecture arch of sdram is
    signal state : common_state_type := initialize;
    -- SDRAM controller
    signal wr_addr, rd_addr : STD_LOGIC_VECTOR(23 DOWNTO 0);
    signal wr_data, rd_data : STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal wr_enable, rd_enable, sdr_busy, sdr_rst_n : STD_LOGIC;
begin
    -- try driving the SDRAM with the 50MHz system clock
    -- possibly there may be a clk skew issue
    SDRAM_clk <= clocks.CLK_50M;

    sdram_ent : component sdram_controller PORT MAP (
        wr_addr => wr_addr, rd_addr => rd_addr,
        wr_data => wr_data, rd_data => rd_data,
        wr_enable => wr_enable, rd_enable => rd_enable,
        busy => sdr_busy, rst_n => sdr_rst_n,

        clk => clocks.CLK_50M, clock_enable => SDRAM_clock_enable,

        -- SDRAM data/signal lines
        addr => SDRAM_addr, bank_addr => SDRAM_bank_addr, data => SDRAM_data,
        data_mask_low => SDRAM_data_mask(0), data_mask_high => SDRAM_data_mask(1),
        we_n => SDRAM_we_n, cas_n => SDRAM_cas_n, ras_n => SDRAM_ras_n, cs_n => SDRAM_cs_n
    );

    SDRAM_DRV: process(clocks.CLK_1M19)
        type sdram_state_type is (idle, processing, done);

        variable busy_cnt    : integer range 0 to 7 := 0;
        variable sdram_state : sdram_state_type := idle;

        procedure sdram_transaction(
                rw   : IN STD_LOGIC;
                addr : IN STD_LOGIC_VECTOR(23 downto 0);
                data : INOUT STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            -- if the controller is busy, stop immediately
            if sdr_busy = '1' then
                if sdram_state = processing then
                    rd_enable <= '0';
                    wr_enable <= '0';
                end if;
                return;
            end if;

            -- start the operation
            if sdram_state = idle then
                if rw = '0' then
                    rd_addr <= addr;
                    rd_enable <= '1';
                else
                    wr_addr <= addr;
                    wr_data <= data;
                    wr_enable <= '1';
                end if;

                sdram_state := processing;
            -- wait for results
            elsif sdram_state = processing then
                if rw = '0' then
                    data := rd_data;
                end if;
                sdram_state := done;
            end if;
        end procedure;

        -- make sure we start and finish each transaction with the same mode
        -- and since the signal may change during time, we copy it to a local variable
        variable rw_mode    : STD_LOGIC;
        variable init_delay : unsigned(3 downto 0) := (others => '0');
        variable tmp_data   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when initialize =>
                    sdr_rst_n <= '0';
                    init_delay := init_delay + 1;
                    if init_delay = 0 then
                        -- disable reset after an initial sleep
                        sdr_rst_n <= '1';
                        state <= idle;
                    end if;
                when idle =>
                    ready <= '1';
                    if enable = '1' then
                        ready <= '0';
                        state <= busy;
                        rw_mode := rw;
                        if rw_mode = '1' then
                            tmp_data := data_in;
                        end if;
                    end if;
                when busy =>
                    case sdram_state is
                        when idle | processing =>
                            sdram_transaction(rw_mode, addr, tmp_data);
                        when done =>
                            sdram_state := idle;
                            if rw_mode = '0' then
                                data_out <= tmp_data;
                            end if;
                            state <= idle;
                    end case;
                when others => state <= idle;
            end case;
        end if;
    end process;
end arch;
