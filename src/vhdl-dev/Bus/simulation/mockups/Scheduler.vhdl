-- Scheduler mockup
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;

entity Scheduler is
    PORT (
        clocks    :  IN t_clocks;
        ready     : OUT STD_LOGIC := '0';

        -- Settings
        REFERENCE_PRESS     :  IN STD_LOGIC_VECTOR( 7 downto 0);
        read_freq_setting   :  IN STD_LOGIC_VECTOR( 5 DOWNTO 0);
        measurement_out     : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);

        -- I/O
        sensors_in          :    IN t_sensors_in;
        sensors_out         :   OUT t_sensors_out;
        sensors_inout       : INOUT t_sensors_inout
    );
END entity;

-- Generic processing order:
--  gather data -> store data -> refresh settings -> wait
architecture arch of Scheduler is
    type scheduler_state_type is (idle, gather_data, set_checksum);
    signal state : scheduler_state_type := idle;
    signal trigger : unsigned(9 downto 0) := (others => '0');
    signal trigger_run : std_logic := '0';
begin
    SCHEDULER_TRIGGER: process(clocks.CLK_0HZ1)
        constant MULT : unsigned(3 downto 0) := to_unsigned(10, 4);
    begin
        if rising_edge(clocks.CLK_0HZ1) and trigger_run = '1' and unsigned(read_freq_setting) > 0 then
            if trigger > 0 then
                trigger <= trigger - 1;
            else
                trigger <= unsigned(read_freq_setting) * MULT - 1;
            end if;
        end if;
    end process;

    SCHEDULER_SENSORS: process(clocks.CLK_1M19)
        variable sens_fired, trigger_handled : boolean := false;
        variable sleep    : unsigned( 3 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_1M19) and REFERENCE_PRESS /= (0 to 7 => 'U')  then
           case state is
                when idle =>
                    -- use trigger_handled to prohibit double fire (due to clock speed difference)
                    if trigger = 0 and not trigger_handled then
                        trigger_handled := true;
                        state <= gather_data;
                        ready <= '0';
                    end if;
                when gather_data =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        -- when the readout process is done
                        measurement_out <= (0 => '1', 11 => '1', 20 => '1', 27 => '1', others => '0');
                        state <= set_checksum;
                    end if;
                when set_checksum =>
                    measurement_out(CHECKSUM_OFFSET downto CHECKSUM_OFFSET - 5) <= i2v(46, CHECKSUM_LEN);
                    state <= idle;
                    ready <= '1';
                    trigger_run <= '1';
            end case;
            if trigger > 0 and trigger_handled then
                trigger_handled := false;
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
