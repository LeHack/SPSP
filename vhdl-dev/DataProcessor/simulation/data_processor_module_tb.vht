library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library modules, utils;
    use utils.utils.all;

use std.textio.all;
use work.image_pkg.all;

ENTITY dataproc_simulation_tb IS END entity;

ARCHITECTURE dataproc_simulation_tb_arch OF dataproc_simulation_tb IS
    -- signals
    SIGNAL CLK_50M       : STD_LOGIC := '0';
    SIGNAL sample_size   : STD_LOGIC_VECTOR(5 downto 0) := i2v(10, 6);
    SIGNAL sensors_in    : t_sensors_in;
    SIGNAL sensors_out   : t_sensors_out;
    SIGNAL sensors_inout : t_sensors_inout;
    SIGNAL storage_inout : t_storage_inout;
    SIGNAL storage_out   : t_storage_out;
    SIGNAL display_out   : t_display_out;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : std_logic_vector(33 downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP ( HZ_DURATION => to_unsigned(1000, 26) ) PORT MAP (
        CLOCK_50 => CLK_50M,
        read_freq_setting => i2v(3, 6),
        sample_size => sample_size,

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
    alias sens_ready    is << signal i1.scheduler_mod.sens_ready : std_logic >>;
    alias dproc_ready   is << signal i1.dproc_ready : std_logic >>;
    alias process_out   is << signal i1.dproc_measurement_out : std_logic_vector(DATA_TEMP_OFFSET + 10 downto 0) >>;
    alias checksum_out  is << signal i1.processor_mod.checksum : std_logic_vector(CHECKSUM_LEN - 1  DOWNTO 0) >>;

    alias pm10std is process_out(DATA_TEMP_OFFSET + 10 downto DATA_TEMP_OFFSET  + 1);
    alias temp    is process_out(DATA_TEMP_OFFSET      downto DATA_HUM_OFFSET   + 1);
    alias hum     is process_out(DATA_HUM_OFFSET       downto DATA_PM10_OFFSET  + 1);
    alias pm10    is process_out(DATA_PM10_OFFSET      downto DATA_PRESS_OFFSET + 1);
    alias press   is process_out(DATA_PRESS_OFFSET     downto 0);

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

    type clk_type is (CLK50M, CLK1M19, CLK0M5);
    procedure sync_clk (constant clk : in clk_type := CLK50M; constant c_loop : in integer := 1) is
        variable i : integer := 0;
    begin
        sync_loop: while i < c_loop loop
            case clk is
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

    procedure process_data(constant exp_temp, exp_hum, exp_pm10, exp_press : in integer range 0 to 2048) is
        variable data : unsigned(DATA_TEMP_OFFSET downto 0) := (others => '0');
    begin
        -- map input to data structure
        data(DATA_TEMP_OFFSET  downto DATA_TEMP_OFFSET  + 1 - DATA_TEMP_LEN)  := to_unsigned(exp_temp,  DATA_TEMP_LEN);
        data(DATA_HUM_OFFSET   downto DATA_HUM_OFFSET   + 1 - DATA_HUM_LEN)   := to_unsigned(exp_hum,   DATA_HUM_LEN);
        data(DATA_PM10_OFFSET  downto DATA_PM10_OFFSET  + 1 - DATA_PM10_LEN)  := to_unsigned(exp_pm10,  DATA_PM10_LEN);
        data(DATA_PRESS_OFFSET downto DATA_PRESS_OFFSET + 1 - DATA_PRESS_LEN) := to_unsigned(exp_press, DATA_PRESS_LEN);

        wait until sens_ready = '0';
        sensors_in.ADC_SDAT <= '1';
        sync_clk(CLK1M19);
        for I in DATA_TEMP_OFFSET downto 0 loop
            sensors_in.ADC_SDAT <= data(I);
            sync_clk(CLK1M19);
        end loop;
        sensors_in.ADC_SDAT <= '0';
    end procedure;

    procedure check_result(constant exp_temp, exp_hum, exp_pm10, exp_pm10std, exp_press : in integer range 0 to 2048; constant msg : in string) is
        variable chksum : integer := 0;
    begin
        wait until dproc_ready = '0';
        wait until dproc_ready = '1';
        is_equal(temp,    i2v(exp_temp,  DATA_TEMP_OFFSET - DATA_HUM_OFFSET),    msg & " - temperature");
        is_equal(hum,     i2v(exp_hum,   DATA_HUM_OFFSET  - DATA_PM10_OFFSET),   msg & " - humidity");
        is_equal(press,   i2v(exp_press, DATA_PRESS_OFFSET + 1),                 msg & " - pressure");
        is_equal(pm10,    i2v(exp_pm10,  DATA_PM10_OFFSET - DATA_PRESS_OFFSET),  msg & " - PM10");
        is_equal(pm10std, i2v(exp_pm10std, 10),                                  msg & " - % PM10");
        chksum := (42 + exp_temp + exp_hum + exp_press + exp_pm10) mod 61;
        is_equal(checksum_out, i2v(chksum, CHECKSUM_LEN),                        msg & " - checksum");
    end procedure;
begin
    wait until main_state = READY;

    process_data(exp_temp => 15, exp_hum => 31, exp_pm10 => 34, exp_press => 1010);
    check_result(
        exp_temp => 15, exp_hum => 31, exp_pm10 => 34, exp_pm10std => 68, exp_press => 1010,
        msg => "Check first iteration (copy)"
    );

    process_data(exp_temp => 20, exp_hum => 40, exp_pm10 => 50, exp_press => 1015);
    check_result(
        exp_temp => 16, exp_hum => 32, exp_pm10 => 36, exp_pm10std => 71, exp_press => 1011,
        msg => "#1 processing after increase"
    );
    check_result(
        exp_temp => 17, exp_hum => 33, exp_pm10 => 37, exp_pm10std => 74, exp_press => 1012,
        msg => "#2 processing after increase"
    );
    check_result(
        exp_temp => 17, exp_hum => 34, exp_pm10 => 38, exp_pm10std => 77, exp_press => 1012,
        msg => "#3 processing after increase"
    );
    check_result(
        exp_temp => 18, exp_hum => 35, exp_pm10 => 39, exp_pm10std => 79, exp_press => 1013,
        msg => "#4 processing after increase"
    );
    check_result(
        exp_temp => 19, exp_hum => 36, exp_pm10 => 41, exp_pm10std => 81, exp_press => 1014,
        msg => "#5 processing after increase"
    );
    -- now wait some more for it to stabilize (mainly humidity and pm10)
    for I in 1 to 11 loop
        wait until dproc_ready = '0';
        wait until dproc_ready = '1';
    end loop;
    check_result(
        exp_temp => 20, exp_hum => 40, exp_pm10 => 50, exp_pm10std => 100, exp_press => 1015,
        msg => "After stabilizing"
    );

    -- now decrease
    process_data(exp_temp => 10, exp_hum => 25, exp_pm10 => 20, exp_press => 1005);
    check_result(
        exp_temp => 19, exp_hum => 39, exp_pm10 => 47, exp_pm10std => 94, exp_press => 1014,
        msg => "processing right after decrease"
    );
    -- now wait for it to stabilize
    for I in 1 to 21 loop
        wait until dproc_ready = '0';
        wait until dproc_ready = '1';
    end loop;
    check_result(
        exp_temp => 10, exp_hum => 25, exp_pm10 => 20, exp_pm10std => 41, exp_press => 1005,
        msg => "After stabilizing again"
    );

    -- now disable sampling
    sample_size <= i2v(1, 6);
    process_data(exp_temp => 30, exp_hum => 50, exp_pm10 => 100, exp_press => 1025);
    check_result(
        exp_temp => 30, exp_hum => 50, exp_pm10 => 100, exp_pm10std => 200, exp_press => 1025,
        msg => "Sampling disabled"
    );

    -- and use a very high sampling setting
    sample_size <= i2v(60, 6);
    check_result(
        exp_temp => 30, exp_hum => 50, exp_pm10 => 100, exp_pm10std => 200, exp_press => 1025,
        msg => "Samplig re-enabled to a large value"
    );

    -- introduce another change
    process_data(exp_temp => 50, exp_hum => 60, exp_pm10 => 150, exp_press => 1030);
    check_result(
        exp_temp => 31, exp_hum => 51, exp_pm10 => 101, exp_pm10std => 203, exp_press => 1026,
        msg => "#1 sampling set very high"
    );
    check_result(
        exp_temp => 31, exp_hum => 51, exp_pm10 => 102, exp_pm10std => 204, exp_press => 1026,
        msg => "#2 sampling set very high"
    );
    -- now wait for it to stabilize
    for I in 1 to 65 loop
        wait until dproc_ready = '0';
        wait until dproc_ready = '1';
    end loop;
    check_result(
        exp_temp => 50, exp_hum => 60, exp_pm10 => 150, exp_pm10std => 299, exp_press => 1030,
        msg => "After 65 iterations"
    );

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
