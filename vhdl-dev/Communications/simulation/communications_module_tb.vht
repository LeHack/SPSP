library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

library drivers, modules, utils;
    use drivers.rn4020_utils.all;
    use utils.utils.all;
    use utils.fake_mem.all;


use std.textio.all;
use work.image_pkg.all;

ENTITY communications_simulation_tb IS END entity;

ARCHITECTURE comms_simulation_tb_arch OF communications_simulation_tb IS
    -- signals
    SIGNAL CLOCK_50      : STD_LOGIC := '0';
    SIGNAL KEYS          : STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
    SIGNAL comms_in      : t_comms_in;
    SIGNAL comms_out     : t_comms_out;
    SIGNAL storage_inout : t_storage_inout;
    SIGNAL storage_out   : t_storage_out;

    type comms_state_type is (
        disabled, initialize, idle, parse, respond,
        call_storage, call_storage_next_entry, call_storage_next_channel, blank_bt_channel,
        comms_running
    );
    type rn4020_state_type is (disabled, initialize, reinit, idle, busy, error);

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : std_logic_vector(159 downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP ( HZ_DURATION => to_unsigned(3_000, 26) ) PORT MAP (
        CLOCK_50 => CLOCK_50,
        KEYS => KEYS,

        -- Sensor IO lines
        comms_in => comms_in, comms_out => comms_out, storage_inout => storage_inout, storage_out => storage_out
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
    alias clocks       is << signal i1.clocks : t_clocks >>;
    alias comms_state  is << signal i1.communications_mod.state : comms_state_type >>;
    alias comms_uid    is << signal i1.communications_mod.uid : unsigned(15 downto 0) >>;
    alias strg_state   is << signal i1.storage_mod.state  : common_state_type >>;
    alias rn4020_state is << signal i1.communications_mod.rn4020_drv.state : rn4020_state_type >>;
    alias rn4020_mem   is << signal i1.communications_mod.rn4020_drv.fake_mem : bt_mem >>;
    alias rn4020_name  is << signal i1.communications_mod.rn4020_drv.device_name : String >>;

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
        constant exp  : IN std_logic_vector(159 downto 0);
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

    procedure is_equal(
        constant got  : IN String;
        constant exp  : IN String;
        constant tmsg : IN String
    ) is
        variable a, b : integer range 0 to 79 := 0;
        constant max : integer := exp'length;
    begin
        test_exp := (others => '0');
        test_got := (others => '0');
        for I in 1 to max loop
            a := (max + 1 - I) * 8 - 1;
            b := a - 7;
            test_got(a downto b) := c2v(got(I));
            test_exp(a downto b) := c2v(exp(I));
        end loop;
        trigger_test(tmsg);
    end procedure;

    procedure is_empty(
        constant got  : IN std_logic_vector;
        constant tmsg : IN String
    ) is begin
        test_exp := (others => '0');
        test_got := got;
        trigger_test(tmsg);
    end procedure;

    procedure is_comms_state(
        constant exp  : IN comms_state_type;
        constant tmsg : IN String
    ) is begin
        test_exp := (comms_state_type'pos(exp) => '1', others => '0');
        test_got := (comms_state_type'pos(comms_state) => '1', others => '0');

        trigger_test(tmsg);
    end procedure;

    procedure is_rn4020_state(
        constant exp  : IN rn4020_state_type;
        constant tmsg : IN String
    ) is begin
        test_exp := (rn4020_state_type'pos(exp) => '1', others => '0');
        test_got := (rn4020_state_type'pos(rn4020_state) => '1', others => '0');

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

    function as_lv(constant a : in unsigned) return std_logic_vector is begin
        return std_logic_vector(a);
    end function;

    function as_lv(
            constant cmd  : in String;
            constant args : in Integer
        ) return std_logic_vector is
        variable output : std_logic_vector(159 downto 0) := (others => '0');
        variable a, b : integer range 0 to 159 := 0;
    begin
        for I in 1 to cmd'length loop
            a := (21 - I) * 8 - 1;
            b := (20 - I) * 8;
            output(a downto b) := c2v(cmd(I));
        end loop;
        if args >= 0 then
            output(79 downto 16) := std_logic_vector(to_unsigned(args, 64));
        else
            output(79 downto 16) := std_logic_vector(to_signed(args, 64));
        end if;

        return output;
    end function;

    function as_lv_str(
            constant cmd  : in String;
            constant args : in String
        ) return std_logic_vector is
        variable output : std_logic_vector(159 downto 0) := (others => '0');
        variable a, b : integer range 0 to 159 := 0;
        constant arglen : integer := args'length;
    begin
        for I in 1 to cmd'length loop
            a := (21 - I) * 8 - 1;
            b := a - 7;
            output(a downto b) := c2v(cmd(I));
        end loop;
        for I in 1 to args'length loop
            a := 20 + (11 - I) * 6 - 1;
            b := a - 5;
            output(a downto b) := c2v6bit(args(I));
        end loop;

        return output;
    end function;

    variable next_uid : integer := 1;
    procedure run_call_internal(constant data : in std_logic_vector(159 downto 0)) is
        variable tmp : std_logic_vector(159 downto 0) := data;
    begin
        tmp(15 downto 0) := std_logic_vector(to_unsigned(next_uid , 16));
        next_uid := next_uid + 1;
        wait until comms_state = idle;
        comms_in.BT_RX <= '1';
        wait until rn4020_state = error;
        for I in 159 downto 0 loop
            comms_in.BT_RX <= tmp(I);
            sync_clk(CLK1M19);
        end loop;
        comms_in.BT_RX <= '0';
        wait until comms_state = respond;
        wait until comms_state = idle;
    end procedure;

    procedure run_call(
            constant cmd  : in String;
            constant args : in Integer := 0
        ) is
        variable tmp : std_logic_vector(159 downto 0) := as_lv(cmd, args);
    begin
        run_call_internal(tmp);
    end procedure;

    procedure get_stored(
            constant stamp, resolution : in Integer := 0
        ) is
        variable tmp : std_logic_vector(159 downto 0) := as_lv(
            "GETSTORED", to_integer(to_unsigned(resolution, 44) & to_unsigned(stamp, 20))
        );
    begin
        run_call_internal(tmp);
    end procedure;

    procedure run_call_str(
            constant cmd  : in String;
            constant args : in String := ""
        ) is
        variable tmp : std_logic_vector(159 downto 0) := as_lv_str(cmd, args);
    begin
        run_call_internal(tmp);
    end procedure;

    procedure check_response(
            constant cmd  : in String;
            constant args : in Integer := 0;
            constant tmsg : in String
        ) is
        variable tmp : std_logic_vector(159 downto 0) := as_lv(cmd, args);
    begin
        tmp(15 downto 0) := std_logic_vector(to_unsigned(next_uid , 16));
        next_uid := next_uid + 1;
        is_equal(rn4020_mem(9), tmp, tmsg);
    end;

    procedure check_response_str(
            constant cmd  : in String;
            constant args : in String := "";
            constant tmsg : in String
        ) is
        variable tmp : std_logic_vector(159 downto 0) := as_lv_str(cmd, args);
    begin
        tmp(15 downto 0) := std_logic_vector(to_unsigned(next_uid , 16));
        next_uid := next_uid + 1;
        is_equal(rn4020_mem(9), tmp, tmsg);
    end;

    procedure check_response_lv(
            constant cmd  : in String;
            constant args : in Std_logic_vector(63 downto 0) := (others => '0');
            constant tmsg : in String
        ) is
        variable tmp : std_logic_vector(159 downto 0) := as_lv(cmd, 0);
    begin
        tmp(79 downto 16) := args(63 downto 0);
        tmp(15 downto  0) := std_logic_vector(to_unsigned(next_uid , 16));
        next_uid := next_uid + 1;
        is_equal(rn4020_mem(9), tmp, tmsg);
    end;

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

    variable channel_data : std_logic_vector(159 downto 0) := (others => '0');
    variable record_data  : std_logic_vector( 63 downto 0) := (others => '0');
    variable tmp_i : integer := 0;
    variable err_flag : unsigned(63 downto 0) := (others => '1');
begin
    -- signal the comms module, that we have a device connected
    comms_in.BT_CONNECTED <= '1';

    is_rn4020_state(disabled, "RN4020: starts in disabled state");
    is_equal(rn4020_name, (1 to 10 => NUL), "RN4020 initial name is null");

    wait until comms_state = parse;
    is_equal(rn4020_name, "SPSP-001", "RN4020 name after init is SPSP-001");

    -- reset settings to defaults and re-fetch
    run_call("GETTMSTAMP");
    check_response("GETTMSTAMP", 42, "BT#A: GETTMSTAMP -> 42");

    -- fetch default values and update the to something else
    run_call("GETCFGPM10");
    check_response("GETCFGPM10", 50, "BT#A: GETCFGPM10 -> 50");

    run_call("SETCFGPM10", 40);
    check_response("SETCFGPM10", 40, "BT#A: SETCFGPM10 -> 40");

    run_call("GETCFGFREQ");
    check_response("GETCFGFREQ", 60, "BT#A: GETCFGFREQ -> 60");

    run_call("SETCFGFREQ", 30);
    check_response("SETCFGFREQ", 30, "BT#A: SETCFGFREQ -> 30");

    run_call("GETCFGSAMP");
    check_response("GETCFGSAMP", 10, "BT#A: GETCFGSAMP -> 10");

    run_call("SETCFGSAMP", 20);
    check_response("SETCFGSAMP", 20, "BT#A: SETCFGSAMP -> 20");

    run_call("GETDISPOFF");
    check_response("GETDISPOFF", 10, "BT#A: GETDISPOFF -> 10");

    run_call("SETDISPOFF", 15);
    check_response("SETDISPOFF", 15, "BT#A: SETDISPOFF -> 15");

    run_call("GETPRESSPT");
    check_response("GETPRESSPT", -35, "BT#A: GETPRESSPT -> -35");

    run_call("SETPRESSPT", -30);
    check_response("SETPRESSPT", -30, "BT#A: SETPRESSPT -> -30");

    run_call_str("GETBTNAME");
    check_response_str("GETBTNAME", "SPSP-001", "BT#A: GETBTNAME -> SPSP-001");

    run_call_str("SETBTNAME", "TESTNAME");
    check_response_str("SETBTNAME", "TESTNAME", "BT#A: SETBTNAME -> TESTNAME");
    is_equal(rn4020_name, "TESTNAME", "BT#A: RN4020 name after SETBTNAME is TESTNAME");

    -- verify all changed values
    run_call("GETCFGPM10");
    check_response("GETCFGPM10", 40, "BT#A: GETCFGPM10 -> 40");

    run_call("GETCFGFREQ");
    check_response("GETCFGFREQ", 30, "BT#A: GETCFGFREQ -> 30");

    run_call("GETCFGSAMP");
    check_response("GETCFGSAMP", 20, "BT#A: GETCFGSAMP -> 20");

    run_call("GETDISPOFF");
    check_response("GETDISPOFF", 15, "BT#A: GETDISPOFF -> 15");

    run_call("GETPRESSPT");
    check_response("GETPRESSPT", -30, "BT#A: GETPRESSPT -> -30");

    run_call_str("GETBTNAME");
    check_response_str("GETBTNAME", "TESTNAME", "BT#A: GETBTNAME -> TESTNAME");

    -- reset settings to defaults and re-fetch
    run_call("RESETCFG");
    check_response("RESETCFG", 0, "BT#A: RESETCFG");

    -- verify restored values
    run_call("GETCFGPM10");
    check_response("GETCFGPM10", 50, "BT#A: GETCFGPM10 -> 50");

    run_call("GETCFGFREQ");
    check_response("GETCFGFREQ", 60, "BT#A: GETCFGFREQ -> 60");

    run_call("GETCFGSAMP");
    check_response("GETCFGSAMP", 10, "BT#A: GETCFGSAMP -> 10");

    run_call("GETDISPOFF");
    check_response("GETDISPOFF", 10, "BT#A: GETDISPOFF -> 10");

    run_call("GETPRESSPT");
    check_response("GETPRESSPT", -35, "BT#A: GETPRESSPT -> -35");

    run_call_str("GETBTNAME");
    check_response_str("GETBTNAME", "SPSP-001", "BT#A: GETBTNAME -> SPSP-001");

    -- validation tests
    run_call("SETCFGPM10", 0);
    check_response("SETCFGPM10", to_integer(err_flag), "BT#A: SETCFGPM10 -> 0 [INVALID]");

    run_call("GETCFGPM10");
    check_response("GETCFGPM10", 50, "BT#A: GETCFGPM10 -> 50");

    run_call("SETCFGFREQ", 0);
    check_response("SETCFGFREQ", to_integer(err_flag), "BT#A: SETCFGFREQ -> 0 [INVALID]");

    run_call("GETCFGFREQ");
    check_response("GETCFGFREQ", 60, "BT#A: GETCFGFREQ -> 60");

    -- data fetching tests
    -- set data fetching frequency to 1s
    run_call("SETCFGFREQ", 1);
    check_response("SETCFGFREQ", 1, "BT#A: SETCFGFREQ -> 1");

    get_stored(69);
    check_response("GETSTORED", 0, "BT@69 #A: GETSTORED complete");
    -- timestamp (69) at first 5B, MSB
    channel_data(159 downto 120) := (140 => '1', 126 => '1', 122 => '1', 120 => '1', others => '0');
    is_equal(rn4020_mem(1), channel_data, "BT@69 #1: Only timestamp, since there is no data at the given timestamp");
    for I in 2 to 8 loop
        is_empty(rn4020_mem(I), "BT@69 #" & Integer'image(I) &": empty");
    end loop;

    -- last 5 records
    get_stored(64);
    check_response("GETSTORED", 5, "BT@64 #A: GETSTORED complete");
    -- set timestamp (64) at first 5B and zero the rest
    channel_data(159 downto   0) := (140 => '1', 126 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data(64);
    channel_data( 79 downto  40) := get_fake_data(65);
    channel_data( 39 downto   0) := get_fake_data(66);
    is_equal(rn4020_mem(1), channel_data, "BT@64 #1: Timestamp + 3 readings");
    channel_data(159 downto   0) := (others => '0');
    channel_data(159 downto 120) := get_fake_data(67);
    channel_data(119 downto  80) := get_fake_data(68);
    is_equal(rn4020_mem(2), channel_data, "BT@64 #2: 2 more readings (data ends @68)");
    for I in 3 to 8 loop
        is_empty(rn4020_mem(I), "BT@64 #" & Integer'image(I) &": empty");
    end loop;

    -- last 31 records
    get_stored(38);
    check_response("GETSTORED", 31, "BT@38 #A: GETSTORED complete");

    channel_data(159 downto   0) := (140 => '1', 125 => '1', 122 => '1', 121 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data(38);
    channel_data( 79 downto  40) := get_fake_data(39);
    channel_data( 39 downto   0) := get_fake_data(40);
    is_equal(rn4020_mem(1), channel_data, "BT@38 #1: Timestamp + 3 readings");
    for I in 2 to 8 loop
        tmp_i := (I - 2) * 4;
        channel_data(159 downto   0) := (others => '0');
        channel_data(159 downto 120) := get_fake_data(41 + tmp_i);
        channel_data(119 downto  80) := get_fake_data(42 + tmp_i);
        channel_data( 79 downto  40) := get_fake_data(43 + tmp_i);
        channel_data( 39 downto   0) := get_fake_data(44 + tmp_i);
        is_equal(rn4020_mem(I), channel_data, "BT@38 #" & Integer'image(I) &": 4 readings");
    end loop;

    -- first 31 records
    get_stored(0);
    check_response("GETSTORED", 31, "BT@0 #A: GETSTORED complete");

    --the initial timestamp is 0
    channel_data(159 downto   0) := (140 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data(0);
    channel_data( 79 downto  40) := get_fake_data(1);
    channel_data( 39 downto   0) := get_fake_data(2);
    is_equal(rn4020_mem(1), channel_data, "BT@0 #1: Timestamp + 3 readings");
    for I in 2 to 8 loop
        tmp_i := (I - 2) * 4;
        channel_data(159 downto   0) := (others => '0');
        channel_data(159 downto 120) := get_fake_data(3 + tmp_i);
        channel_data(119 downto  80) := get_fake_data(4 + tmp_i);
        channel_data( 79 downto  40) := get_fake_data(5 + tmp_i);
        channel_data( 39 downto   0) := get_fake_data(6 + tmp_i);
        is_equal(rn4020_mem(I), channel_data, "BT@0 #" & Integer'image(I) &": 4 readings");
    end loop;

    -- use custom resolution
    get_stored(0, 10);
    check_response("GETSTORED", 7, "BT@0 #A: GETSTORED with custom resolution = 10");

    --the initial timestamp is again 0
    channel_data(159 downto 120) := (143 | 141 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data(0);
    channel_data( 79 downto  40) := get_fake_data(10);
    channel_data( 39 downto   0) := get_fake_data(20);
    is_equal(rn4020_mem(1), channel_data, "BT@0 #1: Timestamp + 3 readings");

    channel_data(159 downto 120) := get_fake_data(30);
    channel_data(119 downto  80) := get_fake_data(40);
    channel_data( 79 downto  40) := get_fake_data(50);
    channel_data( 39 downto   0) := get_fake_data(60);
    is_equal(rn4020_mem(2), channel_data, "BT@0 #2: 4 readings");

    for I in 3 to 8 loop
        is_empty(rn4020_mem(I), "BT@0 #" & Integer'image(I) &": empty");
    end loop;

    -- set data fetching (and reading) frequency to 20s
    run_call("SETCFGFREQ", 20);
    check_response("SETCFGFREQ", 20, "BT#A: SETCFGFREQ -> 20");

    -- now it will return only every 20th record (since fake data has 1s resolution)
    get_stored(0);
    check_response("GETSTORED", 4, "BT@0 #A: GETSTORED complete");

    -- again the initial timestamp is 0
    channel_data(159 downto   0) := (144 | 142 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data( 0);
    channel_data( 79 downto  40) := get_fake_data(20);
    channel_data( 39 downto   0) := get_fake_data(40);
    is_equal(rn4020_mem(1), channel_data, "BT@0 #1: Timestamp + 3 readings");
    channel_data(159 downto   0) := (others => '0');
    channel_data(159 downto 120) := get_fake_data(60);
    is_equal(rn4020_mem(2), channel_data, "BT@0 #2: 1 more reading");
    for I in 3 to 8 loop
        is_empty(rn4020_mem(I), "BT@0 #" & Integer'image(I) &": empty");
    end loop;

    -- additional case to handle:
    -- when data writes overlap the memory, the writes begin from address 0 again
    -- hence we run a risk of fetching new and very old data in one run
    KEYS(0) <= '0';
    wait until strg_state = busy;
    KEYS(0) <= '1';
    wait until strg_state = idle;

    -- set data fetching (and reading) frequency to 2s
    run_call("SETCFGFREQ", 2);
    check_response("SETCFGFREQ", 2, "BT#A: SETCFGFREQ -> 2");

    -- start reading from the beginning
    get_stored(0);
    check_response("GETSTORED", 2, "BT@0 #A: GETSTORED complete");

    -- we should see only 2 records, because the rest is past the point of last-write, meaning it's old data
    -- if the user wants to access it, he needs to start reading from that point onward
    -- again the initial timestamp is 0
    channel_data(159 downto   0) := (141 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data(0);
    channel_data( 79 downto  40) := i2v(46, 6) & i2v(42, 7) & i2v(42, 7) & i2v(42,  9) & i2v(42,  11);
    is_equal(rn4020_mem(1), channel_data, "BT@0 #1: Timestamp + 2 readings, second record is special");
    for I in 2 to 8 loop
        is_empty(rn4020_mem(I), "BT@0 #" & Integer'image(I) &": empty");
    end loop;

    -- old data (past the last-write)
    get_stored(4);
    check_response("GETSTORED", 31, "BT@4 #A: GETSTORED complete");
    channel_data(159 downto   0) := (141 => '1', 122 => '1', others => '0');
    channel_data(119 downto  80) := get_fake_data(4);
    channel_data( 79 downto  40) := get_fake_data(6);
    channel_data( 39 downto   0) := get_fake_data(8);
    is_equal(rn4020_mem(1), channel_data, "BT@4 #1: Timestamp + 3 readings");

    tmp_i := 8;
    for I in 2 to 8 loop
        channel_data(159 downto 120) := get_fake_data(tmp_i + 2);
        channel_data(119 downto  80) := get_fake_data(tmp_i + 4);
        channel_data( 79 downto  40) := get_fake_data(tmp_i + 6);
        channel_data( 39 downto   0) := get_fake_data(tmp_i + 8);
        is_equal(rn4020_mem(I), channel_data, "BT@4 #" & Integer'image(I) &": 4 readings");
        tmp_i := tmp_i + 8;
    end loop;

    -- fetch latest data
    run_call("GETREADING");
    record_data(63 DOWNTO 20) := (
        63 downto 61 => '1', 59 downto 58 => '1', -- checksum: 59
        55 => '1',           -- 16C
        48 downto 47 => '1', -- H24%
        40 downto 39 => '1', -- 48ug/m3
        33 downto 28 => '1', -- 1008hPa
        others => '0'
    );
    record_data(19 DOWNTO  0) := std_logic_vector(to_unsigned(80, 20));
    check_response_lv("GETREADING", record_data, "BT #A: GETREADING complete");

    -- confirm that after the above uid is some high value
    is_equal(std_logic_vector(comms_uid), i2v(84, 160), "BT UID: Check expected value");

    -- now check what happens when the device reconnects
    comms_in.BT_CONNECTED <= '0';
    sync_clk(CLK0HZ1, 3);
    is_equal(std_logic_vector(comms_uid), i2v(0, 160), "BT UID: auto-reset after the device disconnects");
    comms_in.BT_CONNECTED <= '1';
    sync_clk(CLK0HZ1, 4);
    is_equal(std_logic_vector(comms_uid), i2v(0, 160), "BT UID: auto-reset after parsing the command channel");

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
