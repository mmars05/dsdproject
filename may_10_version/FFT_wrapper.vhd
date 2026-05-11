library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_wrapper is
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;  -- active high system reset

    -- input sample stream (44.1kHz rate)
    sample_in       : in  std_logic_vector(23 downto 0);
    sample_valid    : in  std_logic;
    sample_ready    : out std_logic;

    -- FFT output stream
    fft_re_out      : out std_logic_vector(23 downto 0);
    fft_im_out      : out std_logic_vector(23 downto 0);
    fft_valid_out   : out std_logic;
    fft_last_out    : out std_logic;
    fft_ready_in    : in  std_logic;

    -- debug/event outputs
    event_frame_started    : out std_logic;
    event_tlast_unexpected : out std_logic;
    event_tlast_missing    : out std_logic;
    event_status_halt      : out std_logic;
    event_data_in_halt     : out std_logic;
    event_data_out_halt    : out std_logic
  );
end entity;

architecture rtl of fft_wrapper is

    constant FRAME_SIZE : integer := 256;

    -- sample collection buffer
    type sample_buf_t is array(0 to FRAME_SIZE-1) of std_logic_vector(23 downto 0);
    signal sample_buf : sample_buf_t := (others => (others => '0'));

    -- FFT config channel
    signal cfg_tdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_tvalid : std_logic := '0';
    signal cfg_tready : std_logic;

    -- FFT data input channel
    signal s_tdata  : std_logic_vector(47 downto 0) := (others => '0');
    signal s_tvalid : std_logic := '0';
    signal s_tready : std_logic;
    signal s_tlast  : std_logic := '0';

    -- FFT data output channel
    signal m_tdata  : std_logic_vector(47 downto 0);
    signal m_tvalid : std_logic;
    signal m_tlast  : std_logic;

    -- active low reset for FFT IP
    signal fft_aresetn : std_logic := '0';

    -- FSM
    type state_t is (S_RESET, S_CONFIG, S_COLLECT, S_BURST);
    signal state : state_t := S_RESET;

    signal collect_idx : integer range 0 to FRAME_SIZE-1 := 0;
    signal burst_idx   : integer range 0 to FRAME_SIZE-1 := 0;

    type window_rom_t is array(0 to 255) of signed(23 downto 0);
    constant HANNING_ROM : window_rom_t := (
        x"000000",    x"0004F9",    x"0013E4",    x"002CBE",    x"004F83",    x"007C2F",    x"00B2B9",    x"00F31A",
        x"013D48",    x"019136",    x"01EED9",    x"025621",    x"02C6FE",    x"03415F",    x"03C532",    x"045260",
        x"04E8D5",    x"058879",    x"063133",    x"06E2E9",    x"079D7F",    x"0860D9",    x"092CD7",    x"0A015B",
        x"0ADE44",    x"0BC36E",    x"0CB0B6",    x"0DA5F8",    x"0EA30E",    x"0FA7CF",    x"10B414",    x"11C7B2",
        x"12E280",    x"140450",    x"152CF7",    x"165C45",    x"17920C",    x"18CE1B",    x"1A1042",    x"1B584E",
        x"1CA60D",    x"1DF94A",    x"1F51D1",    x"20AF6D",    x"2211E6",    x"237906",    x"24E494",    x"26545A",
        x"27C81D",    x"293FA3",    x"2ABAB3",    x"2C3910",    x"2DBA81",    x"2F3EC9",    x"30C5AB",    x"324EEB",
        x"33DA4C",    x"356790",    x"36F67A",    x"3886CB",    x"3A1846",    x"3BAAAC",    x"3D3DBE",    x"3ED13D",
        x"4064EC",    x"41F88B",    x"438BDC",    x"451EA0",    x"46B098",    x"484185",    x"49D12B",    x"4B5F49",
        x"4CEBA4",    x"4E75FC",    x"4FFE15",    x"5183B1",    x"530695",    x"548684",    x"560342",    x"577C94",
        x"58F240",    x"5A640B",    x"5BD1BC",    x"5D3B1B",    x"5E9FEE",    x"5FFFFF",    x"615B17",    x"62B100",
        x"640184",    x"654C70",    x"669190",    x"67D0B1",    x"6909A3",    x"6A3C33",    x"6B6833",    x"6C8D75",
        x"6DABC9",    x"6EC304",    x"6FD2FB",    x"70DB84",    x"71DC74",    x"72D5A4",    x"73C6EE",    x"74B02C",
        x"75913A",    x"7669F4",    x"773A3A",    x"7801EA",    x"78C0E5",    x"79770F",    x"7A244B",    x"7AC87D",
        x"7B638C",    x"7BF560",    x"7C7DE3",    x"7CFCFF",    x"7D72A1",    x"7DDEB6",    x"7E412D",    x"7E99F7",
        x"7EE907",    x"7F2E50",    x"7F69C6",    x"7F9B62",    x"7FC31C",    x"7FE0EC",    x"7FF4CF",    x"7FFEC1",
        x"7FFEC1",    x"7FF4CF",    x"7FE0EC",    x"7FC31C",    x"7F9B62",    x"7F69C6",    x"7F2E50",    x"7EE907",
        x"7E99F7",    x"7E412D",    x"7DDEB6",    x"7D72A1",    x"7CFCFF",    x"7C7DE3",    x"7BF560",    x"7B638C",
        x"7AC87D",    x"7A244B",    x"79770F",    x"78C0E5",    x"7801EA",    x"773A3A",    x"7669F4",    x"75913A",
        x"74B02C",    x"73C6EE",    x"72D5A4",    x"71DC74",    x"70DB84",    x"6FD2FB",    x"6EC304",    x"6DABC9",
        x"6C8D75",    x"6B6833",    x"6A3C33",    x"6909A3",    x"67D0B1",    x"669190",    x"654C70",    x"640184",
        x"62B100",    x"615B17",    x"5FFFFF",    x"5E9FEE",    x"5D3B1B",    x"5BD1BC",    x"5A640B",    x"58F240",
        x"577C94",    x"560342",    x"548684",    x"530695",    x"5183B1",    x"4FFE15",    x"4E75FC",    x"4CEBA4",
        x"4B5F49",    x"49D12B",    x"484185",    x"46B098",    x"451EA0",    x"438BDC",    x"41F88B",    x"4064EC",
        x"3ED13D",    x"3D3DBE",    x"3BAAAC",    x"3A1846",    x"3886CB",    x"36F67A",    x"356790",    x"33DA4C",
        x"324EEB",    x"30C5AB",    x"2F3EC9",    x"2DBA81",    x"2C3910",    x"2ABAB3",    x"293FA3",    x"27C81D",
        x"26545A",    x"24E494",    x"237906",    x"2211E6",    x"20AF6D",    x"1F51D1",    x"1DF94A",    x"1CA60D",
        x"1B584E",    x"1A1042",    x"18CE1B",    x"17920C",    x"165C45",    x"152CF7",    x"140450",    x"12E280",
        x"11C7B2",    x"10B414",    x"0FA7CF",    x"0EA30E",    x"0DA5F8",    x"0CB0B6",    x"0BC36E",    x"0ADE44",
        x"0A015B",    x"092CD7",    x"0860D9",    x"079D7F",    x"06E2E9",    x"063133",    x"058879",    x"04E8D5",
        x"045260",    x"03C532",    x"03415F",    x"02C6FE",    x"025621",    x"01EED9",    x"019136",    x"013D48",
        x"00F31A",    x"00B2B9",    x"007C2F",    x"004F83",    x"002CBE",    x"0013E4",    x"0004F9",    x"000000"
    );

begin

    u_fft : entity work.xfft_0
        port map (
            aclk                        => clk,
            aresetn                     => fft_aresetn,
            s_axis_config_tdata         => cfg_tdata,
            s_axis_config_tvalid        => cfg_tvalid,
            s_axis_config_tready        => cfg_tready,
            s_axis_data_tdata           => s_tdata,
            s_axis_data_tvalid          => s_tvalid,
            s_axis_data_tready          => s_tready,
            s_axis_data_tlast           => s_tlast,
            m_axis_data_tdata           => m_tdata,
            m_axis_data_tvalid          => m_tvalid,
            m_axis_data_tready          => fft_ready_in,
            m_axis_data_tlast           => m_tlast,
            event_frame_started         => event_frame_started,
            event_tlast_unexpected      => event_tlast_unexpected,
            event_tlast_missing         => event_tlast_missing,
            event_status_channel_halt   => event_status_halt,
            event_data_in_channel_halt  => event_data_in_halt,
            event_data_out_channel_halt => event_data_out_halt
        );

    fft_re_out    <= m_tdata(23 downto 0);
    fft_im_out    <= m_tdata(47 downto 24);
    fft_valid_out <= m_tvalid;
    fft_last_out  <= m_tlast;

    sample_ready <= '1' when state = S_COLLECT else '0';

    process(clk)
    variable windowed : signed(23 downto 0);

    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- assert active-low reset to FFT IP
                fft_aresetn  <= '0';
                cfg_tvalid   <= '0';
                cfg_tdata    <= (others => '0');
                s_tvalid     <= '0';
                s_tlast      <= '0';
                s_tdata      <= (others => '0');
                collect_idx  <= 0;
                burst_idx    <= 0;
                state        <= S_RESET;

            else
                case state is

                    --------------------------------------------------------
                    -- hold FFT in reset for 2 cycles as required by pg109
                    -- then release and wait one more cycle before config
                    --------------------------------------------------------
                    when S_RESET =>
                        fft_aresetn <= '0';
                        state       <= S_CONFIG;

                    --------------------------------------------------------
                    -- release reset, send config word
                    -- wait for config handshake to complete
                    --------------------------------------------------------
                    when S_CONFIG =>
                        fft_aresetn <= '1';  -- release FFT reset
                        cfg_tvalid  <= '1';
                        cfg_tdata   <= (others => '0');  -- forward FFT
                        s_tvalid    <= '0';

                        if cfg_tvalid = '1' and cfg_tready = '1' then
                            cfg_tvalid <= '0';
                            state      <= S_COLLECT;
                        end if;

                    --------------------------------------------------------
                    -- collect 256 samples one at a time at 44.1kHz
                    --------------------------------------------------------
                    when S_COLLECT =>
                        s_tvalid <= '0';
                        s_tlast  <= '0';
                    
                        if sample_valid = '1' then
                            -- multiply sample by window coefficient
                            -- sample is signed 24-bit, coefficient is unsigned 24-bit (0 to 2^23-1)
                            -- product is 48-bit, take top 24 bits to normalize
                            windowed := resize(
                                shift_right(
                                    signed(sample_in) * signed('0' & std_logic_vector(HANNING_ROM(collect_idx))),
                                    23),  -- divide by 2^23 to normalize coefficient scale
                                24);
                    
                            sample_buf(collect_idx) <= std_logic_vector(windowed);
                    
                            if collect_idx = FRAME_SIZE - 1 then
                                collect_idx <= 0;
                                burst_idx   <= 0;
                                state       <= S_BURST;
                            else
                                collect_idx <= collect_idx + 1;
                            end if;
                        end if;

                    --------------------------------------------------------
                    -- burst all 256 samples to FFT at 100MHz
                    -- only advance when FFT asserts s_tready
                    -- tlast asserted with the final sample
                    --------------------------------------------------------
                    when S_BURST =>
                        if s_tready = '1' then
                            s_tdata  <= (47 downto 24 => '0') & sample_buf(burst_idx);
                            s_tvalid <= '1';

                            if burst_idx = FRAME_SIZE - 1 then
                                s_tlast   <= '1';
                                burst_idx <= 0;
                                state     <= S_COLLECT;
                            else
                                s_tlast   <= '0';
                                burst_idx <= burst_idx + 1;
                            end if;
                        end if;

                    when others =>
                        state <= S_RESET;

                end case;
            end if;
        end if;
    end process;

end architecture;
