library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_wrapper is
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
    fft_ready_in    : in  std_logic;

    -- optional debug/event outputs
    event_frame_started    : out std_logic;
    event_tlast_unexpected : out std_logic;
    event_tlast_missing    : out std_logic;
    event_status_halt      : out std_logic;
    event_data_in_halt     : out std_logic;
    event_data_out_halt    : out std_logic
  );
end entity;

architecture rtl of fft_wrapper is

  constant FRAME_SIZE : integer := 1024;

  -- FFT config channel
  signal cfg_tdata  : std_logic_vector(23 downto 0) := (others => '0');
  signal cfg_tvalid : std_logic := '0';
  signal cfg_tready : std_logic;

  -- FFT data input channel
  signal s_tdata    : std_logic_vector(47 downto 0) := (others => '0');
  signal s_tvalid   : std_logic := '0';
  signal s_tready   : std_logic;
  signal s_tlast    : std_logic := '0';

  -- FFT data output channel
  signal m_tdata    : std_logic_vector(47 downto 0);
  signal m_tvalid   : std_logic;
  signal m_tlast    : std_logic;

  -- frame/sample counter
  signal sample_count : integer range 0 to FRAME_SIZE-1 := 0;

  -- config sent once after reset
  signal config_done : std_logic := '0';

begin

  --------------------------------------------------------------------------
  -- FFT core instance
  --------------------------------------------------------------------------
  u_fft : entity work.xfft_0
    port map (
      aclk                    => clk,
      s_axis_config_tdata     => cfg_tdata,
      s_axis_config_tvalid    => cfg_tvalid,
      s_axis_config_tready    => cfg_tready,
      s_axis_data_tdata       => s_tdata,
      s_axis_data_tvalid      => s_tvalid,
      s_axis_data_tready      => s_tready,
      s_axis_data_tlast       => s_tlast,
      m_axis_data_tdata       => m_tdata,
      m_axis_data_tvalid      => m_tvalid,
      m_axis_data_tready      => fft_ready_in,
      m_axis_data_tlast       => m_tlast,
      event_frame_started     => event_frame_started,
      event_tlast_unexpected  => event_tlast_unexpected,
      event_tlast_missing     => event_tlast_missing,
      event_status_channel_halt => event_status_halt,
      event_data_in_channel_halt => event_data_in_halt,
      event_data_out_channel_halt => event_data_out_halt
    );

  --------------------------------------------------------------------------
  -- sample ready:
  -- only accept samples after config has been sent and when FFT is ready
  --------------------------------------------------------------------------
  sample_ready <= s_tready when config_done = '1' else '0';

  --------------------------------------------------------------------------
  -- output unpacking
  -- Assumption here: m_tdata = imag(47:24) & real(23:0)
  -- If your core uses the opposite order, swap these two lines.
  --------------------------------------------------------------------------
  fft_re_out    <= m_tdata(23 downto 0);
  fft_im_out    <= m_tdata(47 downto 24);
  fft_valid_out <= m_tvalid;
  fft_last_out  <= m_tlast;

  --------------------------------------------------------------------------
  -- main control process
  --------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cfg_tdata     <= (others => '0');
        cfg_tvalid    <= '0';
        config_done   <= '0';

        s_tdata       <= (others => '0');
        s_tvalid      <= '0';
        s_tlast       <= '0';
        sample_count  <= 0;

      else
        --------------------------------------------------------------------
        -- Send config once after reset.
        -- For this first version, config word is all 0s.
        -- If your professor/team later wants a specific runtime config,
        -- this is the place to change it.
        --------------------------------------------------------------------
        if config_done = '0' then
          cfg_tvalid <= '1';

          if cfg_tvalid = '1' and cfg_tready = '1' then
            cfg_tvalid  <= '0';
            config_done <= '1';
          end if;

          -- hold input side idle until config completes
          s_tvalid <= '0';
          s_tlast  <= '0';

        else
          ------------------------------------------------------------------
          -- default: no new transfer unless a valid input handshake happens
          ------------------------------------------------------------------
          s_tvalid <= '0';
          s_tlast  <= '0';

          ------------------------------------------------------------------
          -- accept one sample when source says valid and FFT says ready
          ------------------------------------------------------------------
          if sample_valid = '1' and s_tready = '1' then

            -- Pack complex input.
            -- Assumption: s_tdata = imag(47:24) & real(23:0)
            -- Real input = sample_in, Imag input = 0
            s_tdata  <= (47 downto 24 => '0') & sample_in;
            s_tvalid <= '1';

            if sample_count = FRAME_SIZE - 1 then
              s_tlast      <= '1';
              sample_count <= 0;
            else
              s_tlast      <= '0';
              sample_count <= sample_count + 1;
            end if;

          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;