architecture SPI of shift_reg is
    signal state        : common_state_type := idle;
    signal data         : STD_LOGIC_VECTOR(7 downto 0);
    signal spi_enable,
           spi_busy     : STD_LOGIC := '0';
begin
    spi_driver : entity ext.spi_master GENERIC MAP (slaves => 1, d_width => 8) PORT MAP (
        clock => clocks.CLK_50M,
        enable => spi_enable,
        busy => spi_busy,
        cont => '0', reset_n => '1', cpol => '0', cpha => '0', addr => 0,
        tx_data => data, miso => 'Z', mosi => REG_DATA, sclk => REG_CLK, clk_div => 10
    );

    DISPLAY_REG_DRV: process(clocks.CLK_1M19)
        variable fired : boolean := false;
    begin
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when idle =>
                    ready <= '1';
                    if enable = '1' and not fired then
                        ready   <= '0';
                        fired := true;
                        data    <= input;
                        state   <= busy;
                        spi_enable  <= '1';
                        REG_LATCH   <= LATCH_ENABLED;
                    end if;
                when busy =>
                    if spi_busy = '1' then
                        spi_enable <= '0';
                    elsif spi_busy = '0' then
                        state <= idle;
                        -- remember to flip the latch when we're done
                        REG_LATCH <= not LATCH_ENABLED;
                    end if;
                when others => state <= idle;
            end case;
            if enable = '0' then
                fired := false;
            end if;
        end if;
    end process;
end SPI;
