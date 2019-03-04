library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;

entity dht11 is
    PORT (
        clocks     : IN t_clocks;
        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';

        HUM_DAT         : INOUT STD_LOGIC;
        out_humidity,
        out_temperature : OUT UNSIGNED(6 downto 0) := (others => '0')
    );
END entity;

architecture arch of dht11 is
    signal state : common_state_type := initialize;
begin
    process(clocks.CLK_1M19)
        variable sleep : unsigned(4 downto 0) := (others => '0');
    begin
        if rising_edge(clocks.CLK_1M19) then
            case state is
                when idle =>
                    if enable = '1' then
                        state <= busy;
                        ready <= '0';
                    end if;
                when busy =>
                    sleep := sleep + 1;
                    if sleep = 0 then
                        -- mock some results
                        out_temperature <= "000" & x"F";  -- 15C
                        out_humidity    <= "001" & x"E";  -- 30%
                        -- signal ready
                        state <= idle;
                        ready <= '1';
                    end if;
                when others => state <= idle; ready <= '1';
            end case;
        end if;
    end process;
    -- Keep simulations tidy
    HUM_DAT <= '0';
end arch;