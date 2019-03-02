library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.all;

package utils is
    -- common constants
    constant DATA_PRESS_LEN  : integer := 11;
    constant DATA_PM10_LEN   : integer :=  9;
    constant DATA_HUM_LEN    : integer :=  7;
    constant DATA_TEMP_LEN   : integer :=  7;
    constant DATA_PM10P_LEN  : integer := 10;
    constant CHECKSUM_LEN    : integer :=  6;

    constant DATA_PRESS_OFFSET  : integer := DATA_PRESS_LEN - 1;
    constant DATA_PM10_OFFSET   : integer := DATA_PRESS_OFFSET + DATA_PM10_LEN;
    constant DATA_HUM_OFFSET    : integer := DATA_PM10_OFFSET  + DATA_HUM_LEN;
    constant DATA_TEMP_OFFSET   : integer := DATA_HUM_OFFSET   + DATA_TEMP_LEN;
    constant DATA_PM10P_OFFSET  : integer := DATA_TEMP_OFFSET  + DATA_PM10P_LEN;
    constant CHECKSUM_OFFSET    : integer := DATA_TEMP_OFFSET  + CHECKSUM_LEN;

    -- common functions
    function std2bool(constant v: in std_logic) return boolean;
    function bool2std(constant b: in boolean) return std_logic;
    function Int_to_Seg(constant i : in integer range 0 to 31; constant dp : in boolean) return STD_LOGIC_VECTOR;
    function i2v(constant i, size: in integer) return std_logic_vector;
    function c2v(constant c: in Character) return Std_logic_vector;
    function v2c(constant v: in Std_logic_vector(7 downto 0)) return Character;
    function c2v6bit(constant c: in Character) return Std_logic_vector;
    function v2c6bit(constant v: in Std_logic_vector(5 downto 0)) return Character;
    function v2str(constant data : in std_logic_vector(59 downto 0)) return String;
    function incV(constant v: in std_logic_vector; constant i : in integer) return std_logic_vector;

    -- common types
    type handler_state_type is (INIT, READY, STORAGE);
    type machine_state_type is (initialize, ready, execute, busy, error);
    type common_state_type is (initialize, idle, busy, error);
    type storage_data_type is (
        data_record, setting_pm10_norm, setting_read_freq, setting_avg_sample_size,
        setting_device_name, setting_display_timeout, setting_pressure_reference
    );
    type comms_reqest_type is (storage_data, current_timestamp, reset_uid);
    type mem_status_type is (boot, idle, reread, update, input);

    -- signal structures for simplifying I/O
    type t_clocks is record
        CLK_50M,
        CLK_1M19,
        CLK_0M5,
        CLK_0HZ01,
        CLK_0HZ1,
        CLK_1HZ: STD_LOGIC;
    end record;

    type t_sensors_in is record
        -- GP2Y1010/ADC
        ADC_SDAT : STD_LOGIC;
    end record;

    type t_sensors_out is record
        -- GP2Y1010/ADC
        ADC_SADDR,
        ADC_CS_N,
        ADC_SCLK,
        PM_ILED,

        -- LPS331AP
        PRESS_SDO,
        PRESS_CS    : STD_LOGIC;
    end record;

    type t_sensors_inout is record
        -- DHT-11
        HUM_DAT,

        -- LPS331AP
        PRESS_SDA,
        PRESS_SCL   : STD_LOGIC;
    end record;

    type t_comms_in is record
        -- RN4020
        BT_CONNECTED,
        BT_RX       : STD_LOGIC;
    end record;

    type t_comms_out is record
        BT_TX,
        BT_WAKE_SW,
        BT_WAKE_HW  : STD_LOGIC;
    end record;

    type t_storage_request is record
        reset,
        rw_mode    : STD_LOGIC;
        data_type  : storage_data_type;
        data       : STD_LOGIC_VECTOR(59 DOWNTO 0);
        timestamp  : STD_LOGIC_VECTOR(19 DOWNTO 0);
        resolution : UNSIGNED(5 DOWNTO 0);
        latest     : BOOLEAN;
    end record;

    type t_storage_response is record
        data      : STD_LOGIC_VECTOR(59 DOWNTO 0);
        timestamp : STD_LOGIC_VECTOR(19 DOWNTO 0);
        error,
        overflow  : STD_LOGIC;
    end record;

    type t_comms_request is record
        uid         : UNSIGNED(15 DOWNTO 0);
        parsed_ok   : BOOLEAN;
        req_type    : comms_reqest_type;
        storage_req : t_storage_request;
    end record;

    type t_display_out is record
        -- Segment Display
        REG_CLK,
        REG_LATCH,
        REG_DATA,
        DISP_ENA   : STD_LOGIC;
        MLTPLX_CH  : STD_LOGIC_VECTOR(1 downto 0);
    end record;

    type t_storage_inout is record
        -- EEPROM
        EEPROM_SCL,
        EEPROM_SDA : STD_LOGIC;
        -- SDRAM
        SDRAM_data : STD_LOGIC_VECTOR(15 DOWNTO 0);
    end record;

    type t_storage_out is record
        -- SDRAM
        SDRAM_addr            : STD_LOGIC_VECTOR(12 DOWNTO 0);

        SDRAM_data_mask,
        SDRAM_bank_addr       : STD_LOGIC_VECTOR(1 DOWNTO 0);

        SDRAM_clk,
        SDRAM_clock_enable,
        SDRAM_we_n,
        SDRAM_cas_n,
        SDRAM_ras_n,
        SDRAM_cs_n            : STD_LOGIC;
    end record;
end package;

package body utils is
    function std2bool(constant v: in std_logic) return boolean is
    begin
        return (v = '1');
    end function;

    function bool2std(constant b: in boolean) return std_logic is
        variable ret : std_logic := '0';
    begin
        if b then
            ret := '1';
        end if;
        return ret;
    end function;

    function Int_to_Seg(constant i : in integer range 0 to 31; constant dp : in boolean) return STD_LOGIC_VECTOR is
        variable digit : STD_LOGIC_VECTOR(7 downto 0);
    begin
        case i is
            when 0  => digit := "00010100";
            when 1  => digit := "11010111";
            when 2  => digit := "01001100";
            when 3  => digit := "01000101";
            when 4  => digit := "10000111";
            when 5  => digit := "00100101";
            when 6  => digit := "00100100";
            when 7  => digit := "01010111";
            when 8  => digit := "00000100";
            when 9  => digit := "00000101";
            when 10 => digit := "00000110"; -- A
            when 11 => digit := "10100100"; -- b
            when 12 => digit := "00111100"; -- C
            when 13 => digit := "11000100"; -- d
            when 14 => digit := "00101100"; -- E
            when 15 => digit := "00101110"; -- F
            when 16 => digit := "10000110"; -- H
            when 17 => digit := "11101111"; -- -
            when 18 => digit := "00001110"; -- P
            when 19 => digit := "00001010"; -- P.
            when others => digit := "11111111";
        end case;
        if dp then
            digit(2) := '0';
        end if;
        return digit;
    end Int_to_Seg;

    function i2v(constant i, size: in integer) return std_logic_vector is begin
        return std_logic_vector( to_unsigned(i, size) );
    end i2v;

    function c2v(constant c: in Character) return Std_logic_vector is begin
        return std_logic_vector(to_unsigned(character'pos(c), 8));
    end function;

    function v2c(constant v: in Std_logic_vector(7 downto 0)) return Character is begin
        return character'val(to_integer(unsigned(v)));
    end function;

    function c2v6bit(constant c: in Character) return Std_logic_vector is
        variable i : integer range 0 to 255;
    begin
        i := to_integer(unsigned(c2v(c)));
        case i is
            when 48 to 57   => i := i - 47; -- 0-9
            when 65 to 90   => i := i - 54; -- A-Z
            when 35         => i := 37;     -- #
            when 43 to 47   => i := i - 5;  -- + , - . /
            when 58         => i := 43;     -- :
            when 64         => i := 44;     -- @
            when 91 to 93   => i := i - 46; -- [ \ ]
            when 95         => i := 48;     -- _
            when 126        => i := 49;     -- ~
            when others     => i := 0;      -- Undefined
        end case;
        return std_logic_vector(to_unsigned(i, 6));
    end function;

    function v2c6bit(constant v: in Std_logic_vector(5 downto 0)) return Character is
        variable i : integer range 0 to 255;
    begin
        i := to_integer(unsigned(v));
        case i is
            when  1 to 10   => i := i + 47; -- 0-9
            when 11 to 36   => i := i + 54; -- A-Z
            when 37         => i := 35;     -- #
            when 38 to 42   => i := i + 5;  -- + , - . /
            when 43         => i := 58;     -- :
            when 44         => i := 64;     -- @
            when 45 to 47   => i := i + 46; -- [ \ ]
            when 48         => i := 95;     -- _
            when 49         => i := 126;    -- ~
            when others     => i := 0;      -- Undefined
        end case;
        return character'val(i);
    end function;

    function incV(constant v: in std_logic_vector; constant i : in integer) return std_logic_vector is
    begin
        return std_logic_vector(unsigned(v) + i);
    end function;

    function v2str(constant data : in std_logic_vector(59 downto 0)) return String is
        variable a, b : integer range 0 to 60;
        variable res  : string(1 to 10) := (others => NUL);
    begin
        for I in 1 to 10 loop
            a := (11 - I) * 6 - 1;
            b := a - 5;
            res(I) := v2c6bit(data(a downto b));
        end loop;

        return res;
    end function;
end package body;
