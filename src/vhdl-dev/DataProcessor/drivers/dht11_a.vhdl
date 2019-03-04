architecture arch of dht11 is
    signal state     : common_state_type := initialize;
    signal busy_prev : STD_LOGIC := '0';
begin
    DHT11_DRV: process(clocks.CLK_1M19)

    -- we need ~1.19 milion iterations to wait 1 second
    constant second : unsigned(20 downto 0) := (20 => '1', 18 => '1', others => '0'); -- this is slightly more
    variable i : unsigned(20 downto 0) := (others => '1'); -- this is slightly more
    variable read_stage  : integer range 0 to  6 := 0;
    variable bit_counter : integer range 0 to 40 := 0;
    variable hum_data,
             temp_data   : unsigned(15 downto 0) := (others => '0');
    variable checksum    : unsigned( 7 downto 0) := (others => '0');
    variable err_count   : integer range 0 to 5 := 0;

    -- List of data read time points, 1 tick of virt_clk is 0.84us
    constant START_SIG   : integer := 21500; -- slightly over 18ms
    constant MIN_RSP_LEN : integer := 22; -- the minimal time between start and response
    constant PRE_DAT_LEN : integer := 130; -- the minimal time from the response to the first data bit
    constant BIT_0_MIN   : integer := 20; -- minimal duration of a '0' bit
    constant BIT_0_MAX   : integer := 40; -- maximal duration of a '0' bit
    constant BIT_1_MIN   : integer := 70; -- minimal duration of a '1' bit
    constant BIT_1_MAX   : integer := 90; -- maximal duration of a '1' bit

    procedure reset_sensor(constant new_state : in common_state_type := initialize) is begin
        read_stage := 0;
        state <= new_state;
        i := second;
    end procedure;

    -- stages:
    --  * send the start signal (low/high)
    --  * wait for confirmation (low/high)
    --  * read data: 40x (low/high) measuring the high time
    procedure read_sensor is
        variable busy_rising  : boolean := false;
        variable bit_read     : std_logic := '0';
        variable checksum_tmp : unsigned(9 downto 0) := (others => '0');
    begin
        i := i + 1;

        busy_prev <= HUM_DAT;
        busy_rising := (busy_prev = '0' and HUM_DAT = '1');

        case read_stage is
            when 0 =>
                -- pull down comms
                HUM_DAT <= '0';
                read_stage := 1;
                i := (others => '0');
            when 1 =>
                -- after ~18ms pull up
                if i > START_SIG then
                    -- now release it and wait for a response
                    HUM_DAT <= 'Z';
                    read_stage := 2;
                    i := (others => '0');
                end if;
            when 2 =>
                -- confirmation starts no less than after 20us
                if i > MIN_RSP_LEN and busy_rising then
                    read_stage := 3;
                    i := (others => '0');
                end if;
            when 3 =>
                -- now wait for the rising signal again and start measuring the first bit
                if i > PRE_DAT_LEN and busy_rising then
                    read_stage := 4;
                    bit_counter := 39; -- MSB
                    -- reset data storage and counter
                    temp_data := (others => '0');
                    hum_data  := (others => '0');
                    i := (others => '0');
                end if;
            when 4 =>
                -- wait for signal to be low again
                if HUM_DAT = '0' then
                    if i > BIT_0_MIN and i < BIT_0_MAX then
                        -- it's a '0'
                        bit_read := '0';
                    elsif i > BIT_1_MIN and i < BIT_1_MAX then
                        -- it's a '1'
                        bit_read := '1';
                    else 
                        -- unexpected bit
                        reset_sensor;
                        err_count := err_count + 1;
                    end if;

                    if bit_counter > 23 then
                        hum_data(bit_counter - 24) := bit_read;
                    elsif bit_counter > 7 then
                        temp_data(bit_counter - 8) := bit_read;
                    else
                        checksum(bit_counter) := bit_read;
                    end if;
                    -- are there any more bits expected?
                    if bit_counter > 0 then
                        -- wait for next bit
                        read_stage := 5;
                    else
                        -- ok, we've got every bit
                        read_stage := 6;
                    end if;
                end if;
            when 5 =>
                if busy_rising then
                    bit_counter := bit_counter - 1;
                    read_stage := 4;
                    i := (others => '0');
                end if;
            when 6 =>
                -- verify the checksum
                checksum_tmp := "00" & hum_data(15 downto 8) + hum_data(7 downto 0) + temp_data(15 downto 8) + temp_data(7 downto 0);
                if checksum_tmp(7 downto 0) = checksum then
                    -- if it matches, we can output the data, only use the integral part (decimal doesn't make sense anyway)
                    out_temperature <= to_unsigned(to_integer(temp_data(15 downto 8)), 7);
                    out_humidity    <= to_unsigned(to_integer( hum_data(15 downto 8)), 7);

                    reset_sensor(idle);
                    err_count := 0;
                else
                    -- retry?
                    reset_sensor;
                    i := (others => '0');
                    err_count := err_count + 1;
                end if;
        end case;

        -- detect communication stalls (e.g. too long waiting for busy to rise)
        if read_stage > 0 and i > START_SIG then
            -- this should never occur during normal operation
            -- force reset and retry
            reset_sensor;
            err_count := err_count + 1;
        end if;

        -- crash if we get 5 consecutive errors
        if err_count = 5 then
            state <= error;
            out_humidity    <= to_unsigned(0, 7);
            out_temperature <= to_unsigned(0, 7);
        end if;
    end procedure;

    begin
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when initialize =>
                    -- we need to wait for 1s for the sensor to stabilize
                    if i > 0 then
                        i := i - 1;
                    else
                        state <= idle;
                    end if;
                when idle =>
                    ready <= '1';
                    -- wait for trigger
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                        i := (others => '0');
                    end if;
                when busy =>
                    -- when done, it will transition back to idle
                    read_sensor;
                when error =>
                    -- wait one second and go back to idle state
                    i := i + 1;
                    if i = 0 then
                        err_count := 0;
                        state <= idle;
                    end if;
            end case;
        end if;
    end process;
end arch;
