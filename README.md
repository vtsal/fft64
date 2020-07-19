# fft64
VHDL FPGA implementation for 64-point FFT using 18-bit fixed-point arithmetic
64-point FFT using 18-bit fixed point arithmetic with single-cycle complex multiply-accumulates

This project demonstrates a VHDL implementation of a 64-point Fast Fourier Transform (FFT). The goal is, given an N-length input signal x[n] representing a physical signal in the time domain, return an N-length output sequence X[k] representing a transformation of x[n] to the frequency domain. The digital frequency range of X[k] is from theta = 0 to pi radians, or from -pi/2 to pi/2 radians if 0 frequency is centered. The relation of the digital frequency to the physical frequency (Hz) is determined by the sampling rate fs (Hz) at which the signal x[n] was sampled. According to the Shannon-Nyquist theorem, the maximum frequency component which can be recovered at a sampling rate of fs is fs/2. Therefore, theta = pi corresponds to a signal with frequency fs, and theta = pi/2 corresponds to a signal frequency of fs/2. In this demonstration, sine waves are digitally sampled at ts = .01 sec (fs = 100 Hz). Thus an output range of -pi/2 to pi/2 radians in the FFT corresponds to signals from -50 to 50 Hz. Assuming that our input signals are real, we expect to see mirror images of the output spectrum from 0 to 50 Hz and from 0 to -50 Hz.

In this demonstration all input and output products, and computations, are performed in an 18-bit fixed point format. The 18-bit fixed point format is designed to optimize the Xilinx FPGA DSP multiply function, which uses a 25x18 bit input. This demonstration uses a custom rendition of signed 18-bit fixed point format as follows:

<7-bit integer><10-bit fraction>

The python scripts are used to generate the input signal rinfile.txt. As x[n] is considered a complex signal, rinfile.txt represents the real coefficients. The imaginary coefficients, iinfile.txt, are manually set to 0 in this example. To generate the input file, run sinfixedpt.py. This generates a sequence of 64 18-bit (5 hex characters) text file, which represent the summation of two sine waves, one at 10 Hz and one at 40 Hz. Sine wave vectors are computed in floating point and custom-converted by a crude fixed point converter. The resulting file fixedpt.txt should be manually renamed rinfile.txt (iinfile.txt should be manually created to zeroes of the same size).

To compute the 64-point FFT using the Python scipy library, run the dftresult.py script, and uncomment the fft to compute fft(x,NFFT) on the input files 
rinfile.txt and iinfile.txt (this could require renaming the input files in the code). This created the FFT shown in fft64scipy.png.

To simulate generation of the output files routfile.txt and ioutfile.txt, create a Vivado project and add text_tb.vhd, nfft.vhd, regn.vhd, controller.vhd, realcoeff64.vhd, and imagcoeff64.vhd. The FFT complex coefficients have been predefined for N=64, but can be regenerated for any value of N using dftcoeffgen.py. Note that this script formats outputs for use in VHDL in custom 18-bit fixed point (if you are using only the 64-point FFT, this step is not necessary). Set the top module to the text bench (text_tb), and ensure that rinfile.txt and iinfile.txt are in the correct file path. Run the simulation, and collect the output files, routfile.txt, and ioutfile.txt. These files contain the FFT results.

To plot the results, run the dftresult.py script, and note the result. One has been pregenerated in fft64fpga.png.

Structure of the VHDL implementation:

The implementation sequences through 3 phases: 1) initialize input registers from text files; 2) compute FFT; and 3) dump result registers to text files. The N-point FFT completes N/2 complex multiply/accumulates (MAC) in a single clock cycle, and takes N clock cycles to complete, since FFT grows as N log N complexity). One single-cycle complex multiply is observed to require about 4 DSPs in the Xilinx Artix-7 architecture. Pipelined implementations of the complex multiply/accumulate can reduce the number of DSPs, but at the cost of additional latency.

Assumption: This 18-bit fixed point format has limited dynamic range, and does not add bits of precision during accumulates, i.e., intermediate results are always truncated to 18 bits. Therefore, we assume that the accumulated sum will not overflow 7 bits of integer (2^7 = 128) during the calculation. Therefore, input signals should be carefully conditioned to normalize and minimize amplitudes to prevent overflows.

Implementation: This 64-point FFT was implemented for the Nexys-A7 board (Artix-7 100T) at 50 MHz (20 ns clock period). It required 9095 LUTs, 3241 slices, used 128 out of 240 DSPs, and consumed approximately 230 mW. As 32 complex multiply/accumulates are conducted in each clock cycle, this is equivalent to 1.6 GMAC per second.

The FPGA implementation of the FFT is constructed as follows:

Alg: Generate Coefficients C
Initialize C to ones (length N)
for i:=0 to log2(N) -1
	D = 1/2th of complex roots of 1 (in clockwise order)
	x0 | x1 = split(C)
	      x0  D x x1 (top)
	C = [ ...........
          x0 -D x x1 (bot) 
		  
Return "top" coefficients of C in an N/2 x N matrix
	
Alg: Split(C)
If C is an r x c matrix, write C as [C0 | C1 | ... | Cc-1]
Return x0: = [C0 | C2 | ... | Cc-2]
Return x1: = [C1 | C3 | ... | Cc-1]

Example: Let N = 8
C initialized to [1 1 1 1 1 1 1 1]
for i:=0 to 2
	//i = 0//
	D = [1]
	x0 = [1 1 1 1] x1 = [1 1 1 1]
	     1 1 1 1  1  1  1  1
	C = [...................]
       1 1 1 1 -1 -1 -1 -1
		 
	//i = 1//
    D = [1, -j]
    x0 = [ 1 1  1  1]
         [ 1 1 -1 -1]
    x1 = [ 1 1  1  1]
         [ 1 1 -1 -1]
	      
		[ 1  1  1   1  1  1  1  1 ]   
    C = [ 1  1 -1  -1 -j -j  j  j ]
        [ 1  1  1   1 -1 -1 -1 -1 ]
        [ 1	 1 -1  -1  j  j -j -j ]

    //i = 2//
    D = [1, .707 - .707j, -j, -.707 -.707j]
    x0 = [1  1  1  1
	        1 -1 -j  j
		      1  1 -1 -1
		      1 -1  j -j ]
	  x1 = [1  1  1  1 
          1 -1 -j  j
          1  1 -1 -1
          1	-1  j -j ]
  
         1   1    1   1   1              1               1               1                (top)
         1  -1   -j   j   0.707 - 0.707j -0.707 + 0.707j -0.707 - 0.707j 0.707 + 0.707j
         1   1   -1  -1   -j             -j              j               j
         1  -1    j  -j   -0.707 - 0.707j 0.707 + 0.707j 0.707 - 0.707j -0.707 + 0.707j
     C=[ ................................................................................
         1   1    1   1   -1             -1              -1             -1                (bot) 
         1  -1   -j   j   -0.707 + 0.707j 0.707 - 0.707j 0.707 + 0.707j -0.707 - 0.707j
         1   1   -1  -1    j              j              -j             -j
         1  -1    j  -j   0.707 + 0.707j  -0.707 - 0.707j -0.707 + 0.707j 0.707 - 0.707j ]

The 4x8 matrix of the top partition of C will be returned

In the FPGA implementation, the FFT will be calculated using N/2 multipliers per clock cycle as follows:

Real and imaginary coefficients computed off-line are stored in ROM LUT tables.
Partition C into [C0 | C1] such that C0 is an N/2 x N/2 matrix consisting of column subscripts 0 to N/2 - 1,
and C1 is an N/2 x N/2 matrix consisting of column subscripts N/2 to N-1.

Rearrange the input vector x[n] of length(N) according to bit-reversed indices.  E.g., for N = 8 and 
x[n] = [x0, x1, x2, x3, x4, x5, x6, x7], xp[n] = [x0, x4, x2, x6, x1, x5, x3, x7]
Partition the input vector x[n] of length(N) into [x0 | x1], where x0 and x1 are both of length(N/2)

                                [ C0 * x0  + C1 * x1 ] (top)
We are computing the sum of S = [ ...................]
                                [ C0 * x0  - C1 * x1 ] (bottom)

If we compute each columns 0 to N-1 on single clock cycle, there will be N/2 complex-multiply-accumulates (CMACs) per clock cycle in an N-bit FFT,
however, N registers are required to accumulate partial sums for all N points.
