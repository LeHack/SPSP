architecture arch of Storage is
    signal state : common_state_type := initialize;
    -- VirtClk and flags
    signal sdram_ready, sdram_enable, sdram_rw,
           eeprom_ready, eeprom_enable, eeprom_rw : std_logic := '0';

    -- Data
    signal sdram_address   : STD_LOGIC_VECTOR(23 downto 0);
    signal sdram_data_in,
           sdram_data_out  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    signal eeprom_addr     : STD_LOGIC_VECTOR(7 downto 0);
    signal eeprom_data_in,
           eeprom_data_out : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    type io_stage_type is (mem_idle, mem_busy, mem_ready);
    signal io_stage : io_stage_type := mem_idle;
begin
    sdram : entity drivers.sdram PORT MAP (
        clocks => clocks,

        -- Control
        ready   => sdram_ready,
        enable  => sdram_enable,
        rw      => sdram_rw,

        -- I/O
        addr     => sdram_address,
        data_in  => sdram_data_in,
        data_out => sdram_data_out,

        -- SDRAM data/signal lines
        SDRAM_data => storage_inout.SDRAM_data,
        SDRAM_addr => storage_out.SDRAM_addr, SDRAM_bank_addr => storage_out.SDRAM_bank_addr,
        SDRAM_data_mask => storage_out.SDRAM_data_mask, SDRAM_clk => storage_out.SDRAM_clk,
        SDRAM_clock_enable => storage_out.SDRAM_clock_enable, SDRAM_we_n => storage_out.SDRAM_we_n,
        SDRAM_cas_n => storage_out.SDRAM_cas_n, SDRAM_ras_n => storage_out.SDRAM_ras_n,
        SDRAM_cs_n => storage_out.SDRAM_cs_n
    );

    eeprom : entity drivers.eeprom PORT MAP (
        clocks => clocks,

        -- Control
        ready  => eeprom_ready,
        enable => eeprom_enable,
        rw     => eeprom_rw,

        -- I/O
        addr     => eeprom_addr,
        data_in  => eeprom_data_in,
        data_out => eeprom_data_out,

        -- EEPROM signal lines
        sda => storage_inout.EEPROM_SDA, scl => storage_inout.EEPROM_SCL
    );

    STORAGE_MANAGER: process(clocks.CLK_1M19)
        variable sdram_overflow, sdram_first_write : boolean := false;
        variable sdram_row_id          : unsigned ( 1 downto 0) := (others => '0');
        variable sdram_last_write_addr : unsigned (19 downto 0) := (others => '0');
        variable eeprom_row_id         : unsigned ( 3 downto 0) := (others => '0');
        procedure run_io(
            constant op_type : IN storage_data_type;
            constant rw_mode : IN STD_LOGIC;
            constant op_timestamp : IN STD_LOGIC_VECTOR) is
            variable addr_map_l, addr_map_r : integer range 0 to 63 := 0;
            variable short_read, invalid_data : boolean := false;
        begin
            case io_stage is
                -- start from choosing the memory to work with and setting the address
                when mem_idle =>
                    case op_type is
                        when data_record =>
                            -- SDRAM
                            sdram_address <= "00" & op_timestamp & "00";
                            sdram_row_id := (0 => '1', others => '0');
                            sdram_rw <= rw_mode;
                            overflow <= '0';
                            -- set the data to write
                            if rw_mode = '1' then
                                sdram_data_in <= data_in(15 downto 0);
                                if sdram_last_write_addr > unsigned(op_timestamp) then
                                    sdram_overflow := true;
                                end if;
                                -- now update the last write address
                                sdram_last_write_addr := unsigned(op_timestamp);
                                sdram_first_write := true;
                            elsif sdram_last_write_addr < unsigned(op_timestamp) then -- + rw_mode = '0'
                                overflow <= '1';
                                short_read := not sdram_overflow;
                            elsif unsigned(op_timestamp) = 0 and not sdram_first_write then
                                overflow <= '1';
                                short_read := true;
                            end if;

                            if short_read then
                                data_out <= (others => 'U');
                                io_stage <= mem_ready;
                            else
                                sdram_enable <= '1';
                                io_stage <= mem_busy;
                            end if;
                        when others =>
                            -- EEPROM
                            case op_type is
                                when setting_pm10_norm          => eeprom_addr <= x"01";
                                when setting_read_freq          => eeprom_addr <= x"02";
                                when setting_avg_sample_size    => eeprom_addr <= x"03";
                                when setting_device_name        => eeprom_addr <= x"04";
                                    eeprom_row_id := (2 => '1', others => '0'); -- the whole addr range is 04-0B
                                when setting_display_timeout    => eeprom_addr <= x"0C";
                                when setting_pressure_reference => eeprom_addr <= x"0D";
                                when others => NULL;
                            end case;
                            -- set the data to write
                            if rw_mode = '1' then
                                eeprom_data_in <= (others => '0');
                                case op_type is
                                    when setting_pm10_norm          => eeprom_data_in(7 downto 0) <= data_in(7 downto 0);
                                    when setting_read_freq          => eeprom_data_in(5 downto 0) <= data_in(5 downto 0);
                                    when setting_avg_sample_size    => eeprom_data_in(5 downto 0) <= data_in(5 downto 0);
                                    when setting_device_name        => eeprom_data_in(7 downto 0) <= data_in(3 downto 0) & "0000";
                                    when setting_display_timeout    => eeprom_data_in(5 downto 0) <= data_in(5 downto 0);
                                    when setting_pressure_reference => eeprom_data_in(7 downto 0) <= data_in(7 downto 0);
                                    when others => NULL;
                                end case;
                                -- make sure we don't store invalid values
                                invalid_data := unsigned(data_in(7 downto 0)) = 0 and (op_type = setting_pm10_norm or op_type = setting_read_freq);
                                if invalid_data then
                                    error <= '1';
                                    io_stage <= mem_ready;
                                elsif op_type = setting_device_name then
                                    -- for getting/setting the device name, we need to access 8 rows (60b)
                                    io_stage <= mem_busy;
                                else
                                    -- for other settings there is only one read/write, so we need the intermediate stage
                                    io_stage <= mem_ready;
                                end if;
                            else
                                -- for reading we have to transport the read data to the output
                                io_stage <= mem_busy;
                            end if;
                            -- don't start a memory transaction if we don't have anything to do
                            if not invalid_data then
                                eeprom_rw <= rw_mode;
                                eeprom_enable <= '1';
                            end if;
                    end case;
                when mem_busy =>
                    case op_type is
                        when data_record =>
                            -- SDRAM
                            if rw_mode = '0' then
                                -- move the read data to the correct part of the output
                                case sdram_row_id is
                                    when "01" => data_out(15 downto  0) <= sdram_data_out(15 downto 0);
                                    when "10" => data_out(31 downto 16) <= sdram_data_out(15 downto 0);
                                    when "11" => data_out(39 downto 32) <= sdram_data_out( 7 downto 0);
                                    when others => NULL;
                                end case;
                            end if;
                            if sdram_row_id > 0 then
                                sdram_address(1 downto 0) <= std_logic_vector(sdram_row_id);
                                sdram_enable <= '1';
                                -- all other intermediate stages
                                if rw_mode = '1' then
                                    sdram_data_in <= (others => '0');
                                    case sdram_row_id is
                                        when "01" => sdram_data_in <= data_in(31 downto 16);
                                        when "10" => sdram_data_in(7 downto 0) <= data_in(39 downto 32);
                                        when others => NULL;
                                    end case;
                                end if;
                                sdram_row_id := sdram_row_id + 1;
                            else
                                -- run after last read from SDRAM
                                io_stage <= mem_ready;
                            end if;
                        when setting_device_name =>
                            -- EEPROM - multi row read/write
                            if rw_mode = '0' then
                                -- read
                                case eeprom_row_id is
                                    -- eeprom addr: 04-11
                                    when "0100" => data_out( 3 downto  0) <= eeprom_data_out(7 downto 4);
                                    when "0101" => data_out(11 downto  4) <= eeprom_data_out(7 downto 0);
                                    when "0110" => data_out(19 downto 12) <= eeprom_data_out(7 downto 0);
                                    when "0111" => data_out(27 downto 20) <= eeprom_data_out(7 downto 0);
                                    when "1000" => data_out(35 downto 28) <= eeprom_data_out(7 downto 0);
                                    when "1001" => data_out(43 downto 36) <= eeprom_data_out(7 downto 0);
                                    when "1010" => data_out(51 downto 44) <= eeprom_data_out(7 downto 0);
                                    when "1011" => data_out(59 downto 52) <= eeprom_data_out(7 downto 0);
                                    when others => NULL;
                                end case;
                            else
                                -- write
                                case eeprom_row_id is
                                    -- minus the first phase (data_in(3 downto 0)), which was done in mem_idle
                                    when "0100" => eeprom_data_in(7 downto 0) <= data_in(11 downto  4);
                                    when "0101" => eeprom_data_in(7 downto 0) <= data_in(19 downto 12);
                                    when "0110" => eeprom_data_in(7 downto 0) <= data_in(27 downto 20);
                                    when "0111" => eeprom_data_in(7 downto 0) <= data_in(35 downto 28);
                                    when "1000" => eeprom_data_in(7 downto 0) <= data_in(43 downto 36);
                                    when "1001" => eeprom_data_in(7 downto 0) <= data_in(51 downto 44);
                                    when "1010" => eeprom_data_in(7 downto 0) <= data_in(59 downto 52);
                                    when others => NULL;
                                end case;
                            end if;
                            -- bump the address or finish
                            if eeprom_row_id < 11 then
                                eeprom_row_id := eeprom_row_id + 1;
                                eeprom_addr <= "0000" & std_logic_vector(eeprom_row_id);
                                eeprom_enable <= '1';
                            else
                                io_stage <= mem_ready;
                            end if;
                        when others =>
                            -- EEPROM - single row read
                            io_stage <= mem_ready;
                            data_out <= (others => '0');
                            case op_type is
                                when setting_pm10_norm          => data_out(7 downto 0) <= eeprom_data_out;
                                when setting_read_freq          => data_out(5 downto 0) <= eeprom_data_out(5 downto 0);
                                when setting_avg_sample_size    => data_out(5 downto 0) <= eeprom_data_out(5 downto 0);
                                when setting_display_timeout    => data_out(5 downto 0) <= eeprom_data_out(5 downto 0);
                                when setting_pressure_reference => data_out(7 downto 0) <= eeprom_data_out(7 downto 0);
                                when others => NULL;
                            end case;
                    end case;
                when mem_ready =>
                    io_stage <= mem_idle;
            end case;
        end procedure;

        variable op_data_type : storage_data_type;
        variable rw_mode      : STD_LOGIC;
        variable op_timestamp : STD_LOGIC_VECTOR(19 downto 0);

        type init_state_type is (idle, checking, preinit, initializing, done);
        variable eeprom_init      : init_state_type := idle;
        variable eeprom_init_addr : unsigned (4 downto 0);
        procedure initialize_eeprom is
            -- EEPROM Initialization base
            type factory_settings_type is array (0 TO 13) of UNSIGNED(7 DOWNTO 0);
            constant defaults : factory_settings_type := (
                x"2A", -- 42  - just a control number
                x"32", -- 50ug/m3 of PM10 is 100%
                x"3C", -- 60s - sampling wait period
                x"0A", -- 10  - number of samples to average from
                -- BT name as 10x6bit split into 6B
                x"00", x"00", x"42", x"10", x"A0", x"5A", x"A7", x"75", -- SPSP-001 (reversed)
                x"0A", -- 10  - default time after which display is disabled
                x"DD"  -- -35hPa - pressure reference point, to allow calculating the correct local atmospheric pressure
            );
       begin
            -- compare the expected and current value on address 0x00
            -- if it's something else, init the memory with default values
            case eeprom_init is
                when idle =>
                    eeprom_addr   <= x"00";
                    eeprom_rw     <= '0';
                    eeprom_enable <= '1';
                    eeprom_init   := checking;
                when checking =>
                    if unsigned(eeprom_data_out) = defaults(0) then
                        -- everything is ok, nothing to do
                        eeprom_init := done;
                    else
                        -- start the init process
                        eeprom_init := preinit;
                    end if;
                when preinit =>
                    eeprom_init_addr := to_unsigned(factory_settings_type'RIGHT + 1, 5);
                    eeprom_init := initializing;
                when initializing =>
                    if eeprom_init_addr > 0 then
                        eeprom_init_addr := eeprom_init_addr - 1;
                        eeprom_addr    <= "000" & std_logic_vector(eeprom_init_addr);
                        eeprom_data_in <= std_logic_vector(defaults(to_integer(eeprom_init_addr)));
                        eeprom_rw      <= '1';
                        eeprom_enable  <= '1';
                    else
                        eeprom_init := done;
                    end if;
                when others => NULL;
            end case;
        end procedure;

        variable drv_state_ready, trigger_fired : boolean := false;
    begin
        if rising_edge(clocks.CLK_1M19) then
            drv_state_ready := (eeprom_ready = '1' and sdram_ready = '1');
            case state is
                when initialize =>
                    -- wait for both drivers to indicate ready state, then start initialization
                    if eeprom_ready = '1' and eeprom_enable = '0' then
                        initialize_eeprom;
                    elsif eeprom_ready = '0' then
                        eeprom_enable <= '0';
                    end if;

                    -- finally the initialization is done, switch to module ready
                    if eeprom_init = done then
                        state <= idle;
                    end if;
                when idle =>
                    ready <= '1';
                    if enable = '1' and not trigger_fired then
                        ready <= '0';
                        trigger_fired := true;
                        if reset_settings = '1' then
                            -- force reinitialization of eeprom by skipping the magic value check
                            eeprom_init := preinit;
                            state <= initialize;
                        else
                            op_data_type := data_type;
                            rw_mode      := rw;
                            op_timestamp := timestamp;
                            state <= busy;
                            error <= '0';
                        end if;
                    end if;
                when busy =>
                    if eeprom_enable = '1' or sdram_enable = '1' then
                        if not drv_state_ready then
                            -- reset run signals
                            eeprom_enable <= '0';
                            sdram_enable  <= '0';
                        end if;
                    elsif drv_state_ready then
                        run_io(op_data_type, rw_mode, op_timestamp);
                        if io_stage = mem_ready then
                            state <= idle;
                        end if;
                    end if;
                when others => state <= idle;
            end case;
            if enable = '0' and trigger_fired then
                trigger_fired := false;
            end if;
        end if;
    end process;
end arch;
