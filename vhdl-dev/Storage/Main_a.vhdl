architecture arch of Main is
    -- Clock structure
    signal clocks : t_clocks;

    -- Storage State/Flags
    signal strg_ready,
           strg_enable,
           strg_error,
           strg_reset,
           strg_overflow,
           strg_rw,   -- '0' Read, '1' Read/Write
           strg_run   : std_logic := '0';

    -- Storage Data
    signal strg_data_type : storage_data_type;
    signal strg_timestamp : STD_LOGIC_VECTOR(19 DOWNTO 0);
    signal strg_data_in,
           strg_data_out  : STD_LOGIC_VECTOR(59 DOWNTO 0);

    -- Display
    signal disp_val : unsigned(15 downto 0) := (others => '1');
    signal dpoint   : unsigned( 3 downto 0) := (others => '0');

    signal state : mem_status_type := boot;
begin
    clk_map : clocks.CLK_50M <= CLOCK_50;
    vclock : entity utils.clock_divider -- default denominator is 42
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_1M19);
    khz_clock : entity utils.clock_divider -- 500kHz
        GENERIC MAP (denominator => to_unsigned(100, 26))
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_0M5);
    hz10_clock : entity utils.clock_divider
        GENERIC MAP (denominator => HZ_DURATION/10)
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_0HZ1);
    hz_clock : entity utils.clock_divider
        GENERIC MAP (denominator => HZ_DURATION)
        PORT MAP (clk_in => CLOCK_50, clk_out => clocks.CLK_1HZ);

    display : entity drivers.sm410564 PORT MAP (
        clocks => clocks, enable => '1', -- always on

        MLTPLX_CH => display_out.MLTPLX_CH, REG_DATA => display_out.REG_DATA,
        REG_CLK => display_out.REG_CLK, REG_LATCH => display_out.REG_LATCH,
        dvalue => disp_val, data_format => hexadecimal
    );

    storage_drv : entity modules.Storage PORT MAP (
        -- Clocks
        clocks => clocks,

        -- Control
        enable          => strg_enable,
        ready           => strg_ready,
        rw              => strg_rw,
        error           => strg_error,
        reset_settings  => strg_reset,

        -- Data
        data_type => strg_data_type,
        timestamp => strg_timestamp,
        overflow  => strg_overflow,
        data_in   => strg_data_in,
        data_out  => strg_data_out,

        -- I/O
        storage_inout => storage_inout, storage_out => storage_out
    );

    process(clocks.CLK_0M5)
        variable tvalue, tmpval : unsigned(15 downto 0) := (others => '0');

        procedure set_addr(constant addr : in STD_LOGIC_VECTOR(3 downto 0)) is
            variable addr_i : integer range 0 to 15 := to_integer(unsigned(addr));
        begin
            case addr_i is
                when 15 => strg_data_type <= setting_avg_sample_size;
                when 14 => strg_data_type <= setting_read_freq;
                when 13 => strg_data_type <= setting_pm10_norm;
                when 12 => strg_data_type <= setting_device_name;
                when 11 => strg_data_type <= setting_display_timeout;
                when 10 => strg_data_type <= setting_pressure_reference;
                when others =>
                    strg_data_type <= data_record;
                    strg_timestamp <= (others => '0');
                    strg_timestamp(3 downto 0) <= addr;
            end case;
        end procedure;

        variable dipsw_addr : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
        variable read_row : unsigned(1 downto 0) := (others => '0');
        variable strg_first_row : unsigned(15 DOWNTO 0);
    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_0M5) then
            if strg_ready = '1' and strg_enable = '0' then
                -- get the stored value first
                case state is
                    when reread =>
                        -- read current value from memory
                        strg_rw  <= '0';
                        strg_enable <= '1';
                        state <= update;
                        read_row := (others => '0');
                    when update =>
                        if strg_data_out(15 downto 0) = (15 downto 0 => 'U') then
                            tvalue := (others => '0');
                        else
                            tvalue := unsigned(strg_data_out(15 downto 0));
                        end if;
                        state <= idle;
                    when boot | idle =>
                        if dipsw_addr /= DIPSW or state = boot then
                            state <= reread;
                            dipsw_addr := DIPSW;
                            set_addr(dipsw_addr);
                        elsif unsigned(KEY) < 3 then
                            state <= input;
                            if EXT_VALUE /= (0 to 3 => 'U') then
                                tvalue(15 downto 4) := (others => '0');
                                tvalue( 3 downto 0) := unsigned(EXT_VALUE);
                            elsif KEY(0) = '0' then
                                tvalue := tvalue + 1;
                            elsif KEY(1) = '0' then
                                tvalue := tvalue - 1;
                            end if;
                            -- set to write mode
                            strg_rw  <= '1';
                            -- send some data and prepare our test
                            tmpval := tvalue;
                            if strg_data_out = (59 downto 0 => 'U') then
                                strg_data_in <= (others => '0');
                                if unsigned(dipsw_addr) < 13 then
                                    -- add some bits to check for in the test suite
                                    -- when writing higher data rows
                                    strg_data_in(20) <= '1';
                                    strg_data_in(33) <= '1';
                                    strg_data_in(41) <= '1';
                                end if;
                            else
                                strg_data_in <= strg_data_out;
                            end if;
                            strg_data_in(15 downto 0) <= std_logic_vector(tmpval);
                            strg_enable <= '1';
                        end if;
                    when input =>
                        if unsigned(KEY) = 3 then
                            state <= idle;
                        end if;
                end case;
            elsif strg_enable = '1' then
                strg_enable <= '0';
            end if;
            disp_val <= tvalue;
            disp_val(15 downto 12) <= unsigned(dipsw_addr);
          end if;
    end process;
end arch;
