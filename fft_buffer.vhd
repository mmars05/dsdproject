library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fft_buffer is
    Port (
        clk              : in  STD_LOGIC;
        rst              : in  STD_LOGIC;

        -- incoming audio sample stream from i2s/top
        audio_valid      : in  STD_LOGIC;
        audio_sample     : in  STD_LOGIC_VECTOR(23 downto 0);

        -- output sample stream to FFT wrapper
        sample_out       : out STD_LOGIC_VECTOR(23 downto 0);
        sample_valid_out : out STD_LOGIC;
        sample_ready_in  : in  STD_LOGIC
    );
end fft_buffer;

architecture Behavioral of fft_buffer is

    constant FRAME_SIZE : integer := 256;
    constant HOP_SIZE   : integer := 16;

    type ram_type is array (0 to FRAME_SIZE-1) of std_logic_vector(23 downto 0);
    signal sample_mem : ram_type := (others => (others => '0'));

    signal wr_ptr : integer range 0 to FRAME_SIZE-1 := 0;
    signal samples_collected : integer range 0 to FRAME_SIZE := 0;
    signal hop_count : integer range 0 to HOP_SIZE := 0;

    signal sending          : std_logic := '0';
    signal send_count       : integer range 0 to FRAME_SIZE := 0;
    signal current_read_idx : integer range 0 to FRAME_SIZE-1 := 0;

begin

    process(clk)
        variable next_wr_ptr       : integer range 0 to FRAME_SIZE-1;
        variable oldest_sample_idx : integer range 0 to FRAME_SIZE-1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wr_ptr            <= 0;
                samples_collected <= 0;
                hop_count         <= 0;
                sending           <= '0';
                send_count        <= 0;
                current_read_idx  <= 0;
                sample_out        <= (others => '0');
                sample_valid_out  <= '0';

            else
                sample_valid_out <= '0';

                -- write new incoming sample into circular buffer
                if audio_valid = '1' then
                    sample_mem(wr_ptr) <= audio_sample;

                    if wr_ptr = FRAME_SIZE-1 then
                        next_wr_ptr := 0;
                    else
                        next_wr_ptr := wr_ptr + 1;
                    end if;

                    wr_ptr <= next_wr_ptr;

                    if samples_collected < FRAME_SIZE then
                        samples_collected <= samples_collected + 1;
                    end if;

                    if hop_count = HOP_SIZE-1 then
                        hop_count <= 0;

                        if samples_collected = FRAME_SIZE and sending = '0' then
                            sending <= '1';
                            send_count <= 0;

                            oldest_sample_idx := next_wr_ptr;
                            current_read_idx <= oldest_sample_idx;
                        end if;
                    else
                        hop_count <= hop_count + 1;
                    end if;
                end if;

                -- stream current 256-sample window to FFT wrapper
                if sending = '1' then
                    if sample_ready_in = '1' then
                        sample_out       <= sample_mem(current_read_idx);
                        sample_valid_out <= '1';

                        if send_count = FRAME_SIZE-1 then
                            sending    <= '0';
                            send_count <= 0;
                        else
                            send_count <= send_count + 1;

                            if current_read_idx = FRAME_SIZE-1 then
                                current_read_idx <= 0;
                            else
                                current_read_idx <= current_read_idx + 1;
                            end if;
                        end if;
                    end if;
                end if;

            end if;
        end if;
    end process;

end Behavioral;