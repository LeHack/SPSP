architecture arch of eeprom is
    constant slave_addr : STD_LOGIC_VECTOR(6 DOWNTO 0) := x"A" & "000";
    signal state : common_state_type := initialize;
    signal i2c_ena, i2c_rw, i2c_busy, busy_prev : STD_LOGIC;
    signal i2c_addr : STD_LOGIC_VECTOR(6 DOWNTO 0);
    signal i2c_data_wr, i2c_data_rd : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
begin
    i2c : entity ext.i2c_master PORT MAP (
        clk => clocks.CLK_50M, reset_n => '1', ena => i2c_ena, addr => i2c_addr,
        rw => i2c_rw, data_wr => i2c_data_wr, busy => i2c_busy, data_rd => i2c_data_rd,
        sda => SDA, scl => SCL
    );

    EEPROM_DRV: process(clocks.CLK_1M19)
        type i2c_state_type is (idle, processing, done, cooldown);

        variable busy_cnt   : integer range 0 to 2 := 0;
        variable i2c_state  : i2c_state_type := idle;

        procedure i2c_transaction(
                rw   : IN STD_LOGIC;
                addr : IN STD_LOGIC_VECTOR(7 downto 0);
                data : IN STD_LOGIC_VECTOR(7 downto 0) := (others => '0')) is
        begin
            busy_prev <= i2c_busy;
            if (busy_prev = '0' AND i2c_busy = '1') then
                busy_cnt := busy_cnt + 1;
            end if;

            case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= slave_addr;
                    i2c_rw <= '0';
                    i2c_data_wr <= addr;
                when 1 =>
                    -- i2c_rw logic is the inverse of rw
                    case rw is
                        when '1' =>
                            i2c_rw <= '0';
                            i2c_data_wr <= data;
                        when '0' =>
                            i2c_rw <= '1';
                        when others => NULL;
                    end case;
                when 2 =>
                    i2c_ena <= '0';
                    if (i2c_busy = '0') then
                        busy_cnt := 0;
                        i2c_state := done;
                    end if;
            end case;
        end procedure;

        -- make sure we start and finish each transaction with the same mode
        -- and since the signal may change during time, we copy it to a local variable
        variable rw_mode : STD_LOGIC;
        -- additional delay (~4ms) after each transaction for the slave to notice the stop mark
        variable stop_delay : unsigned(12 downto 0) := (others => '0');
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when idle =>
                    ready <= '1';
                    if enable = '1' then
                        ready <= '0';
                        state <= busy;
                        rw_mode := rw;
                    end if;
                when busy =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(rw_mode, addr, data_in);
                        when done =>
                            if rw_mode = '0' then
                                data_out <= i2c_data_rd;
                            end if;
                            i2c_state := cooldown;
                        when cooldown =>
                            stop_delay := stop_delay + 1;
                            if stop_delay = 4600 then
                                state <= idle;
                                i2c_state := idle;
                                stop_delay := (others => '0');
                            end if;
                    end case;
                 when others => state <= idle;
            end case;
        end if;
    end process;
end arch;
