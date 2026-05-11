library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.fft_types_pkg.ALL;

entity vga_buffer is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        -- FFT wrapper outputs
        fft_re_in     : in  STD_LOGIC_VECTOR(23 downto 0);
        fft_im_in     : in  STD_LOGIC_VECTOR(23 downto 0);
        fft_valid_in  : in  STD_LOGIC;
        fft_last_in   : in  STD_LOGIC;
        -- buffered full FFT frame for VGA logic
        bin_mem_out   : out fft_bin_array_t;
        frame_done    : out STD_LOGIC
    );
end vga_buffer;

architecture Behavioral of vga_buffer is
    signal bin_mem   : fft_bin_array_t := (others => (others => '0'));
    signal write_ptr : integer range 0 to 255 := 0;
begin
    process(clk)
        variable re_shifted : unsigned(23 downto 0);
        variable im_shifted : unsigned(23 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bin_mem    <= (others => (others => '0'));
                write_ptr  <= 0;
                frame_done <= '0';
            else
                frame_done <= '0';
                if fft_valid_in = '1' then
                    -- shift right by 6 to discard bottom bits and prevent overflow
                    re_shifted := shift_right(unsigned(fft_re_in), 6)(23 downto 0);
                    im_shifted := shift_right(unsigned(fft_im_in), 6)(23 downto 0);

                    -- pack imag & real into one 48-bit value
                    bin_mem(write_ptr) <= std_logic_vector(im_shifted) & 
                                         std_logic_vector(re_shifted);

                    if fft_last_in = '1' then
                        write_ptr  <= 0;
                        frame_done <= '1';
                    else
                        if write_ptr = 255 then
                            write_ptr <= 0;
                        else
                            write_ptr <= write_ptr + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    bin_mem_out <= bin_mem;
end Behavioral;
