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
    signal state : common_state_type := initialize;
begin
    SENSOR_MANAGER: process(clocks.CLK_1M19)
        variable sleep : unsigned(3 downto 0) := (others => '0');
        variable fired : boolean := false;
    begin
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when initialize =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        state <= idle;
                        ready <= '1';
                    end if;
                when idle =>
                    if enable = '1' and not fired then
                        state <= busy;
                        ready <= '0';
                        fired := true;
                    end if;
                when busy =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        -- mock some results
                        temperature  <= "010" & x"F";  -- 7C
                        humidity     <= "001" & x"E";  -- 30%
                        pressure     <= "011" & x"F2"; -- 1010hPa
                        pm10_reading <=   "0" & x"23"; -- 35 ug/m3
                        -- signal done
                        state <= idle;
                        ready <= '1';
                    end if;
                when others => state <= idle; ready <= '1';
            end case;
            if fired and enable = '0' then
                fired := false;
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
