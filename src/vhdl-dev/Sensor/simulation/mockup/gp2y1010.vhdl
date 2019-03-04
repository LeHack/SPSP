library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library utils;
    use utils.utils.all;

entity gp2y1010 is
    PORT (
       clocks     : IN t_clocks;

        enable     : IN  STD_LOGIC := '0';
        ready      : OUT STD_LOGIC := '0';
        output     : OUT UNSIGNED(8 downto 0); -- ug/m3

        ADC_SDAT   : IN STD_LOGIC;
        ADC_SADDR,
        ADC_CS_N,
        ADC_SCLK,
        PM_ILED    : OUT STD_LOGIC
    );
END entity;

architecture arch of gp2y1010 is
    signal state : common_state_type := initialize;
begin
    process(clocks.CLK_1M19)
        variable sleep : unsigned(5 downto 0) := (others => '0');
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
                        output <= "0" & x"23"; -- 35 ug/m3
                        -- signal ready
                        state <= idle;
                        ready <= '1';
                    end if;
                when others => state <= idle; ready <= '1';
            end case;
        end if;
    end process;
    -- Keep simulations tidy
    ADC_SADDR <= '0';
    ADC_CS_N <= '0';
    ADC_SCLK <= '0';
    PM_ILED <= '0';
end arch;
