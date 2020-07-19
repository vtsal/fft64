#fftcoeffgen
import numpy as np
import cmath
import math

def splitfunc(x,N):
    xsize = int(N/2)
    #print(np.ndim(x))
    if (np.ndim(x) == 1):
        x0 = np.zeros(xsize,dtype=complex)
        #print(x0)
        x1 = np.zeros(xsize,dtype=complex)
        for i in range (0,xsize):
            #print(i)
            #print(x[i])
            #print(x0[i])
            #print(x[i*2])
            x0[i]=x[i*2]
            x1[i]=x[i*2+1]
	
    else:
        rows = np.shape(x)[0]
        #print(rows)
        x0 = np.zeros([rows,xsize],dtype=complex)
        #print("x0 = ", x0)
        x1 = np.zeros([rows,xsize],dtype=complex)
        #print("x1 = ", x1)
        for i in range (0,xsize):
            #print("i = ",i)
            #print(x)
            #print(x0[...,i])
            #print(x[...,i*2])
            x0[...,i]=x[...,i*2]
            x1[...,i]=x[...,i*2+1]
#    X = np.array(x0,x1)
    return [x0, x1]

def genD(N):
    D = np.zeros(2**N, dtype=complex)
    w = (0-1j)*cmath.pi
    for k in range (0,2**N):
        
        D[k] = cmath.e**(w*k/2**N)
    return D

def fixedpoint18(a):
    afx = float.hex(a)
    #print(afx)
    afxstr = str(afx)
    #print(afxstr)
    if (afxstr[0]=='-'):
        sign = -1
    else:
        sign = 1
    #print(sign)

    i = afxstr.index('p')
    #print(i)
    p = int(afxstr[i+2:len(afxstr)])
    #print(p)

#    if (a == 0) or (p >= 9):
    if (a == 0):

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
    
#initialize
N=6 #2**N point FFT
realfile = open('realfile.txt','w')
imagfile = open('imagfile.txt','w')

# generate 2**N/2 coefficients
x = np.ones(2**N,dtype=complex)
for i in range(0,N):
    #print("i=",i)
    D = genD(i)
    #print("D=",D)
    [x0,x1] = splitfunc(x,2**N)
    #print("x0 = ",x0)
    #print("x0 shape = ",x0.shape)
    #print("x1 = ",x1)
    #print("x1 shape = ",x1.shape)
    x1tD = np.transpose(D*np.transpose(x1))
    #print("x1 * D = ",x1tD)
    v0 = np.hstack((x0,x1tD))
    #print("v0 shape = ",v0.shape)
    v1 = np.hstack((x0,-1*x1tD))
    #print("v1 shape = ",v1.shape)
    #print("v0 = ",v0)
    #print("v1 = ",v1)
    x = np.vstack((v0, v1))
    #print("x = ",x)
    #print("x shape = ",x.shape)

nstr = str(2**N) + ' point FFT coefficients\n'
realfile.write(nstr)
imagfile.write(nstr)
for i in range(0,int(2**N/2)):
    realfile.write('--Row ' + str(i) + '\n') 
    imagfile.write('--Row ' + str(i) + '\n')
    for j in range(0,2**N):
        print(i,j)
        a = v0[i,j].real
        b = v0[i,j].imag
        print(a,b)
        if (abs(a)< float(1/2**10)):
            a = 0.0
        if (abs(b) < float(1/2**10)):
            b = 0.0

        afx = fixedpoint18(a)
        bfx = fixedpoint18(b)
        afxstr = 'x"' + '{:05x}'.format(afx) + '",\n'
        bfxstr = 'x"' + '{:05x}'.format(bfx) + '",\n'
        
        print(afxstr, bfxstr)
        realfile.write(afxstr)
        imagfile.write(bfxstr)
        
        #print('\n')
        
realfile.close()
imagfile.close()
