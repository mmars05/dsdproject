library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.fft_types_pkg.ALL;

entity top is
    PORT (
        CLK100MHZ : IN STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10 : IN STD_LOGIC;
        VGA_red : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- VGA outputs
        VGA_green : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_blue : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC
    );
end top;

architecture Behavioral of top is

    signal CLK22MHZ : STD_LOGIC;
    signal clk_pixel : STD_LOGIC;
    signal current_sample : UNSIGNED(23 downto 0);
    signal sample_done : STD_LOGIC;

    -- buffer -> wrapper signals
    signal fft_sample_in    : STD_LOGIC_VECTOR(23 downto 0);
    signal fft_sample_valid : STD_LOGIC;
    signal fft_sample_ready : STD_LOGIC;

    -- FFT outputs
    signal fft_re_out    : STD_LOGIC_VECTOR(23 downto 0);
    signal fft_im_out    : STD_LOGIC_VECTOR(23 downto 0);
    signal fft_valid_out : STD_LOGIC;
    signal fft_last_out  : STD_LOGIC;
    signal fft_ready_in  : STD_LOGIC := '1';

    -- debug / status
    signal event_frame_started    : STD_LOGIC;
    signal event_tlast_unexpected : STD_LOGIC;
    signal event_tlast_missing    : STD_LOGIC;
    signal event_status_halt      : STD_LOGIC;
    signal event_data_in_halt     : STD_LOGIC;
    signal event_data_out_halt    : STD_LOGIC;

    component clk_wiz_0 is
        port (
            clk_in1   : in  STD_LOGIC;
            clk_22MHZ : out STD_LOGIC;
            pixel_clk : out STD_LOGIC
        );
    end component;

    component i2s is
        port (
            CLK22MHZ    : in  STD_LOGIC;
            JA9, JA8, JA7 : out STD_LOGIC;
            JA10        : in  STD_LOGIC;
            sample_out  : out UNSIGNED(23 downto 0);
            sample_done : out STD_LOGIC
        );
    end component;
    
    component vga_sync IS
	PORT (
		pixel_clk : IN STD_LOGIC;
		red_in    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		green_in  : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		blue_in   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		red_out   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		green_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		blue_out  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		hsync     : OUT STD_LOGIC;
		vsync     : OUT STD_LOGIC;
		pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
		pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
	);
    END component;
    
    SIGNAL input_red, input_blue, input_green : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL S_pixel_row, S_pixel_col : STD_LOGIC_VECTOR (10 DOWNTO 0);
    SIGNAL S_vsync : STD_LOGIC;

    component vga_buffer is
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
    end component;
    
    SIGNAL fft_re, fft_im : STD_LOGIC_VECTOR(23 downto 0);
    SIGNAL fft_valid_in, fft_last_in, fft_frame_done : STD_LOGIC;
    SIGNAL vga_fft_output : fft_bin_array_t;
    
    --fft wrapper component
    component fft_wrapper is
        port (
        clk             : in  std_logic;
        rst             : in  std_logic;
    
        -- input sample stream
        sample_in       : in  std_logic_vector(23 downto 0);
        sample_valid    : in  std_logic;
        sample_ready    : out std_logic;
    
        -- FFT output stream
        fft_re_out      : out std_logic_vector(23 downto 0);
        fft_im_out      : out std_logic_vector(23 downto 0);
        fft_valid_out   : out std_logic;
        fft_last_out    : out std_logic;
        fft_ready_in    : in  std_logic := '1';
    
        -- optional debug/event outputs
        event_frame_started    : out std_logic;
        event_tlast_unexpected : out std_logic;
        event_tlast_missing    : out std_logic;
        event_status_halt      : out std_logic;
        event_data_in_halt     : out std_logic;
        event_data_out_halt    : out std_logic
      );
    end component;

    component plotgen is
        port(
            row, col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            data : IN fft_bin_array_t
        );
    end component;
    
begin
    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk_wiz_inst : clk_wiz_0
        port map (
            clk_in1   => CLK100MHZ,
            clk_22MHZ => CLK22MHZ,
            pixel_clk => clk_pixel
        );

    vga_sync_inst : vga_sync
        port map(
            pixel_clk => clk_pixel,
            red_in => input_red,
            green_in => input_green,
            blue_in => input_blue,
            red_out => VGA_red,
            green_out => VGA_green,
            blue_out => VGA_blue,
            pixel_row => S_pixel_row,
            pixel_col => S_pixel_col,
            hsync => VGA_hsync,
            vsync => VGA_vsync
        );   
    --------------------------------------------------------------------
    -- I2S audio input (current sample --> FFT Wrapper sample in)
    --------------------------------------------------------------------
    i2s_inst : i2s
        port map (
            CLK22MHZ    => CLK22MHZ,
            JA9         => JA9,
            JA8         => JA8,
            JA7         => JA7,
            JA10        => JA10,
            sample_out  => current_sample,
            sample_done => sample_done
        );

    --------------------------------------------------------------------
    -- FFT wrapper (sample_done -> sample valid; fft_re/im_out -> vga_buffer re_out)
    --------------------------------------------------------------------
    fft_inst : fft_wrapper
        port map (
            clk                     => CLK100MHZ,
            rst                     => '0',
            sample_in               => std_logic_vector(current_sample),
            sample_valid            => sample_done,
            sample_ready            => fft_sample_ready,
            fft_re_out              => fft_re_out,
            fft_im_out              => fft_im_out,
            fft_valid_out           => fft_valid_out,
            fft_last_out            => fft_last_out,
            fft_ready_in            => fft_ready_in,
            event_frame_started     => event_frame_started,
            event_tlast_unexpected  => event_tlast_unexpected,
            event_tlast_missing     => event_tlast_missing,
            event_status_halt       => event_status_halt,
            event_data_in_halt      => event_data_in_halt,
            event_data_out_halt     => event_data_out_halt
        );

    --------------------------------------------------------------------
    -- VGA OUTPUT WRAPPER
    --------------------------------------------------------------------
    
    vga_buffer_inst: vga_buffer
        port map(
            clk => CLK100MHZ,
            rst => '0',
            
            fft_re_in => fft_re_out,
            fft_im_in => fft_im_out,
            fft_valid_in => fft_valid_out,
            fft_last_in => fft_last_out,
            
            bin_mem_out => vga_fft_output,
            frame_done => fft_frame_done
        
        );
        
    --------------------------------------------------------------------
    -- plot generator
    --------------------------------------------------------------------
    
    plot_generator : plotgen 
        port map(
            row => S_pixel_row,
            col => S_pixel_col,
            red => input_red,
            green => input_green,
            blue => input_blue,
            data => vga_fft_output
        );
end Behavioral;
