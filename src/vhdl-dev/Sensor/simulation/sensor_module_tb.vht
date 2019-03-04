library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library modules, utils;
    use utils.utils.all;

use std.textio.all;
use work.image_pkg.all;

ENTITY sensor_simulation_tb IS END entity;

ARCHITECTURE sensor_simulation_tb_arch OF sensor_simulation_tb IS
    -- signals
    SIGNAL CLOCK_50      : STD_LOGIC := '0';
    SIGNAL sensors_in    : t_sensors_in;
    SIGNAL sensors_out   : t_sensors_out;
    SIGNAL sensors_inout : t_sensors_inout;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : std_logic_vector(19 downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP (HZ_DURATION => to_unsigned(500, 26)) PORT MAP (
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
    alias clocks     is << signal i1.clocks : t_clocks >>;
    alias sens_state is << signal i1.sensor_mod.state : common_state_type >>;
    alias sens_enable is << signal i1.sens_enable : std_logic >>;
    alias sens_temp  is << signal i1.sens_temp  : std_logic_vector( 6 downto 0) >>;
    alias sens_hum   is << signal i1.sens_hum   : std_logic_vector( 6 downto 0) >>;
    alias sens_press is << signal i1.sens_press : std_logic_vector(10 downto 0) >>;
    alias sens_pm10  is << signal i1.sens_pm10  : std_logic_vector( 8 downto 0) >>;

    -- Consider moving this to a separate framework lib
    procedure trigger_test(constant tmsg : IN String) is begin
        test_msg := (others => NUL);
        for I in 1 to tmsg'HIGH loop
            test_msg(I) := tmsg(I);
        end loop;

        test_check <= true;
        wait for 1 ps;
        test_check <= false;
        wait for 1 ps;
    end procedure;

    procedure is_equal(
        constant got  : IN std_logic_vector;
        constant exp  : IN std_logic_vector(19 downto 0);
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

    procedure is_equal(
        constant got  : IN std_logic;
        constant exp  : IN std_logic;
        constant tmsg : IN String
    ) is begin
        test_exp := (0 => exp, others => '0');
        test_got := (0 => got, others => '0');
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

    procedure finish_test is begin
        if test_err_count > 0 then
            report "------ END OF SIMULATION: " & Integer'image(test_err_count) & "/" & Integer'image(test_total_count) & " tests failed -----";
        else
            report "------ END OF SIMULATION: " & Integer'image(test_total_count) & " tests run - ALL OK -----";
        end if;

        -- stop the clock
        test_end <= True;
        sync_clk(CLK50M); -- ensure the test finishes at this point while the stimulus is being disabled
    end procedure;

    variable empty : std_logic_vector(19 downto 0) := (others => '0');
begin
    sync_clk(CLK50M); -- wait for 50MHz clock rising edge

    -- Check initial values
    is_equal(sens_temp,  empty, "check initial temperature");
    is_equal(sens_hum,   empty, "check initial humidity");
    is_equal(sens_press, empty, "check initial pressure");
    is_equal(sens_pm10,  empty, "check initial pm10");
    is_state(initialize, "check initial state (initialize)");

    sync_clk(CLK1M19, 3);
    sync_clk(CLK50M);
    is_state(idle, "check state after init iterations");
    sync_clk(CLK0HZ1, 2);
    is_equal(sens_enable, '1', "check run signal high");

    sync_clk(CLK1M19, 2);
    is_state(busy, "check state after busy stage");
    sync_clk(CLK0HZ1);
    is_equal(sens_enable, '0', "check run signal low");

    -- wait for all driver mockups to setup data
    sync_clk(CLK1M19, 65);  -- 2^6 + 1 for the state propagation
    sync_clk(CLK50M);
    is_state(idle, "check state after collecting data");
    is_equal(sens_temp,  (3 downto 0 => '1', others => '0'),     "check output temperature");
    is_equal(sens_hum,   (4 downto 1 => '1', others => '0'),     "check output humidity");
    is_equal(sens_press, (9 downto 4 | 1 => '1', others => '0'), "check output pressure");
    is_equal(sens_pm10,  (5 | 1 downto 0 => '1', others => '0'), "check output pm10 reading");

    sync_clk(CLK0HZ1, 8); -- Test delay between sensor runs + state propagation
    is_equal(sens_enable, '1', "check run signal high");
    sync_clk(CLK0HZ1);
    is_state(busy, "check state change during second run stage");

    finish_test;
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
