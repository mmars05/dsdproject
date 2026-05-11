library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2s is
    PORT(
        CLK22MHZ    : IN  STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10        : IN  STD_LOGIC;
        sample_out  : OUT SIGNED(23 DOWNTO 0);
        sample_done : OUT STD_LOGIC
    );
end i2s;

architecture I2S_Protocol of i2s is

    signal SCK_COUNT : UNSIGNED(8 downto 0) := (others => '0');
    signal SCK       : STD_LOGIC;
    signal LRCLK     : STD_LOGIC;
    signal LR_prev   : STD_LOGIC := '0';

    signal L_data    : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal R_data    : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');

    signal bit_count : integer range 0 to 23 := 23;
    signal skip      : STD_LOGIC := '0';

    signal data_comb : SIGNED(23 downto 0) := (others => '0');
    signal done      : STD_LOGIC := '0';

begin

    clk_gen : process(CLK22MHZ)
    begin
        if rising_edge(CLK22MHZ) then
            SCK_COUNT <= SCK_COUNT + 1;
        end if;
    end process;

    SCK   <= SCK_COUNT(2);
    LRCLK <= SCK_COUNT(8);

    JA7 <= CLK22MHZ;
    JA9 <= SCK;
    JA8 <= LRCLK;

    sample_out  <= data_comb;
    sample_done <= done;

    fsm : process(CLK22MHZ)
        variable L_s    : signed(23 downto 0);
        variable R_s    : signed(23 downto 0);
        variable temp_s : signed(24 downto 0);
    begin
        if rising_edge(CLK22MHZ) then
            done <= '0';

            if SCK_COUNT(2 downto 0) = "100" then
                LR_prev <= LRCLK;

                if LR_prev /= LRCLK then
                    skip      <= '1';
                    bit_count <= 23;

                    if LRCLK = '0' then
                        -- treat L and R as signed 24-bit, average them
                        L_s    := signed(L_data);
                        R_s    := signed(R_data);
                        temp_s := resize(L_s, 25) + resize(R_s, 25);
                        -- divide by 2 to get average, keep as signed 24-bit
                        data_comb <= temp_s(24 downto 1);
                        done      <= '1';
                    end if;

                elsif skip = '1' then
                    skip <= '0';

                elsif bit_count > 0 then
                    if LRCLK = '1' then
                        R_data(bit_count) <= JA10;
                    else
                        L_data(bit_count) <= JA10;
                    end if;
                    bit_count <= bit_count - 1;

                else
                    if LRCLK = '1' then
                        R_data(0) <= JA10;
                    else
                        L_data(0) <= JA10;
                    end if;
                end if;
            end if;
        end if;
    end process;

end I2S_Protocol;
