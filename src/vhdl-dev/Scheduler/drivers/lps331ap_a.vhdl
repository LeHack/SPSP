architecture arch of lps331ap is
    type t_press_state_type is (initialize, reinit, idle, busy, error);
    signal state : t_press_state_type := initialize;
    constant slave_addr : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1011100";
    signal i2c_ena, i2c_rw, i2c_busy, busy_prev : STD_LOGIC;
    signal i2c_addr : STD_LOGIC_VECTOR(6 DOWNTO 0);
    signal i2c_data_wr, i2c_data_rd : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    signal div_number, div_quotient,
           div_denominator : STD_LOGIC_VECTOR (23 DOWNTO 0);
begin
    -- When using the I2C, CS must be tied high
    PRESS_CS <= '1';
    -- if the SDO pad is connected to ground, the device address is 1011100b
    PRESS_SDO <= '0';

    i2c : entity ext.i2c_master PORT MAP (
        clk => clocks.CLK_50M, reset_n => '1', ena => i2c_ena, addr => i2c_addr,
        rw => i2c_rw, data_wr => i2c_data_wr, busy => i2c_busy, data_rd => i2c_data_rd,
        sda => PRESS_SDA, scl => PRESS_SCL
    );

    div_inst : entity ext.div_signed PORT MAP (
        clock    => clocks.CLK_50M,
		numer	 => div_number,
		denom	 => div_denominator,
		quotient => div_quotient
	);

    LPS331AP_DRV: process(clocks.CLK_1M19)
        subtype reg_addr is STD_LOGIC_VECTOR(7 downto 0);
        subtype reg_data is STD_LOGIC_VECTOR(7 downto 0);
        type i2c_state_type is (idle, processing, done);
        type i2c_rw_type is (i2c_read, i2c_write);

        variable busy_cnt   : integer range 0 to 7 := 0;
        variable i2c_state  : i2c_state_type := idle;
        variable prev_press_ref : std_logic_vector(7 downto 0);

        procedure i2c_transaction(
                rw : IN i2c_rw_type;
                addr : IN reg_addr;
                data : IN reg_data := (others => '0')) is
        begin
            busy_prev <= i2c_busy;
            if (busy_prev = '0' AND i2c_busy = '1') then
                busy_cnt := busy_cnt + 1;
            end if;

            case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= slave_addr;
                    i2c_rw <= '0';
                    i2c_data_wr <= addr;
                when 1 =>
                    case rw is
                        when i2c_write =>
                            i2c_rw <= '0';
                            i2c_data_wr <= data;
                        when i2c_read =>
                            i2c_rw <= '1';
                    end case;
                when 2 =>
                    i2c_ena <= '0';
                    if (i2c_busy = '0') then
                        busy_cnt := 0;
                        i2c_state := done;
                    end if;
                when others => NULL;
            end case;
        end procedure;

        -- Setup required register data
        constant dev_id_reg     : reg_addr := x"0F"; -- WHO_AM_I
        constant expected_id    : reg_data := x"BB"; -- Expected device ID
        constant ctrl_reg1      : reg_addr := x"20"; -- CTRL_REG1
        constant ctrl_reg1_data : reg_data := x"94"; -- Power up, 1Hz data rate for Temp/Press, BDU enable
        -- Set pressure reference point (default is for Cracow: -35hPa, stored in eeprom)
        constant ref_p_xlo      : reg_addr := x"08"; -- REF_P_XL
        constant ref_p_lo       : reg_addr := x"09"; -- REF_P_L
        constant ref_p_hi       : reg_addr := x"0A"; -- REF_P_H

        variable proc_stage : integer range 0 to 5 := 0;

        procedure setup is begin
            case proc_stage is
                when 0 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_read, dev_id_reg);
                        when done =>
                            -- check device ID
                            if i2c_data_rd = expected_id then
                                i2c_state := idle;
                                proc_stage := 1;
                            -- if it's not what we expect, go to error state and stop
                            -- to avoid the risk of damaging the device
                            else
                                state <= error;
                            end if;
                    end case;
                when 1 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_write, ctrl_reg1, ctrl_reg1_data);
                        when done =>
                            i2c_state := idle;
                            proc_stage := 2;
                    end case;
                when 2 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_write, ref_p_xlo, x"FF");
                        when done =>
                            i2c_state := idle;
                            proc_stage := 3;
                            -- snapshot the current value of the reference point, in case it changes
                            prev_press_ref := REFERENCE_PRESS;
                    end case;
                when 3 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_write, ref_p_lo, prev_press_ref(3 downto 0) & x"F");
                        when done =>
                            i2c_state := idle;
                            proc_stage := 4;
                    end case;
                when 4 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_write, ref_p_hi, x"F" & prev_press_ref(7 downto 4));
                        when done =>
                            i2c_state := idle;
                            proc_stage := 0;
                            -- setup is ready, go to idle
                            if state /= reinit then
                                state <= idle;
                            else
                                -- start working now
                                state <= busy;
                            end if;
                    end case;
                when others => NULL;
            end case;
        end procedure;


        variable temp_data   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); -- sign + 15 bit
        variable press_data  : STD_LOGIC_VECTOR(23 downto 0) := (others => '0'); -- sign + 23 bit

        type op_type is (division, results);
        procedure parse_temperature_data(step : in op_type) is
        -- T(degC) = 42.5 + (TEMP_OUT_H & TEMP_OUT_L)[dec]/480
        begin
            case step is
                when division =>
                    -- add 82.5 * 480 (42.5 from the docs + 40 of our own data offset)
                    div_number <= std_logic_vector(to_signed(to_integer(signed(temp_data)) + 39600, 24));
                    div_denominator <= i2v(480, 24);
                when results =>
                    out_temperature <= to_unsigned(to_integer(signed(div_quotient)), 7);
            end case;
        end procedure;

        procedure parse_pressure_data(step : in op_type) is
        -- Pout(mbar) = (PRESS_OUT_H & PRESS_OUT_L & PRESS_OUT_XL)[dec]/4096
        begin
            case step is
                when division =>
                    div_number <= press_data;
                    -- 4096
                    div_denominator <= (12 => '1', others => '0');
                when results =>
                    out_pressure <= to_unsigned(to_integer(signed(div_quotient)), 11);
            end case;
        end procedure;

        -- sensor registry addresses
        constant status_reg     : reg_addr := x"27"; -- STATUS_REG
        constant temp_reg_lo    : reg_addr := x"2B"; -- TEMP_OUT_L
        constant temp_reg_hi    : reg_addr := x"2C"; -- TEMP_OUT_H
        constant press_reg_xlo  : reg_addr := x"28"; -- PRESS_OUT_XL
        constant press_reg_lo   : reg_addr := x"29"; -- PRESS_OUT_L
        constant press_reg_hi   : reg_addr := x"2A"; -- PRESS_OUT_H

        procedure read_sensors is
        begin
            case proc_stage is
                when 0 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_read, temp_reg_lo);
                        when done =>
                            temp_data(7 downto 0) := i2c_data_rd;
                            proc_stage := 1;
                            i2c_state := idle;
                    end case;
                when 1 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_read, temp_reg_hi);
                        when done =>
                            temp_data(15 downto 8) := i2c_data_rd;
                            parse_temperature_data(division);
                            proc_stage := 2;
                            i2c_state := idle;
                    end case;
                when 2 =>
                    case i2c_state is
                        when idle =>
                            parse_temperature_data(results);
                            i2c_state := processing;
                            i2c_transaction(i2c_read, press_reg_xlo);
                        when processing =>
                            i2c_transaction(i2c_read, press_reg_xlo);
                        when done =>
                            press_data(7 downto 0) := i2c_data_rd;
                            proc_stage := 3;
                            i2c_state := idle;
                    end case;
                when 3 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_read, press_reg_lo);
                        when done =>
                            press_data(15 downto 8) := i2c_data_rd;
                            proc_stage := 4;
                            i2c_state := idle;
                    end case;
                when 4 =>
                    case i2c_state is
                        when idle | processing =>
                            i2c_state := processing;
                            i2c_transaction(i2c_read, press_reg_hi);
                        when done =>
                            press_data(23 downto 16) := i2c_data_rd;
                            parse_pressure_data(division);
                            proc_stage := 5;
                            i2c_state := idle;
                    end case;
                when 5 =>
                    parse_pressure_data(results);
                    proc_stage := 0;
            end case;
        end procedure;

    begin
        -- check if state allows us to do anything
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when initialize | reinit =>
                    -- when done it will transition to idle or error states
                    setup;
                when idle =>
                    ready <= '1';
                    -- wait for trigger
                    if enable = '1' then
                        ready <= '0';
                        -- check if we need to reinitialize the device
                        if prev_press_ref /= REFERENCE_PRESS then
                            state <= reinit;
                        else
                            state <= busy;
                        end if;
                    end if;
                when busy =>
                    state <= busy;

                    -- bail on final stage
                    if proc_stage = 5 then
                        state <= idle;
                    end if;

                    read_sensors;
                when others => state <= idle;
            end case;
        end if;
    end process;
end arch;

