architecture arch of Sensor is
    signal state : common_state_type := initialize;

    constant GP2Y1010 : integer := 0;
    constant LPS331AP : integer := 1;
    constant DHT11    : integer := 2;

    -- Driver flags
    signal drv_enable, drv_ready : std_logic_vector(2 downto 0) := (others => '0');
    -- Data
    signal gp2y1010_val         : unsigned( 8 downto 0) := (others => '0');
    signal dht11_humidity,
           lps331ap_temperature : unsigned( 6 downto 0) := (others => '0');
    signal lps331ap_pressure    : unsigned(10 downto 0) := (others => '0');
begin
    pm10sensor : entity drivers.gp2y1010 PORT MAP (
        clocks => clocks,

        -- Control
        enable => drv_enable(GP2Y1010),
        ready  => drv_ready(GP2Y1010),

        -- I/O
        ADC_SADDR => sensors_out.ADC_SADDR, ADC_SDAT => sensors_in.ADC_SDAT,
        ADC_CS_N => sensors_out.ADC_CS_N, ADC_SCLK => sensors_out.ADC_SCLK,
        PM_ILED => sensors_out.PM_ILED,
        output => gp2y1010_val
    );

    pressure_sensor : entity drivers.lps331ap PORT MAP (
        clocks => clocks,

        -- Control
        enable => drv_enable(LPS331AP),
        ready  => drv_ready(LPS331AP),

        REFERENCE_PRESS => REFERENCE_PRESS,
        -- I/O
        PRESS_SDA => sensors_inout.PRESS_SDA, PRESS_SCL => sensors_inout.PRESS_SCL,
        PRESS_SDO => sensors_out.PRESS_SDO, PRESS_CS => sensors_out.PRESS_CS,

        out_temperature => lps331ap_temperature, out_pressure => lps331ap_pressure
    );

    humidity_sensor : entity drivers.dht11 PORT MAP (
        clocks => clocks,

        -- Control
        enable => drv_enable(DHT11),
        ready  => drv_ready(DHT11),

        -- I/O
        HUM_DAT => sensors_inout.HUM_DAT,
        out_humidity => dht11_humidity
    );

    SENSOR_MANAGER: process(clocks.CLK_1M19)
        variable drv_init, drv_busy : unsigned(2 downto 0) := (others => '0');
        variable enable_fired : boolean := false;

        procedure read_sensors(constant trigger : in boolean := false) is begin

            for DEVICE in GP2Y1010 TO DHT11 loop
                if drv_ready(DEVICE) = '1' then
                    drv_init(DEVICE) := '1';

                    if trigger then
                        drv_enable(DEVICE) <= '1';
                    elsif drv_enable(DEVICE) = '1' then
                        drv_busy(DEVICE) := '1';
                    elsif drv_busy(DEVICE) = '1' then
                        drv_busy(DEVICE) := '0';
                        -- latch in the data
                        case DEVICE is
                            when GP2Y1010 => pm10_reading <= STD_LOGIC_VECTOR(gp2y1010_val);
                            when DHT11    => humidity     <= STD_LOGIC_VECTOR(dht11_humidity);
                            when LPS331AP =>
                                temperature <= STD_LOGIC_VECTOR(lps331ap_temperature);
                                pressure    <= STD_LOGIC_VECTOR(lps331ap_pressure);
                            when others => NULL;
                        end case;
                    end if;
                else
                    drv_enable(DEVICE) <= '0';
                end if;
            end loop;
        end procedure;

    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when initialize =>
                    read_sensors;
                    -- wait for all driver states to become ready
                    if drv_init = 7 then
                        state <= idle;
                    end if;
                when idle =>
                    ready <= '1';
                    if enable = '1' then
                        -- trigger the reading operation (runs twice)
                        ready <= '0';
                        read_sensors(not enable_fired);
                        if not enable_fired then
                            enable_fired := true;
                        else
                            -- don't switch state at the first run
                            state <= busy;
                        end if;
                    end if;
                when busy =>
                    -- wait for each driver to finish
                    read_sensors;
                    -- when all requests are resolved, go back to idle state
                    if drv_busy = 0 then
                        state <= idle;
                    end if;
                when others => state <= idle;
            end case;

            -- reset enable_fired, when enable goes low
            if enable = '0' and enable_fired then
                enable_fired := false;
            end if;
        end if;
    end process;
end arch;
