import math, cmath
import numpy as np
import matplotlib.pyplot as plt # library for plotting
from signalgenalt import sine_wave_alt # import the function

def fixedpoint18(a):
    afx = float.hex(a)
    print(afx)
    afxstr = str(afx)
    print(afxstr)
    if (afxstr[0]=='-'):
        sign = -1
    else:
        sign = 1
    print(sign)

    i = afxstr.index('p')
    #print(i)
    p = int(afxstr[i+2:len(afxstr)])
    #print(p)

    if (a == 0) or (p >= 9):
        result = 0
    else:
        if (a == 1):
            result = 1 << 10
        else:
            if (a == -1):
                result = 0x3fc00
        
            else:
        
                pt = afxstr.index('.')
                mantissa = afxstr[pt+1:pt+4]
                #print(mantissa)

                ftptmantissa = int(mantissa, 16) + 2**12
                #print(ftptmantissa)
                ftptmantissaadj = ftptmantissa >> int(p)
                #print(hex(ftptmantissaadj))

                result = ftptmantissa >> 3
                #print(hex(result))

                if (sign == -1):
                    #print(hex(result))
                    result = ~result + 1 # 2s complement
                    #print(hex(result))
    
    #print(hex(result))
    mask = 0x3FFFF
    result = result & mask
    return result

fixedptfile = open('routfile.txt','w')

# create sum of two sine waves
fs = 100 # sampling frequency in Hz
nsamples = 64
A = 1 #attenuation factor

#signal 1
f1 = 10 #frequency = 10 Hz
phase1 = 0 #1/3*np.pi #phase shift in radians
 # desired number of cycles of the sine wave
(t1,x1) = sine_wave_alt(f1,fs,phase1,nsamples) #function call

#signal 2
f2 = 40 #frequency = 10 Hz
phase2 = 0 #1/3*np.pi #phase shift in radians
(t2,x2) = sine_wave_alt(f2,fs,phase2,nsamples) #function call

#signal 3
#f3 = 30 #frequency = 10 Hz
#phase3 = 0 #1/3*np.pi #phase shift in radians
#(t3,x3) = sine_wave_alt(f3,fs,phase3,nsamples) #function call
x = A*(x1+x2)  #manually adjust as necessary

for i in range(0,len(x)):
    print(i,x[i])
    if (abs(x[i])<float(1/2**10)):
        x[i]=0.0
    afx = fixedpoint18(x[i])
    afxstr = '{:05x}'.format(afx) + '\n'
    fixedptfile.write(afxstr)

fixedptfile.close()
  
#plt.plot(t,x) # plot using pyplot library from matplotlib package
#plt.title('Sine wave f='+str(f)+' Hz') # plot title
#plt.xlabel('Time (s)') # x-axis label
#plt.ylabel('Amplitude') # y-axis label
#plt.show() # display the figure  



