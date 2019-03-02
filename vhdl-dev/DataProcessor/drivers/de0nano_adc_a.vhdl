architecture main of de0nano_adc is
    signal state : common_state_type := initialize;
    signal ADC_CS, spi_enable, spi_reset : STD_LOGIC := '0';
begin

    spi_driver : entity ext.spi_master GENERIC MAP (slaves => 1, d_width => 16) PORT MAP (
        clock => clocks.CLK_50M, enable => spi_enable, cont => '0',
        reset_n => spi_reset, cpol => '0', cpha => '0', addr => 0,
        tx_data => input, rx_data => output, clk_div => 16,
        sclk => ADC_SCLK, busy => ADC_CS,
        miso => ADC_SDAT, mosi => ADC_SADDR
    );

    -- Toggle the CS signal
    ADC_CS_N <= not ADC_CS;

    DE0Nano_ADC_DRV: process(clocks.CLK_1M19)
        variable spi_comm_delay : unsigned(5 downto 0) := (others => '0');
        variable init_delay     : unsigned(2 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_1M19) then
            CASE state IS
                WHEN initialize =>
                    init_delay := init_delay + 1;
                    if init_delay = 0 then
                        spi_reset <= '1';
                        state <= idle;
                    end if;
                WHEN idle =>
                    ready <= '1';
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                        spi_comm_delay := (others => '0');
                    end if;
                WHEN busy =>
                    if spi_comm_delay = 0 then
                        spi_enable <= '1';
                    end if;
                    spi_comm_delay := spi_comm_delay + 1;
                    -- after 6 ticks, remove the spi_enable flag, to make sure spi_master stops after the read
                    if spi_comm_delay = 6 then
                        spi_enable <= '0';
                    -- we need ~14 CLK_1M19 ticks to generate 16 sclk ticks
                    -- we should also add a little pause
                    elsif spi_comm_delay = 14 then
                        state <= idle;
                    end if;
                WHEN others => state <= idle;
            end CASE;
        end if;
    end process;
end main;
