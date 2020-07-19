import math, cmath
import numpy as np
import matplotlib.pyplot as plt # library for plotting
from signalgenalt import sine_wave_alt # import the function
from scipy.fftpack import fft, fftshift
from scipy.signal import convolve

def fixpt18tofloat(a):
# takes signed fixedpoint 18, returns float or arbitrary precision    
    
    mask = 0x3FFFF
    signbit = int(a/2**17) # equal to 1 or zero
    #print(signbit)
    if (signbit == 1):
        #print('neg')
        sign = -1
        a = ~a + 1 # 2s complement
        a = a & mask # truncate to 18 bits
    else:
        sign = 1
    result = float(a/2**10) * sign
    return result

fs = 100 # 100 Hz    
rfile = open('routfile.txt','r')
ifile = open('ioutfile.txt','r')

rstr = rfile.readline()
istr = ifile.readline()

NFFT=64
x = []
for i in range (0, NFFT):
    x.append(0)

i = 0

while (rstr != ""):
    ar = int(rstr,16)
    arfp = fixpt18tofloat(ar)
    ai = int(istr,16)
    aifp = fixpt18tofloat(ai)
    #x.real[i] = arfp # substitutes converted fixed point 18 values using same time base
    #x.imag[i] = aifp # substitutes converted fixed point 18 values using same time base
    x[i] = arfp + 1j * aifp
    i = i + 1
    rstr = rfile.readline()
    istr = ifile.readline()

rfile.close()
ifile.close()
        
#plt.plot(t,x) # plot using pyplot library from matplotlib package
#plt.title('Sine wave f='+str(f)+' Hz') # plot title
#plt.xlabel('Time (s)') # x-axis label
#plt.ylabel('Amplitude') # y-axis label
#plt.show() # display the figure 

#y = x[0:NFFT-1]

#X=fftshift(fft(x,NFFT))  #uncomment if you are reading input data not yet passed through FFT
X=fftshift(x)  #use this if processing post-processed FFT input
 
#plt.subplots(nrows=1, ncols=1) #create figure handle
 
fVals=np.arange(start = -NFFT/2,stop = NFFT/2)*fs/NFFT
plt.plot(fVals,np.abs(X),'b')
plt.title('Double Sided FFT - with FFTShift')
plt.xlabel('Frequency (Hz)')
plt.ylabel('|DFT Values|')
plt.xlim(-fs/2,fs/2)
plt.xticks(np.arange(-fs/2, fs/2+1,fs/5))
plt.show()

