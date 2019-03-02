architecture arch of rn4020 is
    -- base for service UUIDs
    constant uuid_base     : String := "0CC3E2897A82448EBD8B9D3552F5380";
    constant default_name  : String := "SPSP-001" & NUL & NUL;
    constant MAX_BUF_HBYTE : Integer := MAX_BUF_BYTE * 2;
    constant MAX_BUF_BIT   : Integer := MAX_BUF_BYTE * 8 - 1;

    type rn4020_state_type is (disabled, initialize, reinit, idle, busy, error);
    signal state : rn4020_state_type := disabled;
    signal tx_sig, tx_busy, rx_sig, rx_busy, rx_err : STD_LOGIC := '0';
    signal tx_data, rx_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal cooloff_syn, cooloff_ack : std_logic := '0';
    signal cooloff_cnt : unsigned(14 downto 0) := (others => '0');
begin
    uart_drv : entity ext.uart GENERIC MAP (
        clk_freq  => 50_000_000,
        baud_rate => 115_200,
        os_rate => 8,
        parity => 0
    ) PORT MAP (
		clk => clocks.CLK_50M,
        rx => RX, tx => TX,
		reset_n => '1',
		tx_data => tx_data, rx_data => rx_data,
		tx_ena => tx_sig, rx_busy => rx_busy,
        tx_busy => tx_busy, rx_error => rx_err
    );

    RN4020_COOLOFF: process(clocks.CLK_0M5) is begin
        if rising_edge(clocks.CLK_0M5) then
            if cooloff_syn = '1' and cooloff_ack = '0' then
                cooloff_ack <= '1';
                if state = initialize or state = reinit then
                    cooloff_cnt <= to_unsigned(25000, 15); -- 50ms for setup
                else
                    cooloff_cnt <= to_unsigned(500, 15); -- 1ms for normal ops
                end if;
            elsif cooloff_syn = '0' and cooloff_ack = '1' then
                cooloff_ack <= '0';
            end if;
            if cooloff_cnt > 0 then
                cooloff_cnt <= cooloff_cnt - 1;
            end if;
        end if;
    end process;

    RN4020_DRV: process(clocks.CLK_1M19) is
        type command_state_type is (idle, init, writing, reading, cooloff, done, error);
        type command_response is (cmd, aok, hexdata);

        variable setup_step : integer range 0 to 18 := 0;
        variable used_name  : string (1 to 10) := default_name;

        variable command_state,
                 next_cmd_state: command_state_type := idle;
        variable io_buffer     : string(1 to 5) := (others => NUL);
        variable command_pos   : integer range 1 to MAX_CMD_LEN := 1;
        variable output_pos    : integer range 1 to MAX_BUF_HBYTE + 1 := 1;
        variable last_char, byte_read : boolean := false;

        procedure uart_command (
                constant command  : in string := "";
                constant response : in command_response;
                signal output     : out std_logic_vector) is
            variable resp_ok : boolean := false;
            variable c       : character := NUL; 
            variable out_a,
                     out_b   : integer range 0 to MAX_BUF_BIT := 0;
        begin
            case command_state is
                when idle =>
                    tx_sig <= '0';
                    cooloff_syn <= '0';
                when init =>
                    if cooloff_cnt = 0 then
                        last_char := false;
                        byte_read := false;
                        -- reset command index
                        command_pos := 1;
                        -- reset output index
                        output_pos := 1;
                        -- reset data buffer and cooloff counter
                        io_buffer   := (others => NUL);
                        -- tx_sig <= '0';
                        if command'length < 2 then
                            command_state := reading;
                        else
                            command_state := writing;
                        end if;
                    end if;
                when writing =>
                    -- send command
                    if tx_busy = '0' and tx_sig = '0' then
                        -- when we reach end of command, send the LineFeed character
                        if command(command_pos) = NUL then
                            tx_data <= c2v(LF);
                            last_char := true;
                        else
                            tx_data <= c2v(command(command_pos));
                            command_pos := command_pos + 1;
                        end if;
                        tx_sig  <= '1';
                    elsif tx_busy = '1' and tx_sig = '1' then
                        tx_sig <= '0';
                        if last_char then
                            -- switch to receiving
                            command_state := reading;
                        end if;
                    end if;
                when reading =>
                    -- wait for rx_busy to assert (receiving has started)
                    if rx_busy = '1' and not byte_read then
                        byte_read := true;
                    -- then read the response when it deasserts
                    elsif rx_busy = '0' and byte_read then
                        -- if this is the first byte, make sure we clear the buffer before using it
                        c := v2c(rx_data);
                        byte_read := false;

                        -- now check for a LineFeed
                        if c = LF then
                            -- is this the expected response?
                            case response is
                                when cmd     => resp_ok := check_response("CMD", io_buffer, output_pos);
                                when aok     => resp_ok := check_response("AOK", io_buffer, output_pos);
                                when hexdata => resp_ok := output_pos > MAX_BUF_HBYTE;
                            end case;
                            command_state := cooloff;
                            if resp_ok then
                                next_cmd_state := done;
                            else
                                next_cmd_state := error;
                            end if;
                        elsif is_valid(c) then -- only store and increment the position if it's a valid character
                            if response = hexdata then
                                -- overflow protection
                                if output_pos > MAX_BUF_HBYTE then
                                    output_pos := 1;
                                    command_state  := cooloff;
                                    next_cmd_state := error;
                                end if;
                                out_a := (MAX_BUF_HBYTE - output_pos + 1) * 4 - 1;
                                out_b := (MAX_BUF_HBYTE - output_pos) * 4;
                                output(out_a downto out_b) <= hex2v(c);
                            else
                                -- overflow protection
                                if output_pos > io_buffer'HIGH then
                                    -- for cmd/aok we ignore overflows
                                    output_pos := 1;
                                end if;
                                io_buffer(output_pos) := c;
                            end if;
                            output_pos := output_pos + 1;
                        end if;
                    end if;
                    if response /= cmd and rx_err = '1' then
                        command_state  := cooloff;
                        next_cmd_state := error;
                    end if;
                when cooloff =>
                    -- give the driver a moment (~1ms) to "cooloff" after each processed command
                    -- this requirement seems to come from experimenting with the rn4020 itself
                    -- though the docs say nothing about it
                    if cooloff_syn = '0' and cooloff_ack = '0' then
                        cooloff_syn <= '1';
                    elsif cooloff_cnt > 0 then
                        cooloff_syn <= '0';
                        command_state := next_cmd_state;
                    end if;
                when others => NULL;
            end case;
        end procedure;

        variable timeout    : unsigned(15 downto 0) := (others => '0');
        variable subseq_err : unsigned( 1 downto 0) := (others => '0');
        procedure run_cmd(
                variable step      : inout integer;
                constant command   : in string := "";
                constant response  : in command_response := aok;
                signal output      : out std_logic_vector) is
        begin
            case command_state is
                when done =>
                    subseq_err := (others => '0');
                    command_state := idle;
                    step := step + 1;
                    uart_command(command & NUL, response, output);
                when others =>
                    uart_command(command & NUL, response, output);
                    -- error/timeout handling
                    if command_state = error then
                        -- restart the command
                        command_state := idle;
                        -- also check which error this is
                        subseq_err := subseq_err + 1;
                        if subseq_err = 0 then
                            -- if it's the 4th error in a row, restart the whole setup process
                            step := 0;
                            timeout := (others => '0');
                        end if;
                    elsif command_state = idle then
                        command_state := init;
                    end if;
            end case;
        end procedure;

        -- Setup takes on average ~2s to initialize and bootup the Bluetooth antenna
        procedure setup is
            constant add_characteristic : String := "PC," & uuid_base;
            constant ro20 : String := ",02,14";
            constant rw20 : String := ",0A,14";
        begin
            case setup_step is
                -- [220ms] reset mode
                when  0 =>
                    init_progress <= (0 => '1', others => '0');
                    WAKE_HW <= '0';
                    WAKE_SW <= '0';
                    timeout := timeout + 1;
                    if timeout = 0 then
                        -- timeout := (others => '0');
                        setup_step := 1;
                    end if;
                -- [~1ms] switch into CMD mode
                when  1 =>
                    -- wake up the hardware
                    if cooloff_cnt = 0 then
                        WAKE_SW <= '1';
                        WAKE_HW <= '1';
                    end if;
                    run_cmd(setup_step, NULL, cmd); -- wait for CMD mode
                -- [24ms] factory reset or full reboot
                when  2 => run_cmd(setup_step, "SF,1"); init_progress(1) <= '1';
                -- [15ms] set services
                when  3 => run_cmd(setup_step, "SS,00000001");
                -- [14ms] set role (auto-advertise)
                when  4 => run_cmd(setup_step, "SR,20000000");
                -- [26ms] set device name
                when  5 => run_cmd(setup_step, "SN," & used_name); init_progress(2) <= '1';
                -- [48ms] clear private services
                when  6 => run_cmd(setup_step, "PZ");
                -- [ 4ms] set private service UUID
                when  7 => run_cmd(setup_step, "PS," & uuid_base & "0");
                -- [52ms each] add a 20 byte r/o characteristic
                when  8 => run_cmd(setup_step, add_characteristic & "1" & ro20);
                when  9 => run_cmd(setup_step, add_characteristic & "2" & ro20);
                when 10 => run_cmd(setup_step, add_characteristic & "3" & ro20);
                when 11 => run_cmd(setup_step, add_characteristic & "4" & ro20);
                when 12 => run_cmd(setup_step, add_characteristic & "5" & ro20);
                when 13 => run_cmd(setup_step, add_characteristic & "6" & ro20);
                when 14 => run_cmd(setup_step, add_characteristic & "7" & ro20);
                when 15 => run_cmd(setup_step, add_characteristic & "8" & ro20);
                -- [52ms] add a 20 byte r/w characteristic
                when 16 => run_cmd(setup_step, add_characteristic & "A" & rw20);
                -- [1383ms] reboot the device to run with newly set configuration
                when 17 => run_cmd(setup_step, "R,1", cmd); init_progress(3) <= '1';
                when 18 =>
                    state <= idle;
                    ready <= '1';
                    WAKE_SW <= '0';
                    init_progress <= (others => '0');
                when others => setup_step := setup_step + 1;
            end case;
        end procedure;

        procedure run_io(
                constant rw       : IN STD_LOGIC;
                constant addr     : IN STD_LOGIC_VECTOR;
                signal data_in    : IN STD_LOGIC_VECTOR;
                signal data_out   : OUT STD_LOGIC_VECTOR;
                variable io_ready : OUT BOOLEAN) is
            variable result : Integer range 0 to 1 := 0;
            variable addr_i : Integer range 0 to 15;
            variable addr_c : Character;
            variable temp   : String(1 to MAX_BUF_HBYTE);
            variable a, b   : integer range 0 to MAX_BUF_BIT := 0;
        begin
            addr_i := to_integer(unsigned(addr));
            if addr_i = 0 or addr_i > 9 then
                state <= error;
                return;
            end if;

            if addr_i <= 8 then
                addr_c := Character'val(48 + addr_i); -- 1-8
            else
                addr_c := 'A'; -- 9
            end if;

            if rw = '0' then
                run_cmd(result, "SUR," & uuid_base & addr_c, hexdata, data_out);
            else
                for I in 1 to MAX_BUF_HBYTE loop
                    a := (MAX_BUF_HBYTE - I + 1) * 4 - 1;
                    b := (MAX_BUF_HBYTE - I) * 4;
                    temp(I) := v2hex(data_in(a downto b));
                end loop;
                run_cmd(result, "SUW," & uuid_base & addr_c & ',' & temp);
            end if;

            io_ready := result > 0;
        end procedure;

        procedure update_name is begin
            case setup_step is
                -- [220ms] reset mode
                when  0 =>
                    WAKE_SW <= '0';
                    timeout := timeout + 1;
                    if timeout = 0 then
                        setup_step := 1;
                    end if;
                when 1 =>
                    timeout := timeout + 1;
                    -- wake up the hardware after a couple clocks, not immediately
                    if timeout > 10 then
                        WAKE_SW <= '1';
                    end if;
                    run_cmd(setup_step, NULL, cmd); -- wait for CMD mode
                when 2 => run_cmd(setup_step, "SN," & used_name);
                when 3 => run_cmd(setup_step, "R,1", cmd);
                when 4 =>
                    state <= idle;
                    ready <= '1';
                    WAKE_SW <= '0';
                    setup_step := 0;
                when others => setup_step := 0;
            end case;
        end procedure;

        variable rw_mode  : std_logic := '0';
        variable io_ready : boolean;
    begin
        if rising_edge(clocks.CLK_1M19) then
            case state IS
                WHEN disabled =>
                    -- don't start before instructed to
                    if enable = '1' then
                        ready <= '0';
                        state <= initialize;
                        if device_name(1) /= NUL and device_name /= used_name then
                            used_name := device_name;
                        end if;
                    end if;
                WHEN initialize =>
                    setup;
                WHEN reinit =>
                    update_name;
                WHEN idle =>
                    -- wait for run signal
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                        rw_mode  := rw;
                        io_ready := false;
                        data_out <= (others => '0');
                    elsif device_name(1) /= NUL and device_name /= used_name then
                        used_name := device_name;
                        state <= reinit;
                    end if;
                WHEN busy =>
                    run_io(rw_mode, addr, data_in, data_out, io_ready);
                    if io_ready then
                        state <= idle;
                        ready <= '1';
                    end if;
                when error =>
                    if unsigned(addr) > 0 and unsigned(addr) < 10 then
                        -- reset error state when address is back to a valid range
                        state <= idle;
                        ready <= '1';
                    end if;
                WHEN others => NULL;
            end CASE;
        end if;
    end process;
end arch;
