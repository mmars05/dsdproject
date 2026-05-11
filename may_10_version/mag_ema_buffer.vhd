library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.fft_types_pkg.ALL;

entity mag_ema_buffer is
    port(
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        frame_done : in  STD_LOGIC;
        bin_in     : in  fft_bin_array_t;
        mag_out    : out mag_array_t
    );
end mag_ema_buffer;

architecture Behavioral of mag_ema_buffer is
    signal smoothed_mag : mag_array_t := (others => (others => '0'));
    signal updating     : std_logic := '0';
    signal update_idx   : integer range 0 to 255 := 0;

begin
    process(clk)
        variable re_v, im_v     : signed(23 downto 0);
        variable re_abs, im_abs : signed(23 downto 0);
        variable raw_mag        : unsigned(23 downto 0);
        variable ema_v          : unsigned(25 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                smoothed_mag <= (others => (others => '0'));
                updating     <= '0';
                update_idx   <= 0;

            else
                if frame_done = '1' then
                    updating   <= '1';
                    update_idx <= 0;
                end if;

                if updating = '1' then
                    re_v := signed(bin_in(update_idx)(23 downto 0));
                    im_v := signed(bin_in(update_idx)(47 downto 24));

                    if re_v < 0 then re_abs := -re_v; else re_abs := re_v; end if;
                    if im_v < 0 then im_abs := -im_v; else im_abs := im_v; end if;

                    if re_abs >= im_abs then raw_mag := unsigned(re_abs);
                    else raw_mag := unsigned(im_abs); end if;

                    -- EMA: 7/8 * old + 1/8 * new with overflow saturation
                    ema_v := resize(unsigned(smoothed_mag(update_idx)), 26)
                           - resize(shift_right(unsigned(smoothed_mag(update_idx)), 4), 26)
                           + resize(shift_right(raw_mag, 4), 26);

                    -- saturate to 24 bits
                    if ema_v(25) = '1' or ema_v(24) = '1' then
                        smoothed_mag(update_idx) <= (others => '1');
                    else
                        smoothed_mag(update_idx) <= std_logic_vector(ema_v(23 downto 0));
                    end if;

                    if update_idx = 255 then
                        updating   <= '0';
                        update_idx <= 0;
                    else
                        update_idx <= update_idx + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    mag_out <= smoothed_mag;
end Behavioral;
