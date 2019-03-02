library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library modules, utils;
    use utils.utils.all;

use std.textio.all;
use work.image_pkg.all;

ENTITY scheduler_simulation_tb IS END entity;

ARCHITECTURE scheduler_simulation_tb_arch OF scheduler_simulation_tb IS
    -- signals
    SIGNAL CLOCK_50   : STD_LOGIC := '0';
    SIGNAL sensors_in    : t_sensors_in;
    SIGNAL sensors_out   : t_sensors_out;
    SIGNAL sensors_inout : t_sensors_inout;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : std_logic_vector(39 downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP ( HZ_DURATION => to_unsigned(500, 26) ) PORT MAP (
        CLOCK_50 => CLOCK_50,

        -- Sensor IO lines
        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout
    );

-- drive the 50MHz clock
CLK_GEN: process begin
	if not test_end then
		CLOCK_50 <= '0';
		wait for 20 ns;
        CLOCK_50 <= '1';
		wait for 20 ns;
	else
		wait;
	end if;
end process;

stimulus : process
    -- i1 signal access
    alias clocks        is << signal i1.clocks : t_clocks >>;
    -- internal scheduler
    alias schd_ready    is << signal i1.scheduler_mod.ready : std_logic >>;
    alias schd_trigger  is << signal i1.scheduler_mod.trigger : unsigned(9 downto 0) >>;
    alias schd_trigger_run is << signal i1.scheduler_mod.trigger_run : std_logic >>;
    -- internal sensor
    alias sens_state    is << signal i1.scheduler_mod.sensor_mod.state : common_state_type >>;
    -- external scheduler
    alias schd_measurement_out  is << signal i1.schd_measurement_out : std_logic_vector(39 DOWNTO 0) >>;

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
        constant exp  : IN std_logic_vector(39 downto 0);
        constant tmsg : IN String
    ) is begin
        test_exp := exp;
        if test_got'length > got'length then
            test_got := (others => '0');
            test_got(got'length-1 downto 0) := got;
        else
            test_got := got;
        end if;

        trigger_test(tmsg);
    end procedure;

    procedure is_state(
        constant exp  : IN common_state_type;
        constant tmsg : IN String
    ) is begin
        test_exp := (common_state_type'pos(exp) => '1', others => '0');
        test_got := (common_state_type'pos(sens_state) => '1', others => '0');

        trigger_test(tmsg);
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

    variable empty : std_logic_vector(39 downto 0) := (others => '0');
begin
    wait for 1 ns;
    is_equal(as_lv(schd_trigger), (others => '0'), "scheduler: check initial trigger condition");
    is_equal(schd_ready, '0', "scheduler: check initial state (waiting for first read)");
    is_equal(schd_trigger_run, '0', "scheduler: internal trigger disabled");
    is_state(initialize, "sensor: check initial state (initialize)");

    sync_clk(CLK1M19, 20);
    is_state(idle, "sensor: check state update");
    is_equal(schd_ready, '0', "scheduler: still waiting for the pressure reference value");

    sync_clk(CLK1M19, 6);
    is_state(busy, "sensor: check reaction to trigger (ready -> busy)");

    wait until schd_ready = '1';
    is_equal(
        schd_measurement_out(39 downto 0),
        i2v(5, 6) & i2v(47, 7) & i2v(30, 7) & i2v(35, 9) & i2v(1010, 11),
        "scheduler: check output data + checksum"
    );
    is_state(idle, "sensor: went idle");

    -- wait "1.4 seconds"
    sync_clk(CLK0HZ1, 14);
    is_equal(schd_ready, '1', "scheduler: keeps idle state until trigger fires");
    is_equal(as_lv(schd_trigger), i2v(1, 40), "scheduler: check trigger value (T:-0.1)");
    wait until schd_trigger = 0;

    sync_clk(CLK1M19, 2);
    is_equal(schd_ready, '0', "scheduler: another run has started");
    -- and confirm the trigger is reset
    is_equal(as_lv(schd_trigger), i2v(29, 40), "scheduler: check updated trigger value (T:-3)");

    sync_clk(CLK1M19, 2); -- wait 2 ticks
    is_state(busy, "sensor: check reaction to trigger (ready -> busy)");

    -- now wait for the whole iteration to finish
    wait until schd_ready = '1';

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
