library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.fft_types_pkg.ALL;

--This one is basically just tracking our column and row and sending out R/G/B colors accordingly. This also should take the magnitude
--We are using an approximation

entity plotgen is
    port(
        vsync_plot : IN STD_LOGIC;
        row, col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        data : IN mag_array_t
    );
end plotgen;

architecture Behavioral of plotgen is
signal index : integer;
signal col_offset : unsigned (10 downto 0);

signal data_sample : mag_array_t;

signal output_red, output_blue, output_green : STD_LOGIC_VECTOR(3 DOWNTO 0);

begin
    
process(vsync_plot)
begin
    if falling_edge(vsync_plot) AND (col = "0" AND row = "0") THEN
        data_sample <= data;
    end if;
end process;

process(col, row, data_sample)
    variable col_offset_v : unsigned(10 downto 0);
    variable index_v      : integer range 0 to 255;
    variable mag_shifted  : unsigned(10 downto 0);
    variable log_mag : unsigned(4 downto 0);

begin
    red   <= (others => '0');
    green <= (others => '0');
    blue  <= (others => '0');

    if (unsigned(col) >= 144) and (unsigned(col) < 656) then
        col_offset_v := unsigned(col) - 144;
        index_v      := to_integer(col_offset_v(10 downto 1));
        mag_shifted  := resize(shift_right(unsigned(data_sample(index_v)), 10), 11);

        if mag_shifted = 0 then
            -- zero magnitude: show red at bottom row only
            if unsigned(row) = 599 then
                red <= (others => '1');
            end if;
        elsif mag_shifted > 599 then
            -- overflow: show blue full height
            blue <= (others => '1');
        else
            -- normal: green bar
            if unsigned(row) >= (to_unsigned(599, 11) - mag_shifted) then
                green <= (others => '1');
            end if;
        end if;
    end if;
end process;

end Behavioral;
