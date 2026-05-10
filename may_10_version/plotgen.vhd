library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.fft_types_pkg.ALL;

--This one is basically just tracking our column and row and sending out R/G/B colors accordingly. This also should take the magnitude
--We are using an approximation

entity plotgen is
    port(
        row, col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        data : IN fft_bin_array_t
    );
end plotgen;

architecture Behavioral of plotgen is
signal re_s, im_s : signed(23 downto 0);
signal re_abs, im_abs : signed(23 downto 0);
signal mag_approx : unsigned(23 downto 0);
signal index : integer;
signal col_offset : unsigned (10 downto 0);

signal output_red, output_blue, output_green : STD_LOGIC_VECTOR(3 DOWNTO 0);

begin

    
process(col, row, data)
    variable col_offset_v : unsigned(10 downto 0);
    variable index_v      : integer range 0 to 127;
    variable re_s_v       : signed(23 downto 0);
    variable im_s_v       : signed(23 downto 0);
    variable re_abs_v     : signed(23 downto 0);
    variable im_abs_v     : signed(23 downto 0);
    variable mag_v        : unsigned(23 downto 0);
begin
    red   <= (others => '0');
    green <= (others => '0');
    blue  <= (others => '0');

    if (unsigned(col) >= 144) and (unsigned(col) < 656) then
        col_offset_v := unsigned(col) - 144;
        index_v      := to_integer(col_offset_v(10 downto 1));

        re_s_v := signed(data(index_v)(23 downto 0));
        im_s_v := signed(data(index_v)(47 downto 24));

        if re_s_v < 0 then re_abs_v := -re_s_v; else re_abs_v := re_s_v; end if;
        if im_s_v < 0 then im_abs_v := -im_s_v; else im_abs_v := im_s_v; end if;

        if re_abs_v >= im_abs_v then mag_v := unsigned(re_abs_v);
        else mag_v := unsigned(im_abs_v); end if;

        if unsigned(row) >= (599 - mag_v(23 downto 6)) then
            green <= (others => '1');
        end if;
    end if;
end process;

end Behavioral;
