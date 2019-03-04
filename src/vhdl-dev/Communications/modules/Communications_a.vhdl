architecture arch of Communications is
    -- rn4020 config
    signal bt_cfg   : t_rn4020_cfg;
    type comms_state_type is (
        disabled, initialize, idle, parse, respond,
        call_storage, call_storage_next_entry, call_storage_next_channel, blank_bt_channel,
        comms_running
    );
    signal state, return_state : comms_state_type := disabled;
    signal listen : std_logic := '0';
    signal listen_syn, listen_ack, listen_rst : boolean := false;
    signal uid : unsigned(15 downto 0) := (others => '0');
    -- marker constants
    constant REQ_ARG_LSB : integer := 16;
begin
    listen <= comms_in.BT_CONNECTED;

    rn4020_drv : entity drivers.rn4020 PORT MAP (
        clocks => clocks,
        ready  => bt_cfg.ready,
        enable => bt_cfg.trigger,

        -- driver config
        rw => bt_cfg.rw_mode,
        addr => bt_cfg.addr,
        data_in => bt_cfg.data_in,
        data_out => bt_cfg.data_out,
        device_name => btname,

        -- driver I/O
        RX => comms_in.BT_RX, TX => comms_out.BT_TX,
        WAKE_SW => comms_out.BT_WAKE_SW, WAKE_HW => comms_out.BT_WAKE_HW
    );

    -- Triggers a listen_syn every 10ms, unless the module is busy
    REQUEST_LISTENER: process(clocks.CLK_0HZ01) begin
        if rising_edge(clocks.CLK_0HZ01) and listen = '1' then
            if listen_syn and listen_ack then
                listen_syn <= false;
            elsif not listen_syn and not listen_ack then
                listen_syn <= true;
                sleep_led <= not sleep_led;
            end if;
        end if;
    end process;

    REQUEST_HANDLER: process(clocks.CLK_0M5)
        -- the following is required to workaround a Quartus Prime issue when elaborating
        -- the assingment of an aggregate over a variable memory range:
        -- bt_cfg.data_in(chaddr1 downto chaddr4)
        -- doing it directly caused quartus_map to crash with memory violation (segfault)
        constant empty_40b_block : std_logic_vector(39 downto 0) := (others => '0');
        constant empty_6b_block  : std_logic_vector( 5 downto 0) := (others => '0');
        variable record_count    : unsigned(4 downto 0) := (others => '0');

        function parse_request(
                constant request     : in STD_LOGIC_VECTOR;
                constant freq_sett   : in STD_LOGIC_VECTOR;
                constant unique_id   : in UNSIGNED(15 downto 0)
            ) return t_comms_request is
            variable a, b    : integer range 0 to 159;
            variable tmp_v   : std_logic_vector(7 downto 0);
            variable command : String(1 to 10);
            variable parsed_req  : t_comms_request;
            variable storage_req : t_storage_request;
        begin
            -- start with an unknown request
            parsed_req.parsed_ok := False;
            -- set some defaults
            parsed_req.req_type := storage_data;
            storage_req.data := (others => '0');
            storage_req.reset := '0';
            storage_req.latest := False;
            -- next check the unique id, since it's least work
            parsed_req.uid := unsigned(request(REQ_ARG_LSB - 1 downto 0));
            -- if we already know this uid, just return
            if parsed_req.uid > 0 and parsed_req.uid <= unique_id then
                return parsed_req;
            end if;
            -- convert input vector into a string
            for I in 0 to 9 loop
                a := (20 - I) * 8 - 1;
                b := (19 - I) * 8;
                tmp_v(7 downto 0) := request(a downto b);
                command(I + 1) := v2c(tmp_v);
            end loop;
            -- read requests
            if command(1 to 8) = "RESETUID" then
                if unique_id > 1 then
                    parsed_req.req_type := reset_uid;
                end if;
            elsif command(1 to 3) = "GET" then
                storage_req.rw_mode := '0';
                if command(4 to 6) = "CFG" then
                    case command(7 to 10) is
                        when "PM10" => storage_req.data_type := setting_pm10_norm;       parsed_req.parsed_ok := True;
                        when "FREQ" => storage_req.data_type := setting_read_freq;       parsed_req.parsed_ok := True;
                        when "SAMP" => storage_req.data_type := setting_avg_sample_size; parsed_req.parsed_ok := True;
                        when others => NULL;
                    end case;
                elsif command(4 to 9) = "STORED" then
                    storage_req.resolution := unsigned(request(REQ_ARG_LSB + 25 downto REQ_ARG_LSB + 20));
                    storage_req.timestamp  := request(REQ_ARG_LSB + 19 downto REQ_ARG_LSB);
                    storage_req.data_type  := data_record;
                    parsed_req.parsed_ok   := True;
                    if storage_req.resolution = 0 then
                        storage_req.resolution := unsigned(freq_sett);
                    end if;
                elsif command(4 to 10) = "READING" then
                    storage_req.latest    := True;
                    storage_req.data_type := data_record;
                    parsed_req.parsed_ok  := True;
                elsif command(4 to 9) = "BTNAME" then
                    storage_req.data_type := setting_device_name;
                    parsed_req.parsed_ok  := True;
                elsif command(4 to 10) = "DISPOFF" then
                    storage_req.data_type := setting_display_timeout;
                    parsed_req.parsed_ok := True;
                elsif command(4 to 10) = "PRESSPT" then
                    storage_req.data_type := setting_pressure_reference;
                    parsed_req.parsed_ok := True;
                elsif command(4 to 10) = "TMSTAMP" then
                    parsed_req.req_type := current_timestamp;
                    parsed_req.parsed_ok := True;
                end if;
            -- write requests
            elsif command(1 to 3) = "SET" then
                storage_req.rw_mode := '1';
                if command(4 to 6) = "CFG" then
                    case command(7 to 10) is
                        when "PM10" =>
                            storage_req.data_type := setting_pm10_norm;
                            storage_req.data(7 downto 0) := request(REQ_ARG_LSB + 7 downto REQ_ARG_LSB);
                            parsed_req.parsed_ok := True;
                        when "FREQ" =>
                            storage_req.data_type := setting_read_freq;
                            storage_req.data(5 downto 0) := request(REQ_ARG_LSB + 5 downto REQ_ARG_LSB);
                            parsed_req.parsed_ok := True;
                        when "SAMP" =>
                            storage_req.data_type := setting_avg_sample_size;
                            storage_req.data(5 downto 0) := request(REQ_ARG_LSB + 5 downto REQ_ARG_LSB);
                            parsed_req.parsed_ok := True;
                        when others => NULL;
                    end case;
                elsif command(4 to 9) = "BTNAME" then
                    storage_req.data_type := setting_device_name;
                    storage_req.data(59 downto 0) := request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB + 4);
                    parsed_req.parsed_ok := True;
                elsif command(4 to 10) = "DISPOFF" then
                    storage_req.data_type := setting_display_timeout;
                    storage_req.data(5 downto 0) := request(REQ_ARG_LSB + 5 downto REQ_ARG_LSB);
                    parsed_req.parsed_ok := True;
                elsif command(4 to 10) = "PRESSPT" then
                    storage_req.data_type := setting_pressure_reference;
                    storage_req.data(7 downto 0) := request(REQ_ARG_LSB + 7 downto REQ_ARG_LSB);
                    parsed_req.parsed_ok := True;
                end if;
            elsif command(1 to 8) = "RESETCFG" then
                storage_req.reset := '1';
                parsed_req.parsed_ok := True;
            end if;
            -- attach the storage config record
            parsed_req.storage_req := storage_req;

            return parsed_req;
        end function;

        procedure run_comms_and(constant rstate : in comms_state_type) is begin
            bt_cfg.trigger <= '1';
            state <= comms_running;
            return_state <= rstate;
        end procedure;

        constant command_addr     : std_logic_vector(3 downto 0) := i2v(9, 4);
        variable last_request     : std_logic_vector(159 downto 0) := (others => '0');
        variable parsed_request   : t_comms_request;
        variable bt_data_channel  : integer range 1 to 8 := 1;
        variable bt_next_entry    : integer range 1 to 4 := 1;
        variable chaddr1, chaddr2 : integer range 0 to 159;
        variable no_more_data,
                 overflow_request : boolean := false;
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_0M5) then
            case state is
                when disabled =>
                    if enable = '1' then
                        run_comms_and(initialize);
                    end if;
                when initialize =>
                    ready <= '1';
                    state <= idle;
                when idle =>
                    if not listen_syn and listen_ack then
                        listen_ack <= false;
                    elsif listen_syn and not listen_ack then
                        -- resetting the uid on new BT connect signal
                        if not listen_rst and listen = '1' then
                            listen_rst <= true;
                        end if;
                        listen_ack <= true;
                        bt_cfg.addr <= command_addr;
                        bt_cfg.rw_mode <= '0';
                        ready <= '0';
                        run_comms_and(parse);
                    end if;
                    if listen_rst and listen = '0' then
                        listen_rst <= false;
                        -- reset uid
                        uid <= (others => '0');
                        -- now clear the command channel
                        bt_cfg.addr <= command_addr;
                        bt_cfg.rw_mode <= '1';
                        bt_cfg.data_in <= (others => '0');
                        run_comms_and(idle);
                    end if;
                when parse =>
                    -- ok, now try to parse the request
                    -- display(7 downto 0) <= unsigned(bt_cfg.data_out(7 downto 0));
                    parsed_request := parse_request(bt_cfg.data_out, read_freq_setting, uid);
                    -- if parsing succeded and it's a new request
                    if parsed_request.parsed_ok then
                        busy <= '1';
                        -- store request for later
                        last_request := bt_cfg.data_out;
                        uid <= parsed_request.uid;

                        if parsed_request.req_type = storage_data then
                            -- tell storage what we want
                            storage_request <= parsed_request.storage_req;
                            state <= call_storage;
                            record_count := (others => '0');
                            storage_syn <= '1';
                            -- remember to use parsed_request here, since storage_request will be set on the next clock!
                            if parsed_request.storage_req.reset /= '1' and parsed_request.storage_req.data_type = data_record then
                              -- set initial values for data record gathering
                                bt_data_channel  := 1;
                                bt_next_entry    := 2;
                                no_more_data     := false;
                                overflow_request := false;
                            end if;
                            -- start preparing the first channel data by setting the timestamp
                            bt_cfg.data_in <= (others => '0');
                            bt_cfg.data_in(145 downto 140) <= std_logic_vector(parsed_request.storage_req.resolution);
                            bt_cfg.data_in(139 downto 120) <= parsed_request.storage_req.timestamp;
                        elsif parsed_request.req_type = current_timestamp then
                            -- if all the user wants is the current timestamp, move directly to response
                            bt_cfg.addr <= command_addr;
                            bt_cfg.rw_mode <= '1';
                            -- clear the args field
                            last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB + 19) := (others => '0');
                            -- set the timestamp
                            last_request(REQ_ARG_LSB + 19 downto REQ_ARG_LSB) := timestamp;
                            -- update uid in request with a higher value
                            last_request(REQ_ARG_LSB - 1 downto 0) := std_logic_vector(parsed_request.uid + 1);
                            bt_cfg.data_in <= last_request;
                            run_comms_and(respond);
                        end if;
                    else
                        if parsed_request.req_type = reset_uid then
                            uid <= (others => '0');
                        end if;
                        -- back to idle
                        state <= idle;
                        ready <= '1';
                    end if;
                when call_storage =>
                    if storage_ack = '1' then
                        storage_syn <= '0';
                        -- now prepare the request response
                        bt_cfg.rw_mode <= '1';

                        -- handling data records is a bit more tricky
                        -- since most likely we will need to collect more info from the storage
                        if storage_request.reset /= '1' and storage_request.data_type = data_record and not storage_request.latest then
                            -- first store the received data in the channel at the correct offset
                            chaddr1 := (5 - bt_next_entry) * 40 - 1;
                            chaddr2 := chaddr1 - 39;
                            -- if the first record indicates an overflow
                            if bt_data_channel = 1 and bt_next_entry = 2 and storage_response.overflow = '1' then
                                -- set an overflow ignore flag for the whole request
                                overflow_request := true;
                            end if;
                            if storage_response.data(39 downto 0) = (39 downto 0 => 'U') or (storage_response.overflow = '1' and not overflow_request) then
                                -- we're trying to read data from a long time ago (beyond the current write mark)
                                bt_cfg.data_in(chaddr1 downto 0) <= (chaddr1 downto 0 => '0');
                                -- prevent further storage requests
                                no_more_data := true;
                            else
                                record_count := record_count + 1;
                                bt_cfg.data_in(chaddr1 downto chaddr2) <= storage_response.data(39 downto 0);
                            end if;
                            -- did we reach the end of slots in the channel?
                            if bt_next_entry < 4 then
                                bt_next_entry := bt_next_entry + 1;
                                -- we need to wait for Bus to deassert ack
                                state <= call_storage_next_entry;
                            else
                                -- now setup the BT write for the current channel
                                bt_cfg.addr <= i2v(bt_data_channel, 4);
                                bt_next_entry := 1;
                                if bt_data_channel < 8 then
                                    bt_data_channel := bt_data_channel + 1;
                                else
                                    bt_data_channel := 1;
                                end if;
                                run_comms_and(call_storage_next_channel);
                            end if;
                        else
                            -- in all other cases we only do one write to the command addr
                            bt_cfg.addr <= command_addr;
                            -- update uid in request with a higher value
                            last_request(REQ_ARG_LSB - 1 downto 0) := std_logic_vector(uid + 1);
                            -- add data read from the storage, if available
                            if storage_request.latest then
                                last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB) := (others => '0');
                                last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB + 24) := storage_response.data(39 downto 0);
                                -- 23-20 - unused (for now)
                                last_request(REQ_ARG_LSB + 19 downto REQ_ARG_LSB) := storage_response.timestamp;
                            elsif storage_request.rw_mode = '0' then
                                case storage_request.data_type is
                                    when setting_pm10_norm =>
                                        last_request(REQ_ARG_LSB +  7 downto REQ_ARG_LSB) := storage_response.data( 7 downto 0);
                                    when setting_read_freq =>
                                        last_request(REQ_ARG_LSB +  5 downto REQ_ARG_LSB) := storage_response.data( 5 downto 0);
                                    when setting_avg_sample_size =>
                                        last_request(REQ_ARG_LSB +  5 downto REQ_ARG_LSB) := storage_response.data( 5 downto 0);
                                    when setting_device_name =>
                                        last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB + 4) := storage_response.data(59 downto 0);
                                    when setting_display_timeout =>
                                        last_request(REQ_ARG_LSB +  5 downto REQ_ARG_LSB) := storage_response.data( 5 downto 0);
                                    when setting_pressure_reference =>
                                        last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB) := std_logic_vector(
                                            to_signed(to_integer(signed(storage_response.data(7 downto 0))), 64)
                                        );
                                    when others => NULL;
                                end case;
                            elsif storage_response.error = '1' then
                                last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB) := (others => '1');
                            end if;
                            -- update the request
                            bt_cfg.data_in <= last_request;
                            run_comms_and(respond);
                        end if;
                    end if;
                when call_storage_next_entry =>
                    if storage_ack = '0' then
                        if no_more_data then
                            state <= blank_bt_channel;
                        else
                            -- setup another storage call
                            storage_request.timestamp <= std_logic_vector(
                                unsigned(storage_request.timestamp) + storage_request.resolution
                            );
                            -- go back
                            state <= call_storage;
                            storage_syn <= '1';
                        end if;
                    end if;
                when call_storage_next_channel =>
                    if storage_ack = '0' then
                        if bt_data_channel > 1 then
                            storage_request.timestamp <= std_logic_vector(
                                unsigned(storage_request.timestamp) + storage_request.resolution
                            );
                            bt_cfg.data_in <= (others => '0');
                            -- go back
                            if no_more_data then
                                state <= blank_bt_channel;
                            else
                                state <= call_storage;
                                storage_syn <= '1';
                            end if;
                        else
                            -- final update after data record
                            bt_cfg.addr <= command_addr;
                            -- update the args field with the number of retrieved records
                            last_request(REQ_ARG_LSB + 63 downto REQ_ARG_LSB + 5) := (others => '0');
                            last_request(REQ_ARG_LSB +  4 downto REQ_ARG_LSB) := std_logic_vector(record_count);
                            -- update the uid
                            last_request(15 downto 0) := std_logic_vector(uid + 1);
                            bt_cfg.data_in <= last_request;
                            run_comms_and(respond);
                        end if;
                    end if;
                    -- bt_data_channel, bt_next_entry
                    -- handle reading up to 31 data sets from storage
                when blank_bt_channel =>
                    -- blank all channels left
                    bt_cfg.rw_mode <= '1';
                    -- now setup the BT write for the current channel
                    bt_cfg.addr <= i2v(bt_data_channel, 4);
                    -- this could be simpler if we'd use an unsigned type
                    if bt_data_channel < 8 then
                        bt_data_channel := bt_data_channel + 1;
                    else
                        bt_data_channel := 1;
                    end if;
                    run_comms_and(call_storage_next_channel);
                when respond =>
                    busy <= '0';
                    -- update the reference uid
                    uid <= uid + 1;
                    -- ok, request response ready, go back to sleep
                    if storage_request.reset /= '1' then
                        state <= idle;
                        ready <= '1';
                    else
                        -- or reinit the whole thing
                        state <= initialize;
                    end if;
                when comms_running =>
                    if std2bool(bt_cfg.trigger) xor std2bool(bt_cfg.ready) then
                        if std2bool(bt_cfg.trigger) then
                            bt_cfg.trigger <= '0';
                        else
                            state <= return_state;
                        end if;
                    end if;
            end case;
        end if;
    end process;
end arch;
