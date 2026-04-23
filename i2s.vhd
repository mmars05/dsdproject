library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2s is
    PORT(
        CLK22MHZ : IN STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10 : IN STD_LOGIC;
        sample_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        sample_done : OUT STD_LOGIC
        );
end i2s;

architecture I2S_Protocol of i2s is

    TYPE state IS (L_START, L_SAMPLE, R_START, R_SAMPLE, SEND_DATA); --define state tracker
    SIGNAL pr_state : state := L_START; --present state
    
    SIGNAL L_data, R_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL data_comb : unsigned (23 DOWNTO 0);
    SIGNAL data_comb_temp : unsigned (24 DOWNTO 0);

    SIGNAL  bit_count : integer range 0 to 23 := 23;
    
    SIGNAL done : STD_LOGIC;

    SIGNAL SCK_COUNT : UNSIGNED(8 DOWNTO 0) := (others => '0');
    SIGNAL SCK : STD_LOGIC;
begin
    sckGen : process(CLK22MHZ)
    begin
        if rising_edge(CLK22MHZ) THEN
            SCK_COUNT <= SCK_COUNT + 1;
        END IF;
    end process;
    
    JA7 <= CLK22MHZ;
    JA9 <= SCK_COUNT(2);
    SCK <= SCK_COUNT(2);
    JA8 <= SCK_COUNT(8);

    fsm : process(SCK)
    begin
        if rising_edge(SCK) then
            case pr_state is

                when L_START =>
                    done <= '0';
                    bit_count <= 23;
                    pr_state  <= L_SAMPLE;

                when L_SAMPLE =>
                    done <= '0';
                    L_data(bit_count) <= JA10;
                    if bit_count = 0 then
                        pr_state  <= R_START;
                    else
                        bit_count <= bit_count - 1;
                    end if;

                when R_START =>
                    done <= '0';
                    bit_count <= 23;
                    pr_state  <= R_SAMPLE;

                when R_SAMPLE =>
                    done <= '0';
                    R_data(bit_count) <= JA10;
                    if bit_count = 0 then
                        pr_state  <= SEND_DATA;
                    else
                        bit_count <= bit_count - 1;
                    end if;

                when SEND_DATA =>
                    data_comb_temp <= ('0' & unsigned(L_data)) + ('0' & unsigned(R_data));
                    data_comb      <= data_comb_temp(24 downto 1);
                    pr_state       <= L_START;  -- loop back
                    done <= '1';

            end case;
        end if;
    end process;

end I2S_Protocol;
