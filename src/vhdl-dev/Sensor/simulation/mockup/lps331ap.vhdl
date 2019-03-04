library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;

entity lps331ap is
    PORT (
        clocks     :  IN t_clocks;
        enable     :  IN STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';

        PRESS_SDA,
        PRESS_SCL  : INOUT STD_LOGIC;
        PRESS_SDO,
        PRESS_CS   :   OUT STD_LOGIC;
        REFERENCE_PRESS :  IN STD_LOGIC_VECTOR(7 downto 0);
        out_temperature : OUT UNSIGNED( 6 downto 0) := (others => '0');
        out_pressure    : OUT UNSIGNED(10 downto 0) := (others => '0')
    );
END entity;

architecture arch of lps331ap is
    signal state : common_state_type := initialize;
begin
    process(clocks.CLK_1M19)
        variable sleep : unsigned(3 downto 0) := (others => '0');
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
                        out_pressure    <= "011" & x"F2"; -- 1010hPa
                        -- signal ready
                        state <= idle;
                        ready <= '1';
                    end if;
                when others => state <= idle; ready <= '1';
            end case;
        end if;
    end process;
    -- Keep simulations tidy
    PRESS_SDO <= '0';
    PRESS_CS <= '0';
    PRESS_SDA <= '0';
    PRESS_SCL <= '0';
end arch;
