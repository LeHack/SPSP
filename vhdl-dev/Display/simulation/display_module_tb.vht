library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library modules, utils;
    use utils.utils.all;

use std.textio.all;
use work.image_pkg.all;

ENTITY display_simulation_tb IS END entity;

ARCHITECTURE display_simulation_tb_arch OF display_simulation_tb IS
    -- signals
    SIGNAL CLK_50M       : STD_LOGIC := '0';
    SIGNAL KEYS          : STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
    SIGNAL DISP_TIMEOUT  : STD_LOGIC_VECTOR(5 downto 0) := i2v(10, 6);
    SIGNAL sensors_in    : t_sensors_in;
    SIGNAL sensors_out   : t_sensors_out;
    SIGNAL sensors_inout : t_sensors_inout;
    SIGNAL storage_inout : t_storage_inout;
    SIGNAL storage_out   : t_storage_out;
    SIGNAL display_out   : t_display_out;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : std_logic_vector(DATA_PM10P_OFFSET downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP ( HZ_DURATION => to_unsigned(30_000, 26) ) PORT MAP (
        CLOCK_50 => CLK_50M,
        KEYS => KEYS,
        read_freq_setting => i2v(6, 6),
        disp_timeout => DISP_TIMEOUT,

        -- Sensor IO lines
        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout,
        storage_inout => storage_inout, storage_out => storage_out, display_out => display_out
    );

-- drive the 50MHz clock
CLK_GEN: process begin
	if not test_end then
		CLK_50M <= '0';
		wait for 20 ns;
        CLK_50M <= '1';
		wait for 20 ns;
	else
		wait;
	end if;
end process;

stimulus : process
    alias main_state    is << signal i1.state : handler_state_type >>;
    alias clocks        is << signal i1.clocks : t_clocks >>;
    alias seconds_cnt   is << signal i1.seconds_cnt : unsigned(19 downto 0) >>;
    alias sens_ready    is << signal i1.scheduler_mod.sens_ready : std_logic >>;
    alias schd_out      is << signal i1.schd_measurement_out : std_logic_vector(CHECKSUM_OFFSET DOWNTO 0) >>;
    alias dproc_ready   is << signal i1.dproc_ready : std_logic >>;
    alias dproc_out     is << signal i1.dproc_measurement_out : std_logic_vector(DATA_PM10P_OFFSET DOWNTO 0) >>;
    alias disp_ready    is << signal i1.disp_ready  : std_logic >>;
    alias disp_enable   is << signal i1.disp_enable : std_logic >>;
    alias disp_active   is << signal i1.display_mod.disp_enable : std_logic >>;
    alias disp_trigger  is << signal i1.display_mod.trigger : unsigned(9 downto 0) >>;
    alias disp_value    is << signal i1.display_mod.disp_val : unsigned(15 downto 0) >>;

    procedure trigger_test(constant tmsg : IN String) is begin
        test_msg := (others => NUL);
        for I in 1 to tmsg'HIGH loop
            test_msg(I) := tmsg(I);
        end loop;

        test_check <= true;
        wait for 1 ns;
        test_check <= false;
        wait for 1 ns;
    end procedure;

    procedure is_equal(
        constant got  : IN std_logic;
        constant exp  : IN std_logic;
        constant tmsg : IN String
    ) is begin
        test_got := (0 => got, others => '0');
        test_exp := (0 => exp, others => '0');

        trigger_test(tmsg);
    end procedure;

    procedure is_equal(
        constant got  : IN std_logic_vector;
        constant exp  : IN std_logic_vector;
        constant tmsg : IN String
    ) is begin
        test_got := (others => '0');
        test_exp := (others => '0');

        test_got(got'length-1 downto 0) := got;
        test_exp(exp'length-1 downto 0) := exp;

        trigger_test(tmsg);
    end procedure;

    procedure is_equal(
        constant got  : IN Unsigned;
        constant exp  : IN Unsigned;
        constant tmsg : IN String
    ) is begin
        is_equal(std_logic_vector(got), std_logic_vector(exp), tmsg);
    end procedure;

    procedure is_equal(
        constant got  : IN Unsigned;
        constant exp  : IN Integer;
        constant tmsg : IN String
    ) is begin
        is_equal(std_logic_vector(got), std_logic_vector(to_unsigned(exp, 16)), tmsg);
    end procedure;

    type clk_type is (CLK50M, CLK1M19, CLK0M5, CLK0HZ1);
    procedure sync_clk (constant clk : in clk_type := CLK50M; constant c_loop : in integer := 1) is
        variable i : integer := 0;
    begin
        sync_loop: while i < c_loop loop
            case clk is
                when CLK0HZ1 => wait until rising_edge(clocks.CLK_0HZ1);
                when CLK0M5  => wait until rising_edge(clocks.CLK_0M5);
                when CLK1M19 => wait until rising_edge(clocks.CLK_1M19);
                when CLK50M  => wait until rising_edge(clocks.CLK_50M);
            end case;
            i := i + 1;
        end loop;
    end procedure;

    function as_lv(a : in unsigned) return std_logic_vector is begin
        return std_logic_vector(a);
    end function;

    function prepare_sensor_data(
        constant exp_temp, exp_hum, exp_pm10, exp_press : in integer range 0 to 2048
    ) return unsigned is
        variable data : unsigned(DATA_TEMP_OFFSET downto 0) := (others => '0');
    begin
        -- map input to data structure
        data(DATA_TEMP_OFFSET  downto DATA_TEMP_OFFSET  + 1 - DATA_TEMP_LEN)  := to_unsigned(exp_temp,  DATA_TEMP_LEN);
        data(DATA_HUM_OFFSET   downto DATA_HUM_OFFSET   + 1 - DATA_HUM_LEN)   := to_unsigned(exp_hum,   DATA_HUM_LEN);
        data(DATA_PM10_OFFSET  downto DATA_PM10_OFFSET  + 1 - DATA_PM10_LEN)  := to_unsigned(exp_pm10,  DATA_PM10_LEN);
        data(DATA_PRESS_OFFSET downto DATA_PRESS_OFFSET + 1 - DATA_PRESS_LEN) := to_unsigned(exp_press, DATA_PRESS_LEN);

        return data;
    end function;

    procedure set_reading(constant data : in unsigned(DATA_TEMP_OFFSET downto 0)) is begin
        wait until sens_ready = '0';
        sensors_in.ADC_SDAT <= '1';
        sync_clk(CLK1M19);
        for I in DATA_TEMP_OFFSET downto 0 loop
            sensors_in.ADC_SDAT <= data(I);
            sync_clk(CLK1M19);
        end loop;
        sensors_in.ADC_SDAT <= '0';
    end procedure;

    variable exp_data  : unsigned(DATA_TEMP_OFFSET downto 0) := (others => '0');
    variable timestamp : unsigned(19 downto 0) := (others => '0');
begin
    is_equal(disp_active, '1', "Display is enabled from the beginning");
    is_equal(disp_value, (0 to 15 => '1'), "Display shows dashes only at this time");
    wait until sens_ready = '1';
    -- set some readings and wait for the main module to be ready
    exp_data := prepare_sensor_data(exp_temp => 55, exp_hum => 31, exp_pm10 => 34, exp_press => 1010);
    set_reading(exp_data);
    -- check initial state right after top-level reaches READY
    is_equal(schd_out(DATA_TEMP_OFFSET downto 0), (0 to DATA_TEMP_OFFSET=> 'U'), "Scheduler output is not initialized yet");
    wait until main_state = READY; -- second, after storage

    wait until disp_enable = '1';
    is_equal(disp_enable, '1', "Display is enabled during bootup");
    is_equal(dproc_ready, '1', "Data processor finished processing data");
    is_equal(schd_out(DATA_TEMP_OFFSET downto 0),  std_logic_vector(exp_data), "Scheduler output matches what we set");
    is_equal(dproc_out(DATA_TEMP_OFFSET downto 0), std_logic_vector(exp_data), "Data processor output matches what we set");

    -- first confirm that the device shows the bootup flash, without any interactions
    is_equal(KEYS, "11", "Keys are both disabled");
    wait until disp_trigger > 0;
    sync_clk(CLK0HZ1, 2);
    -- store current timestamp
    timestamp := seconds_cnt;
    -- now confirm that while the display is active, it cycles trough available measurements
    is_equal(disp_value,  1_010, "Check if the correct pressure is being displayed");
    -- note the high value "prefixes" causing the first digit to display a letter
    -- stating the type of measurement, see Int_to_Seg from utils/types.vhdl for details
    sync_clk(CLK0HZ1, 16);
    is_equal(disp_value, 12_015, "Check if the correct temperature is being displayed");
    sync_clk(CLK0HZ1, 16);
    is_equal(disp_value, 16_031, "Check if the correct humidity is being displayed");
    sync_clk(CLK0HZ1, 16);
    is_equal(disp_value, 18_034, "Check if the correct pm10 value is being displayed");
    sync_clk(CLK0HZ1, 16);
    is_equal(disp_value, 19_068, "Check if the correct pm10 percentage is being displayed");
    sync_clk(CLK0HZ1, 16);
    is_equal(disp_value,  1_010, "Check if the pressure is being displayed again (loop)");

    wait until disp_active = '0';
    is_equal(seconds_cnt, timestamp + 9, "Display auto-disabled after 10s");

    -- update the reading
    exp_data := prepare_sensor_data(exp_temp => 60, exp_hum => 40, exp_pm10 => 50, exp_press => 1015);
    set_reading(exp_data);
    sync_clk(CLK0M5);

    -- now provide a key press and check that the display re-activates
    -- note that since we're doing it right after setting new sensor data
    -- the event handler is busy processing/storing at this point,
    -- therefore we're also testing delayed keypress handling
    KEYS(0) <= '0';
    sync_clk(CLK0M5); -- keep the press long enough for the device to see it
    KEYS(0) <= '1';
    sync_clk(CLK0HZ1, 4);
    is_equal(disp_active, '1', "Display has been re-activated after a key press");
    -- time the activation again
    timestamp := seconds_cnt;
    sync_clk(CLK0HZ1);
    -- we should see the pressure again
    is_equal(disp_value,  1_011, "Got a new intermediate pressure value after a new reading");
    -- let it display for 0.6 second in total and press a button again
    sync_clk(CLK0HZ1, 5);
    is_equal(disp_value,  1_011, "Pressure is still displayed");
    KEYS(0) <= '0';
    sync_clk(CLK0M5); -- keep the press long enough for the device to see it
    KEYS(0) <= '1';
    sync_clk(CLK0HZ1, 4); -- this should be enough for the display to react and refresh the data
    is_equal(disp_value, 12_016, "We should see the intermediate temperature value now");

    -- confirm that after changing the displayed value, it stays twice the time a normal toggle (3.2s)
    -- and that the next toggle is timed normally (1.6s)
    sync_clk(CLK0HZ1, 28);
    is_equal(disp_value, 12_016, "Temperature is still displayed");
    sync_clk(CLK0HZ1, 2);
    is_equal(disp_value, 16_032, "Humidity comes up next");
    sync_clk(CLK0HZ1, 15);
    is_equal(disp_value, 18_036, "And now we see the PM10 value");

    -- go back to humidity
    KEYS(1) <= '0';
    sync_clk(CLK0M5); -- keep the press long enough for the device to see it
    KEYS(1) <= '1';
    sync_clk(CLK0HZ1, 4); -- this should be enough for the display to react and refresh the data
    is_equal(disp_value, 16_032, "Humidity is back");
    sync_clk(CLK0HZ1, 1);
    is_equal(disp_value, 16_033, "Humidity is updated");
    sync_clk(CLK0HZ1, 26);
    is_equal(disp_value, 16_033, "The display time is also prolonged when pressing <back>");
    sync_clk(CLK0HZ1, 4);
    is_equal(disp_value, 18_037, "And now we see the PM10 value again");

    wait until disp_active = '0';
    is_equal(seconds_cnt, timestamp + 16, "The total display time was longer due to interaction");

    -- wait a moment and change the default timeout value
    sync_clk(CLK0HZ1, 4);
    DISP_TIMEOUT <= i2v(3, 6);
    KEYS(0) <= '0';
    sync_clk(CLK0M5); -- keep the press long enough for the device to see it
    KEYS(0) <= '1';
    sync_clk(CLK0HZ1, 4);
    is_equal(disp_active, '1', "Display has been re-activated after a key press");
    timestamp := seconds_cnt;
    sync_clk(CLK0HZ1);
    -- we should see the pressure again
    is_equal(disp_value,  1_012, "Another intermediate pressure value");
    wait until disp_active = '0';
    is_equal(seconds_cnt, timestamp + 3, "The total display time matches the reduced display timeout");

    sync_clk(CLK1M19);

    if test_err_count > 0 then
        report "------ END OF SIMULATION: " & Integer'image(test_err_count) & "/" & Integer'image(test_total_count) & " tests failed -----";
    else
        report "------ END OF SIMULATION: " & Integer'image(test_total_count) & " tests run - ALL OK -----";
    end if;

    -- stop the clock
    test_end <= True;
    sync_clk(CLK50M, 2); -- ensure the test finishes at this point while the stimulus is being disabled
end process;

test_monitor : process(test_check)
    variable l : line;
begin
    if test_check then
        test_total_count := test_total_count + 1;
        if test_got /= test_exp then
            assert false report "[ ERR ] " & test_msg severity warning;
            write(l, now);
            write(l, string'(", the data did NOT match"));
            writeline(output, l);
            write(l, string'("Expected binary value: " & image(test_exp)));
            writeline(output, l);
            write(l, string'("  Actual binary value: " & image(test_got)));
            writeline(output, l);
            writeline(output, l);
            test_err_count := test_err_count + 1;
        else
            report "[OK] " & test_msg;
        end if;
    end if;
end process;

END architecture;
