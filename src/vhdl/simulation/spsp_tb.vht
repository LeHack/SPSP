library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library modules, utils;
    use utils.utils.all;

use std.textio.all;
use work.image_pkg.all;

ENTITY spsp_simulation_tb IS END entity;

ARCHITECTURE spsp_simulation_tb_arch OF spsp_simulation_tb IS
    -- signals
    SIGNAL CLK_50M       : STD_LOGIC := '0';
    SIGNAL KEYS          : STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
    SIGNAL DIPSW         : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL sensors_in    : t_sensors_in;
    SIGNAL sensors_out   : t_sensors_out;
    SIGNAL sensors_inout : t_sensors_inout;
    SIGNAL storage_inout : t_storage_inout;
    SIGNAL storage_out   : t_storage_out;
    SIGNAL display_out   : t_display_out;
    SIGNAL comms_in      : t_comms_in;
    SIGNAL comms_out     : t_comms_out;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : std_logic_vector(DATA_PM10P_OFFSET downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP ( HZ_DURATION => to_unsigned(30_000, 26) ) PORT MAP (
        CLOCK_50 => CLK_50M,
        DIPSW => DIPSW,
        KEYS => KEYS,

        -- Sensor IO lines
        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout,
        storage_inout => storage_inout, storage_out => storage_out, display_out => display_out,
        comms_in => comms_in, comms_out => comms_out
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
    -- signal the comms module, that we have a device connected
    comms_in.BT_CONNECTED <= '1';

    is_equal(disp_active, '1', "Display is enabled from the beginning");
    is_equal(disp_value, (0 to 15 => '1'), "Display shows dashes only at this time");
    wait until sens_ready = '1';
    -- set some readings and wait for the main module to be ready
    exp_data := prepare_sensor_data(exp_temp => 15, exp_hum => 31, exp_pm10 => 34, exp_press => 1010);
    set_reading(exp_data);
    -- check initial state right after top-level reaches READY
    is_equal(schd_out(DATA_TEMP_OFFSET downto 0), (0 to DATA_TEMP_OFFSET=> 'U'), "Scheduler output is not initialized yet");
    wait until main_state = READY; -- second, after storage

    wait until disp_enable = '1';
    is_equal(disp_enable, '1', "Display triggered on bootup to show first reading");
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
