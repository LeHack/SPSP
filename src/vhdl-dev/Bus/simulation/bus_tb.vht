library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library utils;
    use utils.utils.all;

use std.textio.all;
use work.image_pkg.all;

ENTITY bus_simulation_tb IS END entity;

ARCHITECTURE bus_simulation_tb_arch OF bus_simulation_tb IS
    type scheduler_state_type is (idle, gather_data, set_checksum);
    -- signals
    SIGNAL CLOCK_50   : STD_LOGIC := '0';
    SIGNAL storage_inout : t_storage_inout;
    SIGNAL storage_out   : t_storage_out;
    SIGNAL sensors_in    : t_sensors_in;
    SIGNAL sensors_out   : t_sensors_out;
    SIGNAL sensors_inout : t_sensors_inout;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : STD_LOGIC_VECTOR(19 downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 50) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP (HZ_DURATION => to_unsigned(500, 26)) PORT MAP (
        CLOCK_50 => CLOCK_50,

        sensors_in => sensors_in, sensors_out => sensors_out, sensors_inout => sensors_inout,
        storage_inout => storage_inout, storage_out => storage_out
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
    -- access the virtual clock and main states
    alias clocks is << signal i1.clocks : t_clocks >>;
    -- signals to check
    alias schd_ready is << signal i1.scheduler_mod.ready : std_logic >>;
    alias strg_ready is << signal i1.storage_mod.ready : std_logic >>;
    alias strg_stamp is << signal i1.storage_mod.timestamp : std_logic_vector(19 DOWNTO 0) >>;
    alias strg_mem   is << signal i1.storage_mod.fake_mem  : std_logic_vector(47 DOWNTO 0) >>;
    alias strg_rw    is << signal i1.storage_mod.rw  : std_logic >>;
    alias strg_type  is << signal i1.storage_mod.data_type  : storage_data_type >>;

    -- store temporary address as unsigned
    variable tmp_mem : std_logic_vector(19 downto 0) := (others => '0');

    procedure sync_clk (constant c_loop : integer) is
        variable i : integer := 0;
    begin
        loop1: while i <= c_loop loop
            wait until rising_edge(clocks.CLK_1M19);
            i := i + 1;
        end loop;
    end procedure;

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

    procedure is_data_type(
        constant exp  : IN storage_data_type;
        constant tmsg : IN String
    ) is begin
        test_exp := (storage_data_type'pos(exp) => '1', others => '0');
        test_got := (storage_data_type'pos(strg_type) => '1', others => '0');

        trigger_test(tmsg);
    end procedure;

    procedure finish_test is begin
        if test_err_count > 0 then
            report "------ END OF SIMULATION: " & Integer'image(test_err_count) & "/" & Integer'image(test_total_count) & " tests failed -----";
        else
            report "------ END OF SIMULATION: " & Integer'image(test_total_count) & " tests run - ALL OK -----";
        end if;

        -- stop the clock
        test_end <= True;
        sync_clk(0); -- ensure the test finishes at this point while the stimulus is being disabled
    end procedure;
begin
    -- wait for the first measurement to come in and start being stored
    wait until schd_ready = '1' and strg_ready = '0';

    is_equal(strg_stamp, i2v(1, 20), "store_data: check stamp on first record");
    is_equal(strg_rw, '1', "store_data: check rw flag");
    is_data_type(data_record, "store_data: check selected data type");

    wait until strg_ready = '1';

    is_equal(strg_mem(19 downto 0), (0 => '1', 11 => '1', others => '0'), "store_data: check fake mem 1");
    tmp_mem := strg_mem(39 downto 20);
    is_equal(tmp_mem, (0 => '1', 7 => '1', others => '0'), "store_data: check fake mem 2");

    wait until schd_ready = '0';
    wait until schd_ready = '1' and strg_ready = '0';

    is_equal(strg_stamp, i2v(5, 20), "store_data: check stamp on second record");

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
