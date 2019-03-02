library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;

entity Sensor is
    PORT (
        clocks : IN t_clocks;

        enable :  IN STD_LOGIC := '0'; -- single fire mode, to init another reading it needs to be toggled
        ready  : OUT STD_LOGIC := '0';

        -- Settings
        REFERENCE_PRESS : IN STD_LOGIC_VECTOR( 7 downto 0);

        -- Output data
        temperature,
        humidity      : OUT STD_LOGIC_VECTOR( 6 downto 0) := (others => '0');
        pressure      : OUT STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
        pm10_reading  : OUT STD_LOGIC_VECTOR( 8 downto 0) := (others => '0');

        -- I/O
        sensors_in    :    IN t_sensors_in;
        sensors_out   :   OUT t_sensors_out;
        sensors_inout : INOUT t_sensors_inout
    );
END entity;

architecture arch of Sensor is
    signal fired, xfer_running : boolean := false;
    signal xfer_item : integer := 0;
begin
    SENSOR_MOCK: process(clocks.CLK_1M19)
        variable sleep : unsigned( 5 downto 0) := (others => '0');
        variable data  : unsigned(DATA_TEMP_OFFSET downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_1M19) then
            if not fired and ready = '1' and enable = '1' then
                ready <= '0';
                fired <= true;
            elsif ready = '0' then
            -- test bench data pipe for BT commands
                if xfer_running then
                    data(xfer_item) := sensors_in.ADC_SDAT;
                    if xfer_item > 0 then
                        xfer_item <= xfer_item - 1;
                    else
                        xfer_running <= false;
                    end if;
                elsif sensors_in.ADC_SDAT = '1' then
                    xfer_running <= True;
                    xfer_item <= DATA_TEMP_OFFSET;
                else
                    sleep := sleep + 1;
                    if sleep = 0 then
                        -- signal ready
                        temperature  <= std_logic_vector(data(DATA_TEMP_OFFSET  downto DATA_HUM_OFFSET   + 1));
                        humidity     <= std_logic_vector(data(DATA_HUM_OFFSET   downto DATA_PM10_OFFSET  + 1));
                        pm10_reading <= std_logic_vector(data(DATA_PM10_OFFSET  downto DATA_PRESS_OFFSET + 1));
                        pressure     <= std_logic_vector(data(DATA_PRESS_OFFSET downto 0));
                        ready <= '1';
                    end if;
                end if;
            end if;
            if enable = '0' then
                fired <= false;
            end if;
        end if;
    end process;
    -- Keep simulations tidy
    sensors_out.ADC_SADDR <= '0';
    sensors_out.ADC_CS_N <= '0';
    sensors_out.ADC_SCLK <= '0';
    sensors_out.PM_ILED <= '0';
    sensors_out.PRESS_SDO <= '0';
    sensors_out.PRESS_CS <= '0';
    sensors_inout.PRESS_SDA <= '0';
    sensors_inout.PRESS_SCL <= '0';
    sensors_inout.HUM_DAT <= '0';
end arch;
