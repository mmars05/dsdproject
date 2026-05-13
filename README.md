# Fast Fourier Transform - CPE 487 Final 
This GitHub contains a Stevens affiliated design project using hardware description language VHDL. The focus of our final design was to implement a live Fast-Fourier Transform on the Nexus-A7100T FPGA.

*By Zain Choudhry, Matthew Marseglia, and Nick Herrmann* 
## Introduction
For our final project our group chose to work in the signal processing realm and create a live **256 point Fast-Fourier Transform** in order to merge our understand from a course within the electrical engineering ciriculum EE448 to system design in CPE-487.  Ideally our project serves as an educational backing for ourselves as we continue studying signal processing. It also will be for others who may be interested in seeing the importance of a frequency spectrum.  The project allowed us to test our current knowledge of VHDL while also expanding on the concept behind an FFT.  

<img width="2880" height="2160" alt="IMG_5173" src="https://github.com/user-attachments/assets/6290ad85-49ea-4c58-a092-762d0feacd34" />

**What is an FFT?**

The fast-fourier transform is a fundamental mathematical technique used in, but not limited to, signal processing, data analysis and image processing.  The FFT is an algorithm for transforming time-domain data into its frequency-domain representation.  The FFT allows engineers to analyze frequency components of a signal. 

Time-Domain Example:

<img width="556" height="279" alt="Screenshot 2026-05-13 091348" src="https://github.com/user-attachments/assets/7f99de12-6d7c-453a-938e-046a5ce5ec19" />

Corresponding Frequency Domain Example:

<img width="556" height="266" alt="Screenshot 2026-05-13 091503" src="https://github.com/user-attachments/assets/c54b0c3d-ea03-4091-97a7-0ea79cc7eb74" />

The peaks of the frequency domain indicate which frequencies are prevalent within our time domain signal.  The tallest peak in our frequency domain represents the **fundamental frequency** whereas the lower ones often represent unwanted subharmonic frequencies within the same signal. FFT effectiveness is dependent on the sampling frequency, block length and resolution.   Sampling frequency must be twice the highest frequency of interest, otherwise aliasing occurs causing distorted signals.  Larger FFT blocks enable finer resolution allowing for better distinction between closely spaced frequencies at the expense of time and computational power.

**Hardware and Software Used**
- Nexys-A7 FPGA
- FFT IP Core
- I2S PMOD Interface
- Monitor and Cable for VGA
- Vivado & Simulation
- VHDL

### System Diagram 
<img width="492" height="218" alt="Screenshot 2026-05-13 092116" src="https://github.com/user-attachments/assets/4d3b3068-f53d-4248-8981-96f9a8e54b5e" />

# Setup Requirements 

To setup you will need the following items:
- PMod I2S Interface
<img width="357" height="277" alt="Screenshot 2026-05-13 101105" src="https://github.com/user-attachments/assets/ab86744e-3bab-43b7-8147-5dc4e07b2cf9" />

- VGA Connector and Cables
<img width="528" height="331" alt="Screenshot 2026-05-13 101221" src="https://github.com/user-attachments/assets/77974089-6211-4f8c-ba6b-493c8442ef2a" />

- Monitor
<img width="197" height="149" alt="Screenshot 2026-05-13 101457" src="https://github.com/user-attachments/assets/c4256837-7e39-404c-923b-4052b4e20487" />

- Nexys-A7 FPGA
<img width="497" height="346" alt="Screenshot 2026-05-13 101311" src="https://github.com/user-attachments/assets/385e974e-900a-40d2-aefe-ba5410e0e540" />

- 3.3 mm jack for computer audio
<img width="328" height="290" alt="Screenshot 2026-05-13 101400" src="https://github.com/user-attachments/assets/925e1de5-e4d0-4dbe-9211-deea8b009297" />

Once congifured to port JA on Nexys-A7 FPGA you must implement the provided code within this GitHub repository 
# Inputs and Outputs

The inputs and outputs of the FFT for each vhd are as follows:

- **top**

        CLK100MHZ : IN STD_LOGIC;
        JA9, JA8, JA7 : OUT STD_LOGIC;
        JA10 : IN STD_LOGIC;
        VGA_red : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- VGA outputs
        VGA_green : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_blue : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)

end top;
- **I2S**

            CLK22MHZ    : in  STD_LOGIC;
            JA9, JA8, JA7 : out STD_LOGIC;
            JA10        : in  STD_LOGIC;
            sample_out  : out signed(23 downto 0);
            sample_done : out STD_LOGIC

- **FFT_wrapper**
        clk             : in  std_logic;
        rst             : in  std_logic;
  
        sample_in       : in  std_logic_vector(23 downto 0);
        sample_valid    : in  std_logic;
        sample_ready    : out std_logic;
    
        fft_re_out      : out std_logic_vector(23 downto 0);
        fft_im_out      : out std_logic_vector(23 downto 0);
        fft_valid_out   : out std_logic;
        fft_last_out    : out std_logic;
        fft_ready_in    : in  std_logic := '1';
    
        event_frame_started    : out std_logic;
        event_tlast_unexpected : out std_logic;
        event_tlast_missing    : out std_logic;
        event_status_halt      : out std_logic;
        event_data_in_halt     : out std_logic;
        event_data_out_halt    : out std_logic
  
- **vga_buffer**

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
  
- **mag_ema_buffer**

        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        frame_done : in  STD_LOGIC;
        bin_in     : in  fft_bin_array_t;
        mag_out    : out mag_array_t

  
- **vga_sync**

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

- **plotgen**
  
            vsync_plot : IN STD_LOGIC;
            row, col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            data : IN mag_array_t

## Challenges
Our group faced a multitude of difficulties during this project which lead to our final design.  As this project was highly conceptual it took several days of research along with subseqent signal processing studying in order to better understand our system. Here are the main challenges faced:
- Real/Imaginary packing
- Clock synchronization
- Noise in FFT output
- VGA timings


Regardless of these challenges it was important for us to learn how to tackle each aspect.  By iterating through each process as a group it helped to bolster some of our teamwork skills along with FPGA design and VHDL code implementation.  These challenges also helped us to learn more about different the peripheral Pmod I2S as well as the IP Catalog incorporated in Vivado.

## Conclusion
**Responsibilites**
Overall our group believes that we adopted a real-time FFT processing implementation, by taking advantage of the FFT IP nested in Vivado we were able to display our code on a VGA after much simulation and hardware testing.  Some noise was present but overall the frequency peaks were visible indicating that our FFT acted as desired. As for our responsibilities our group attacked each vhd as a joint group in order to increase overall quality and to ask other questions before doing research and committing code before the presentation date.  Here are some generalized responsibilities:

- Nick was responsible for I2S, mag_ema_buffer, top and VGA vhds.  Nick also was responsible for compiling and handling several aspects of the debugging process.
- Matt was responsible for conducting research along with contributing towards the VGA buffer, plotgen, and the GitHub entry
- Zain was responsible for researching the FFT and creating the FFT_Wrapper vhd

Timeline

- Week 1: Research PMOD, FFT, VGA
- Week 2: I2S Implementation 
- Week 3: FFT Wrapper Implemntation 
- Week 4: VGA Implementation
- Week 5: Filtering and Debugging

Conclusively we are satisfied with the turnout of this project and hope that those who read it over learn more about signal processing and FPGA design.
