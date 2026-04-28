library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fft_manager is
    Port (
        clk          : in  STD_LOGIC;                     -- Fast System Clock (100MHz)
        sample_valid : in  STD_LOGIC;                     -- Pulse from I2S when sample is ready
        sample_in    : in  STD_LOGIC_VECTOR(23 downto 0); -- Data from I2S
        
        -- AXI-Stream Interface to Xilinx FFT IP
        fft_tready   : in  STD_LOGIC;
        fft_tdata    : out STD_LOGIC_VECTOR(63 downto 0); -- Real + Imaginary
        fft_tvalid   : out STD_LOGIC;
        fft_tlast    : out STD_LOGIC
    );
end fft_manager;

architecture Behavioral of fft_manager is
    -- Internal "Array" (Block RAM)
    type ram_type is array (0 to 1023) of std_logic_vector(23 downto 0);
    signal audio_buffer : ram_type := (others => (others => '0'));
    
    signal wr_ptr : unsigned(9 downto 0) := (others => '0');
    signal rd_ptr : unsigned(9 downto 0) := (others => '0');
    
    type state_type is (IDLE, SENDING);
    signal state : state_type := IDLE;

begin

    -- PROCESS 1: FILL THE ARRAY (The "Collection")
    capture_proc: process(clk)
    begin
        if rising_edge(clk) then
            if sample_valid = '1' then
                audio_buffer(to_integer(wr_ptr)) <= sample_in;
                wr_ptr <= wr_ptr + 1;
            end if;
        end if;
    end process;

    -- PROCESS 2: SEND TO FFT (The "Handoff")
    stream_proc: process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    fft_tvalid <= '0';
                    fft_tlast  <= '0';
                    -- Start sending when the write pointer has looped back
                    if wr_ptr = 0 and sample_valid = '1' then 
                        state <= SENDING;
                        rd_ptr <= (others => '0');
                    end if;

                when SENDING =>
                    if fft_tready = '1' then
                        fft_tvalid <= '1';
                        -- FFT IP expects [Imaginary(31:0) & Real(31:0)]
                        -- We pad our 24-bit audio to 32 bits and set Imaginary to 0
                        fft_tdata <= (others => '0'); -- Clear all bits
                        fft_tdata(23 downto 0) <= audio_buffer(to_integer(rd_ptr));
                        
                        if rd_ptr = 255 then
                            fft_tlast <= '1'; -- Signal last sample in the block
                            state <= IDLE;
                        else
                            rd_ptr <= rd_ptr + 1;
                        end if;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
