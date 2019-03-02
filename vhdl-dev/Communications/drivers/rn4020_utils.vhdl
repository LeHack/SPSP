library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

package rn4020_utils is
    constant MAX_CMD_LEN : Integer := 100;

    type t_rn4020_cfg is record
        ready,
        trigger,
        rw_mode     : STD_LOGIC;

        addr      : STD_LOGIC_VECTOR(  3 DOWNTO 0);
        data_in,
        data_out  : STD_LOGIC_VECTOR(159 DOWNTO 0);
    end record;

    function v2hex(constant v: in Std_logic_vector(3 downto 0)) return Character;
    function hex2V(constant c: in Character) return Std_logic_vector;
    function is_valid(constant c: in Character) return Boolean;

    function check_response (
                constant check: in String(1 to 3);
                constant data: in String;
                constant position : in Integer) return Boolean;
end package;

package body rn4020_utils is
    function hex2v(constant c: in Character) return Std_logic_vector is
        variable tmp : integer range 0 to 70;
    begin
        tmp := character'pos(c);
        if tmp > 47 then
            tmp := tmp - 48;
        else
            tmp := 0;
        end if;
        if tmp > 9 then
            tmp := tmp - 7; -- distance from '9' to 'A' in ASCII
        end if;
        return std_logic_vector(to_unsigned(tmp, 4));
    end function;

    function v2hex(constant v: in Std_logic_vector(3 downto 0)) return Character is
        variable tmp : integer range 0 to 70;
    begin
        tmp := to_integer(unsigned(v)) + 48;
        if tmp > 57 then
            tmp := tmp + 7;
        end if;
        return character'val(tmp);
    end function;

    function is_valid(constant c: in Character) return Boolean is
    begin
        return Character'pos(c) >= 30;
    end function;

    function check_response (
                constant check    : in String(1 to 3);
                constant data     : in String;
                constant position : in Integer) return Boolean is
        variable sample : String(1 to 3) := (others => NUL);
    begin
        -- now get the last 3 characters from the buffer (w/o CR&LF)
        for I in 1 to 3 loop
            if position - I > 0 then
                sample(4 - I) := data(position - I);
            else
                sample(4 - I) := data(data'HIGH - I + position);
            end if;
        end loop;

        return (sample = check);
    end function;
end package body;
