library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    PORT (
        CLK100MHZ : IN STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10 : IN STD_LOGIC
    );
end top;

architecture Behavioral of top is

    signal CLK22MHZ : STD_LOGIC;
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
            clk_22MHZ : out STD_LOGIC
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

begin

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk_wiz_inst : clk_wiz_0
        port map (
            clk_in1   => CLK100MHZ,
            clk_22MHZ => CLK22MHZ
        );

    --------------------------------------------------------------------
    -- I2S audio input
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
    -- Rolling buffer
    --------------------------------------------------------------------
    buffer_inst : entity work.fft_buffer
        port map (
            clk              => CLK22MHZ,
            rst              => '0',
            audio_valid      => sample_done,
            audio_sample     => std_logic_vector(current_sample),
            sample_out       => fft_sample_in,
            sample_valid_out => fft_sample_valid,
            sample_ready_in  => fft_sample_ready
        );

    --------------------------------------------------------------------
    -- FFT wrapper
    --------------------------------------------------------------------
    fft_inst : entity work.fft_wrapper
        port map (
            clk                     => CLK22MHZ,
            rst                     => '0',
            sample_in               => fft_sample_in,
            sample_valid            => fft_sample_valid,
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

end Behavioral;