architecture arch of Display is
    signal state         : common_state_type := idle;
    signal disp_val      : unsigned(15 downto 0) := (others => '1');
    signal disp_enable   : std_logic := '1';
    signal trigger       : unsigned( 9 downto 0) := (others => '0');
    signal trigger_rst,
           trigger_ack   : std_logic := '0';
    signal key_event     : unsigned(1 downto 0) := (others => '1');
    signal key_event_syn,
           key_event_ack : boolean := false;
    signal mltplx_reversed : std_logic_vector(1 downto 0) := (others => '0');
begin
    displaying <= disp_enable;
    display_out.MLTPLX_CH(0) <= not mltplx_reversed(0);
    display_out.MLTPLX_CH(1) <= not mltplx_reversed(1);

    display_drv: entity drivers.sm410564 PORT MAP (
        clocks => clocks, enable => disp_enable,

        MLTPLX_CH => mltplx_reversed, MLTPLX_ENA => display_out.DISP_ENA,
        REG_CLK => display_out.REG_CLK, REG_LATCH => display_out.REG_LATCH, REG_DATA => display_out.REG_DATA,
        dvalue => disp_val, dpoint => unsigned(dpoint), data_format => mixed
    );

    DISPLAY_TIMEOUT_TRIGGER: process(clocks.CLK_0HZ1)
        constant MULT : unsigned(3 downto 0) := to_unsigned(10, 4);
        -- allow auto-shutdown while bypassing the bootup disabled-state
        variable disp_state : boolean := false;
    begin
        if rising_edge(clocks.CLK_0HZ1) then
            if trigger_rst = '1' then
                trigger_ack <= '1';
                trigger <= unsigned(timeout) * MULT - 1;
                disp_state := true;
            elsif trigger > 0 then
                disp_enable <= '1';
                trigger_ack <= '0';
                trigger <= trigger - 1;
            elsif disp_state then
                disp_enable <= '0';
                disp_state := false;
            end if;
        end if;
    end process;

    DISPLAY_MANAGER: process(clocks.CLK_0M5)
        variable enable_ack : boolean := false;
    begin
        if rising_edge(clocks.CLK_0M5) then
            case state is
                when idle =>
                    ready <= '1';
                    if enable = '1' and not enable_ack then
                        state <= busy;
                        ready <= '0';
                        -- toggle trigger_rst signal
                        trigger_rst <= '1';
                        key_event <= unsigned(keys);
                        if disp_enable = '1' and key_event < 3 then
                            -- don't send a syn if no key was pressed or the display was hidden
                            key_event_syn <= true;
                        end if;
                        enable_ack := true;
                    end if;
                when busy =>
                    if trigger_ack = '1' then
                        trigger_rst <= '0';
                        ready <= '1';
                        state <= idle;
                    end if;
                when others => state <= idle;
            end case;
            if key_event_ack and key_event_syn then
                key_event_syn <= false;
            end if;
            if enable = '0' and enable_ack then
                enable_ack := false;
            end if;
        end if;
    end process;

    DISPLAY_CYCLER: process(clocks.CLK_0HZ1)
        type t_displayed is (PRESSURE, TEMPERATURE, HUMIDITY, PM10_VALUE, PM10_PERCENTAGE);
        variable now_showing : t_displayed := t_displayed'LOW;
        variable switch : unsigned (4 downto 0) := (others => '0');

        alias pm10_perc  is data(DATA_PM10P_OFFSET downto DATA_PM10P_OFFSET + 1 - DATA_PM10P_LEN);
        alias temp       is data(DATA_TEMP_OFFSET  downto DATA_TEMP_OFFSET  + 1 - DATA_TEMP_LEN);
        alias hum        is data(DATA_HUM_OFFSET   downto DATA_HUM_OFFSET   + 1 - DATA_HUM_LEN);
        alias pm10       is data(DATA_PM10_OFFSET  downto DATA_PM10_OFFSET  + 1 - DATA_PM10_LEN);
        alias press      is data(DATA_PRESS_OFFSET downto DATA_PRESS_OFFSET + 1 - DATA_PRESS_LEN);

        constant DISP_C_PREF    : unsigned(15 downto 0) := to_unsigned(12000, 16); -- C
        constant DISP_CNEG_PREF : unsigned(15 downto 0) := to_unsigned(20000, 16); -- C-
        constant DISP_H_PREF    : unsigned(15 downto 0) := to_unsigned(16000, 16); -- H
        constant DISP_P_PREF    : unsigned(15 downto 0) := to_unsigned(18000, 16); -- P
        constant DISP_Pd_PREF   : unsigned(15 downto 0) := to_unsigned(19000, 16); -- P.

        function get_next(
            constant v   : in t_displayed;
            constant dir : in boolean := true
        ) return t_displayed is
            variable res : t_displayed;
        begin
            if dir then
                if t_displayed'POS(v) < t_displayed'POS(t_displayed'HIGH) then
                    res := t_displayed'SUCC(v);
                else
                    res := t_displayed'LOW;
                end if;
            else
                if t_displayed'POS(v) > t_displayed'POS(t_displayed'LOW) then
                    res := t_displayed'PRED(v);
                else
                    res := t_displayed'HIGH;
                end if;
            end if;

            return res;
        end function;
    begin
        if rising_edge(clocks.CLK_0HZ1) then
            if trigger = 0 then
                switch := (4 => '0', 3 downto 0 => '1');
                now_showing := t_displayed'LOW;
            else
                case now_showing is
                    when PRESSURE        => disp_val <= to_unsigned(0, 16) + unsigned(press);
                    when HUMIDITY        => disp_val <= DISP_H_PREF  + unsigned(hum);
                    when PM10_VALUE      => disp_val <= DISP_P_PREF  + unsigned(pm10);
                    when PM10_PERCENTAGE => disp_val <= DISP_Pd_PREF + unsigned(pm10_perc);
                    when TEMPERATURE     =>
                        if unsigned(temp) >= 40 then
                            disp_val <= DISP_C_PREF     + unsigned(temp) - 40;
                        else
                            disp_val <= DISP_CNEG_PREF  + unsigned(temp) - 40;
                        end if;
                end case;
                if switch = 0 then
                    now_showing := get_next(now_showing);
                    switch := (4 => '0', 3 downto 0 => '1');
                end if;
                if key_event_syn and not key_event_ack then
                    key_event_ack <= true;
                    now_showing := get_next(now_showing, (key_event = 2));
                    switch := (others => '1');
                elsif key_event_ack then
                    key_event_ack <= false;
                end if;

                switch := switch - 1;
            end if;
        end if;
    end process;
end arch;
