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
- VGA Monitor
- Vivado & Simulation
- VHDL

### System Diagram 
<img width="492" height="218" alt="Screenshot 2026-05-13 092116" src="https://github.com/user-attachments/assets/4d3b3068-f53d-4248-8981-96f9a8e54b5e" />



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
- Week 4: Research FFT IP
- Week 5: VGA Implementation
- Week 6: Filtering and Debugging
- Week 7: Final touch ups 

Conclusively we are satisfied with the turnout of this project and hope that those who read it over learn more about signal processing and FPGA design.
