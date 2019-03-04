library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library drivers, utils;
    use drivers.rn4020_utils.all;
    use utils.utils.all;
    use utils.fake_mem.all;

entity rn4020 is
    GENERIC(
        MAX_BUF_BYTE : INTEGER := 20 -- 20 bytes
    );
    PORT (
        clocks        :  IN t_clocks;
        rw, enable    :  IN STD_LOGIC := '0';
        ready         : OUT STD_LOGIC := '0';

        RX            :  IN STD_LOGIC;
        addr          :  IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        data_in       :  IN STD_LOGIC_VECTOR(MAX_BUF_BYTE * 8 - 1 DOWNTO 0);
        data_out      : OUT STD_LOGIC_VECTOR(MAX_BUF_BYTE * 8 - 1 DOWNTO 0);
        device_name   :  IN String := "";

        WAKE_SW,
        WAKE_HW,
        TX            : OUT STD_LOGIC;
        init_progress : OUT UNSIGNED( 3 downto 0) -- can be used to monitor the initialization
    );
END entity;

architecture arch of rn4020 is
    type rn4020_state_type is (disabled, initialize, reinit, idle, busy, error);
    signal state : rn4020_state_type := disabled;

    signal fake_mem     : bt_mem := (others => (others => '0'));
    signal xfer_running : boolean := False;
    signal xfer_item    : integer := 0;
  begin
    process(clocks.CLK_1M19) is
        variable sleep   : unsigned(2 downto 0) := (others => '0');
        variable rw_mode : std_logic := '0';
        variable mem_map : integer := 0;
        variable used_name  : string (1 to 10) := "SPSP-001" & NUL & NUL;
  begin
        if rising_edge(clocks.CLK_1M19) then
            case state IS
                WHEN disabled | reinit =>
                    -- don't start before instructed to
                    if enable = '1' or state = reinit then
                        state <= initialize;
                    end if;
                WHEN initialize =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        state <= idle;
                        used_name := device_name;
                        ready <= '1';
                    end if;
                WHEN idle =>
                    -- wait for run signal
                    if enable = '1' then
                        ready <= '0';
                        state <= busy;
                        rw_mode  := rw;
                        data_out <= (others => '0');
                    elsif device_name /= used_name then
                        state <= reinit;
                    end if;
                WHEN busy =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        mem_map := to_integer(unsigned(addr));
                        if rw = '1' then
                            -- write
                            fake_mem(mem_map)(159 downto 0) <= data_in(159 downto 0);
                        else
                            -- read
                            data_out(159 downto 0) <= fake_mem(mem_map)(159 downto 0);
                        end if;
                        state <= idle;
                        ready <= '1';
                    end if;
                WHEN others => NULL;
            end CASE;

            -- test bench data pipe for BT commands
            if xfer_running then
                fake_mem(9)(xfer_item) <= RX;
                if xfer_item > 0 then
                    xfer_item <= xfer_item - 1;
                else
                    xfer_running <= False;
                    state <= idle;
                    ready <= '1';
                end if;
            elsif RX = '1' then
                xfer_running <= True;
                state <= error;
                ready <= '0';
                xfer_item <= 159;
            end if;
        end if;
    end process;

    -- blank signals to get rid of warnings
    WAKE_SW <= '0';
    WAKE_HW <= '0';
    TX <= '0';
    init_progress <= (others => '0');
end arch;
