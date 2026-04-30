library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.arrayPackage.ALL;

entity top is
    PORT (
        CLK100MHZ : IN STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10 : IN STD_LOGIC
        );
end top;

architecture Behavioral of top is
SIGNAL MCLK : STD_LOGIC;
SIGNAL SCLK : STD_LOGIC;
SIGNAL CLK22MHZ : STD_LOGIC;
SIGNAL current_sample : STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL sample_done : STD_LOGIC;

SIGNAL dataArr : signed_array := (others => 0);

component clk_wiz_0 is
    PORT(
        clk_in1 : IN STD_LOGIC;
        clk_22MHZ: OUT STD_LOGIC
        );
end component;

component i2s is
    PORT(
        CLK22MHZ : IN STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10 : IN STD_LOGIC;
        sample_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        sample_done : OUT STD_LOGIC
        );
end component;

begin
    clk_wiz : clk_wiz_0
    port map(
        clk_in1 => CLK100MHZ,
        clk_22MHZ => CLK22MHZ
        );
    
    i2s_imp : i2s
    port map(
        CLK22MHZ => CLK22MHZ,
        JA9 => JA9,
        JA8 => JA8,
        JA7 => JA7,
        JA10 => JA10,
        sample_out => current_sample,
        sample_done => sample_done
        );

    sampleProcess : process(sample_done)
    begin
        IF rising_edge(sample_done) THEN
            FOR i in 255 DOWNTO 0 LOOP
                IF i < 255 THEN --shift all the way
                    dataArr(i+1) <= dataArr(i);
                ELSE    --once shifting is done, initialize new sample to (0)
                    dataArr(0) <= TO_INTEGER(unsigned(current_sample));
                END IF;
            END LOOP;
            
        END IF;
    end process;

end Behavioral;
