library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

use std.textio.all;
use work.image_pkg.all;
library utils;
    use utils.utils.all;

ENTITY storage_simulation_tb IS END entity;

ARCHITECTURE storage_simulation_tb_arch OF storage_simulation_tb IS
    -- signals
    SIGNAL CLOCK_50   : STD_LOGIC := '0';
    SIGNAL KEY        : STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
    SIGNAL DIPSW      : STD_LOGIC_VECTOR(3 downto 0) := (others => '1');
    SIGNAL EXT_VALUE  : STD_LOGIC_VECTOR(3 downto 0) := (others => 'U');

    -- Component connections
    SIGNAL display_out   : t_display_out;
    SIGNAL storage_inout : t_storage_inout;
    SIGNAL storage_out   : t_storage_out;

    SIGNAL test_check, test_end : boolean := false;
    SHARED VARIABLE test_got, test_exp : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    SHARED VARIABLE test_msg : String(1 to 80) := (others => NUL);
    SHARED VARIABLE test_total_count, test_err_count : Integer := 0;
BEGIN
	i1 : entity work.Main GENERIC MAP (HZ_DURATION => to_unsigned(300, 26)) PORT MAP (
        CLOCK_50 => CLOCK_50,
        KEY => KEY,
        DIPSW => DIPSW,
        EXT_VALUE => EXT_VALUE,

        display_out => display_out,
        storage_inout => storage_inout,
        storage_out => storage_out
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
    -- access the virtual clock and main state
    alias clocks        is << signal i1.clocks : t_clocks >>;
    alias main_state    is << signal i1.state  : mem_status_type >>;
    -- signals to check
    alias disp_val      is << signal i1.display.dvalue : UNSIGNED(15 downto 0) >>;
    alias disp_dot      is << signal i1.display.dpoint : UNSIGNED( 3 downto 0) >>;
    alias strg_state    is << signal i1.storage_drv.state    : common_state_type >>;
    alias strg_out      is << signal i1.storage_drv.data_out : STD_LOGIC_VECTOR(59 DOWNTO 0) >>;
    alias strg_overflow is << signal i1.storage_drv.overflow : STD_LOGIC >>;
    alias strg_err      is << signal i1.storage_drv.error    : STD_LOGIC >>;
    alias eeprom_in     is << signal i1.storage_drv.eeprom.data_in : STD_LOGIC_VECTOR( 7 DOWNTO 0) >>;
    alias eeprom_ready  is << signal i1.storage_drv.eeprom.ready   : STD_LOGIC >>;
    alias sdram_in      is << signal i1.storage_drv.sdram.data_in  : STD_LOGIC_VECTOR(15 DOWNTO 0) >>;
    alias sdram_out     is << signal i1.storage_drv.sdram.data_out : STD_LOGIC_VECTOR(15 DOWNTO 0) >>;
    alias sdram_addr    is << signal i1.storage_drv.sdram.addr     : STD_LOGIC_VECTOR(23 DOWNTO 0) >>;
    alias sdram_ready   is << signal i1.storage_drv.sdram.ready    : STD_LOGIC >>;

    -- store temporary address as unsigned
    variable addr : unsigned(3 downto 0) := (others => '1');

    procedure set_address(constant new_addr : integer) is begin
        addr := to_unsigned(new_addr, 4);
        KEY <= (others => '1');
        DIPSW <= std_logic_vector(addr);
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
        constant exp  : IN std_logic_vector(15 downto 0);
        constant tmsg : IN String
    ) is begin
        if got'length < test_got'length then
            -- for smaller got, pad with 0's
            test_got := (others => '0');
            test_got(got'length-1 downto 0) := got;
        else
            -- for everything else, use the first 16 bytes
            test_got := got(15 downto 0);
        end if;
        test_exp := exp;
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

    -- borrowed from my bluetooth uart module
    function u2hex(constant v: in unsigned(3 downto 0)) return Character is
        variable tmp : integer range 0 to 70;
    begin
        tmp := to_integer(v) + 48;
        if tmp > 57 then
            tmp := tmp + 7;
        end if;
        return character'val(tmp);
    end function;

    type test_case_type is (avg_sample_size, read_freq, pm10norm, btname, display_time, press_ref, data);
    type test_case_rw is (read_test, write_test, reread_test, overflow_test);
    procedure check_test_case(constant test_case : IN test_case_type; constant test_type : IN test_case_rw) is
        variable tmp_val : std_logic_vector(15 downto 0) := (others => '0');
    begin
        test_exp := (others => '0');
        test_got := (others => '0');

        wait until strg_state = busy;
        -- for data we have more to check
        if test_case /= data and test_case /= btname then
            wait until main_state = idle;
        end if;

        case test_case is
            when avg_sample_size =>
                case test_type is
                    when read_test => 
                        -- first see what comes out of the storage (the initial value from eeprom)
                        is_equal(strg_out, x"000A", "read: strg_out @ avg_sample_size");
                        -- next see if the display is updated correctly
                        is_equal(as_lv(disp_val), x"F00A", "read: disp_val @ avg_sample_size");
                    when write_test => 
                        -- the display is updated with the key
                        is_equal(as_lv(disp_val), x"F00B", "write: disp_val @ avg_sample_size");
                        -- also check what eeprom got
                        is_equal(eeprom_in, x"000B", "write: eeprom_in @ avg_sample_size");
                    when reread_test => 
                        -- now reread the data from the memory
                        is_equal(strg_out, x"000B", "reread: strg_out @ avg_sample_size");
                        -- and recheck the display
                        is_equal(as_lv(disp_val), x"F00B", "reread: disp_val @ avg_sample_size");
                    when others => NULL;
                end case;
            when read_freq =>
                case test_type is
                    when read_test => 
                        is_equal(strg_out, x"003C", "read: strg_out @ read_freq");
                        is_equal(as_lv(disp_val), x"E03C", "read: disp_val @ read_freq");
                    when write_test => 
                        is_equal(as_lv(disp_val), x"E03D", "write: disp_val @ read_freq");
                        is_equal(eeprom_in, x"003D", "write: eeprom_in @ read_freq");
                    when reread_test => 
                        is_equal(strg_out, x"003D", "reread: strg_out @ read_freq");
                        is_equal(as_lv(disp_val), x"E03D", "reread: disp_val @ read_freq");
                    when others => NULL;
                end case;
            when pm10norm =>
                case test_type is
                    when read_test => 
                        is_equal(strg_out, x"0032", "read: strg_out @ pm10norm");
                        is_equal(as_lv(disp_val), x"D032", "read: disp_val @ pm10norm");
                    when write_test => 
                        is_equal(as_lv(disp_val), x"D033", "write: disp_val @ pm10norm");
                        is_equal(eeprom_in, x"0033", "write: eeprom_in @ pm10norm");
                    when reread_test => 
                        is_equal(strg_out, x"0033", "reread: strg_out @ pm10norm");
                        is_equal(as_lv(disp_val), x"D033", "reread: disp_val @ pm10norm");
                    when others => NULL;
                end case;
            when display_time =>
                case test_type is
                    when read_test =>
                        is_equal(strg_out, x"000A", "read: strg_out @ display_time");
                        is_equal(as_lv(disp_val), x"B00A", "read: disp_val @ display_time");
                    when write_test =>
                        is_equal(as_lv(disp_val), x"B00B", "write: disp_val @ display_time");
                        is_equal(eeprom_in, x"000B", "write: eeprom_in @ display_time");
                    when reread_test =>
                        is_equal(strg_out, x"000B", "reread: strg_out @ display_time");
                        is_equal(as_lv(disp_val), x"B00B", "reread: disp_val @ display_time");
                    when others => NULL;
                end case;
            when press_ref =>
                case test_type is
                    when read_test =>
                        is_equal(strg_out, x"00DD", "read: strg_out @ press_ref");
                        is_equal(as_lv(disp_val), x"A0DD", "read: disp_val @ press_ref");
                    when write_test =>
                        is_equal(as_lv(disp_val), x"A0DE", "write: disp_val @ press_ref");
                        is_equal(eeprom_in, x"00DE", "write: eeprom_in @ press_ref");
                    when reread_test =>
                        is_equal(strg_out, x"00DE", "reread: strg_out @ press_ref");
                        is_equal(as_lv(disp_val), x"A0DE", "reread: disp_val @ press_ref");
                    when others => NULL;
                end case;
            when btname =>
                case test_type is
                    when read_test =>
                        wait until main_state = idle;
                        is_equal(strg_out, x"2000", "read: strg_out @ btname [15-00]");
                        tmp_val := strg_out(31 downto 16);
                        is_equal(tmp_val, x"0104", "read: strg_out @ btname [31-16]");
                        tmp_val := strg_out(47 downto 32);
                        is_equal(tmp_val, x"75AA", "read: strg_out @ btname [47-32]");
                        tmp_val := x"0" & strg_out(59 downto 48);
                        is_equal(tmp_val, x"075A", "read: strg_out @ btname [59-48]");
                    when write_test =>
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"0010", "write: eeprom_in @ btname [07-00]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"0000", "write: eeprom_in @ btname [15-07]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"0042", "write: eeprom_in @ btname [23-16]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"0010", "write: eeprom_in @ btname [31-24]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"00A0", "write: eeprom_in @ btname [39-32]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"005A", "write: eeprom_in @ btname [47-40]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"00A7", "write: eeprom_in @ btname [55-48]");
                        wait until eeprom_ready = '1';
                        wait until eeprom_ready = '0';
                        is_equal(eeprom_in, x"0075", "write: eeprom_in @ btname [59-56]");
                        wait until main_state = idle;
                    when reread_test =>
                        wait until main_state = idle;
                        is_equal(strg_out, x"2001", "reread: strg_out @ btname");
                    when others => NULL;
                end case;
            when data =>
                case test_type is
                    -- the read_test will behave the same for every sdram memory cell
                    -- since it actually executes a memory init procedure and set every cell to 0
                    when read_test =>
                        wait until strg_state = idle;
                        -- check what is returned from storage
                        is_equal(strg_out, (others => 'U'), "read/init: sdram_addr @ data[" & u2hex(addr) & "]");
                        is_equal(strg_overflow, '1', "read/init: storage overflow after a short read");
                    when write_test =>
                        wait until sdram_ready = '0';
                        is_equal(sdram_in, x"000" & as_lv(addr + 1), "write 0: sdram_in @ data[" & u2hex(addr) & "]");
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "00",
                            "write 0: sdram_addr @ data[" & u2hex(addr) & "]"
                        );

                        wait until sdram_ready = '1';
                        wait until sdram_ready = '0';
                        is_equal(sdram_in, x"0010", "write 1: sdram_in @ data[" & u2hex(addr) & "]");
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "01",
                            "write 1: sdram_addr @ data[" & u2hex(addr) & "]"
                        );

                        wait until sdram_ready = '1';
                        wait until sdram_ready = '0';
                        is_equal(sdram_in, x"0002", "write 2: sdram_in @ data[" & u2hex(addr) & "]");
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "10",
                            "write 2: sdram_addr @ data[" & u2hex(addr) & "]"
                        );

                        wait until sdram_ready = '1';
                        wait until sdram_ready = '0';
                        is_equal(sdram_in, x"0000", "write 3: sdram_in @ data[" & u2hex(addr) & "]");
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "11",
                            "write 3: sdram_addr @ data[" & u2hex(addr) & "]"
                        );

                        wait until strg_state = idle;
                        is_equal(strg_overflow, '0', "write: storage overflow after each write");
                        sync_clk(CLK0M5, 1);

                        -- see if the display is updated correctly, note that this only display
                        -- the first 16 bits of the written data
                        is_equal(
                            as_lv(disp_val),
                            as_lv(addr) & x"00" & as_lv(addr + 1),
                            "write: disp_val @ data[" & u2hex(addr) & "]"
                        );
                    when reread_test =>
                        wait until sdram_ready = '0';
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "00",
                            "reread 0: sdram_addr @ data[" & u2hex(addr) & "]"
                        );
                        wait until sdram_ready = '1';
                        is_equal(sdram_out, x"000" & as_lv(addr + 1), "reread 0: sdram_out @ data[" & u2hex(addr) & "]");

                        wait until sdram_ready = '0';
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "01",
                            "reread 1: sdram_addr @ data[" & u2hex(addr) & "]"
                        );
                        wait until sdram_ready = '1';
                        is_equal(sdram_out, x"0010", "reread 1: sdram_out @ data[" & u2hex(addr) & "]");

                        wait until sdram_ready = '0';
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "10",
                            "reread 2: sdram_addr @ data[" & u2hex(addr) & "]"
                        );
                        wait until sdram_ready = '1';
                        is_equal(sdram_out, x"0002", "reread 2: sdram_out @ data[" & u2hex(addr) & "]");

                        wait until sdram_ready = '0';
                        is_equal(
                            sdram_addr,
                            x"00" & "00" & as_lv(addr) & "11",
                            "reread 3: sdram_addr @ data[" & u2hex(addr) & "]"
                        );
                        wait until sdram_ready = '1';
                        is_equal(sdram_out, x"0000", "reread 3: sdram_out @ data[" & u2hex(addr) & "]");

                        wait until strg_state = idle;
                        is_equal(strg_overflow, '0', "reread: storage overflow when reading incrementaly from the start");
                        is_equal(strg_out, x"000" & as_lv(addr + 1), "reread 0: strg_out @ data[" & u2hex(addr) & "]");
                        tmp_val := strg_out(31 downto 16);
                        is_equal(tmp_val, x"0010", "reread 1: strg_out @ data[" & u2hex(addr) & "]");
                        tmp_val := (others => '0');
                        tmp_val(1 downto 0) := strg_out(33 downto 32);
                        is_equal(tmp_val, x"0002", "reread 2: strg_out @ data[" & u2hex(addr) & "]");

                        -- wait one virt_clk tick for display to be updated
                        wait until main_state = idle;
                        is_equal(
                            as_lv(disp_val),
                            as_lv(addr) & x"00" & as_lv(addr + 1),
                            "reread: disp_val @ data[" & u2hex(addr) & "]"
                        );
                    when overflow_test =>
                        wait until strg_state = idle;
                        is_equal(strg_overflow, '1', "overflow: reading from a higher addr than last written to");
                        is_equal(strg_out, x"0005", "reread 0: strg_out @ data[5]");
                        tmp_val := strg_out(31 downto 16);
                        is_equal(tmp_val, x"0010", "reread 1: strg_out @ data[5]");
                        tmp_val := (others => '0');
                        tmp_val(1 downto 0) := strg_out(33 downto 32);
                        is_equal(tmp_val, x"0002", "reread 2: strg_out @ data[5]");
                end case;
        end case;
    end procedure;

    procedure press_key(constant right : in boolean := true) is begin
        if main_state /= idle then
            wait until main_state = idle;
        end if;
        if right then
            KEY <= "10"; -- press the right key, increasing the value by 1
        else
            KEY <= "01";
        end if;
        wait until main_state = mem_status_type'VALUE("input");
        KEY <= "11"; -- reset keys
    end procedure;

    procedure finish_test is begin
        if test_err_count > 0 then
            report "------ END OF SIMULATION: " & Integer'image(test_err_count) & "/" & Integer'image(test_total_count) & " tests failed -----";
        else
            report "------ END OF SIMULATION: " & Integer'image(test_total_count) & " tests run - ALL OK -----";
        end if;

        -- stop the clock
        test_end <= True;
        sync_clk(CLK50M, 2); -- ensure the test finishes at this point while the stimulus is being disabled
    end procedure;
begin
    wait until strg_state = idle;
    set_address(15);
    check_test_case(avg_sample_size, read_test);
    press_key;
    check_test_case(avg_sample_size, write_test);

    set_address(14);
    check_test_case(read_freq, read_test);
    press_key;
    check_test_case(read_freq, write_test);

    set_address(13);
    check_test_case(pm10norm, read_test);
    press_key;
    check_test_case(pm10norm, write_test);

    set_address(12);
    check_test_case(btname, read_test);
    press_key;
    check_test_case(btname, write_test);

    set_address(11);
    check_test_case(display_time, read_test);
    press_key;
    check_test_case(display_time, write_test);

    set_address(10);
    check_test_case(press_ref, read_test);
    press_key;
    check_test_case(press_ref, write_test);

    set_address(15);
    check_test_case(avg_sample_size, reread_test);
    set_address(14);
    check_test_case(read_freq, reread_test);
    set_address(13);
    check_test_case(pm10norm, reread_test);
    set_address(12);
    check_test_case(btname, reread_test);
    set_address(11);
    check_test_case(display_time, reread_test);
    set_address(10);
    check_test_case(press_ref, reread_test);

    for I in 0 to 9 loop
        set_address(I);
        check_test_case(data, read_test); -- actually init
        -- now set an initial value using key presses, analyze the final write op
        for J in 0 to I loop
            press_key;
            if J < I then
                wait until main_state = idle;
            end if;
        end loop;
        check_test_case(data, write_test);
    end loop;

    for I in 0 to 9 loop
        set_address(I);
        check_test_case(data, reread_test);
    end loop;

    -- finally check overflow signalling
    -- first write something on a low address
    set_address(2);
    wait until strg_state = busy;
    press_key(false); -- left
    wait until strg_state = busy;
    wait until main_state = idle;
    -- now read something from a higher address (sdram overflow should become triggered now)
    set_address(4);
    check_test_case(data, overflow_test);

    -- check data validation, try writing 0 as read_freq and pm10norm
    EXT_VALUE <= i2v(0, 4);
    set_address(14);
    wait until strg_state = busy;
    wait until main_state = idle;
    is_equal(strg_err, '0', "error not set: validation check @ read_freq");
    press_key;
    wait until strg_state = busy;
    wait until main_state = idle;
    -- confirm the error flag is high
    is_equal(strg_err, '1', "error set: validation check @ read_freq");

    set_address(13);
    wait until strg_state = busy;
    wait until main_state = idle;
    is_equal(strg_err, '0', "error not set: validation check @ pm10norm");
    press_key;
    wait until strg_state = busy;
    wait until main_state = idle;
    is_equal(strg_err, '1', "error set: validation check @ pm10norm");
    EXT_VALUE <= (others => 'U');

    -- now confirm that the values are equal to the last reread check
    set_address(14);
    wait until strg_state = busy;
    wait until main_state = idle;
    is_equal(strg_out, x"003D", "reread: strg_out @ read_freq");

    set_address(13);
    wait until strg_state = busy;
    wait until main_state = idle;
    is_equal(strg_out, x"0033", "reread: strg_out @ pm10norm");

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
