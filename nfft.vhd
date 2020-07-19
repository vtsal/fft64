----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_unsigned.all;

entity nfft is
    generic(
	SIZE: integer:=6;
	WIDTH: integer :=18
	);
    port (
    clk : in std_logic;
	rst : in std_logic;
	start : in std_logic;
	rdin, idin: in std_logic_vector(WIDTH-1 downto 0);
	rdout, idout: out std_logic_vector(WIDTH-1 downto 0);
	di_ready: out std_logic;
	di_valid: in std_logic;
	do_ready: in std_logic;
	do_valid: out std_logic
	);
	
end nfft;

architecture structural of nfft is

type signalarray is array (2**SIZE-1 downto 0) of std_logic;
type signalvectorarray is array (2**SIZE-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);
type halfsignalvectorarray is array (2**(SIZE-1)-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);
type sumarray is array (2**SIZE-1 downto 0) of std_logic_vector(WIDTH*2-1 downto 0);
type halfindexarray is array (2**(SIZE-1)-1 downto 0) of std_logic_vector(2*SIZE-2 downto 0);

constant ZEROES  : std_logic_vector(WIDTH*2-1 downto 0):=(others => '0');
signal eni : signalarray;
signal rqi, iqi : signalvectorarray;
signal rinput, iinput : std_logic_vector(WIDTH-1 downto 0);
signal rprod, iprod, rsum, isum, rregin, iregin : sumarray;
signal rdout36, idout36 : std_logic_vector(WIDTH*2-1 downto 0);
signal enld, ensum, outreginit : std_logic;
signal ldcntr : std_logic_vector(SIZE-1 downto 0);
signal index : halfindexarray;
signal col : std_logic_vector(SIZE-1 downto 0);
signal realcoeff, imagcoeff : halfsignalvectorarray;

begin

-- input register bank
initreg: for i in 0 to 2**SIZE-1 generate

rinreg : entity work.regn(behavioral)
    generic map(
    N => WIDTH
    )
    port map(

        clk => clk,
		en => eni(i),
		d => rdin,
		q => rqi(i)
	);  
iinreg : entity work.regn(behavioral)
    generic map(
    N => WIDTH
    )
    port map(

        clk => clk,
		en => eni(i),
		d => idin,
		q => iqi(i)
	);  

-- decoder

eni(i) <= '1' when ((unsigned(ldcntr) = i) and (enld = '1')) else '0';
	
end generate initreg;  

-- summation and output register bank
outreg: for i in 0 to 2**SIZE-1 generate

routreg : entity work.regn(behavioral)
    generic map(
    N => WIDTH*2
    )
    port map(

        clk => clk,
		en => ensum,
		d => rregin(i),
		q => rsum(i)
	);  
	
rregin(i) <= ZEROES when (outreginit = '1') else
            rsum(i) + rprod(i) when (ldcntr(SIZE-1) = '0')
			else rsum(i) - rprod(i);

ioutreg : entity work.regn(behavioral)
    generic map(
    N => WIDTH*2
    )
    port map(

        clk => clk,
		en => ensum,
		d => iregin(i),
		q => isum(i)
	);  

iregin(i) <= ZEROES when (outreginit = '1') else
             isum(i) + iprod(i) when (ldcntr(SIZE-1) = '0')
			 else isum(i) - iprod(i);

end generate outreg;  

-- single cycle complex multiplier

-- x[n] r component selector
-- inputs are listed in fft bit permutated order
rmult64: if (SIZE = 6) generate

		with col select
		rinput <= rqi(0) when "000000",
    		    rqi(32) when "000001",
				rqi(16) when "000010",
				rqi(48) when "000011",
				rqi(8) when "000100",
				rqi(40) when "000101",
				rqi(24) when "000110",
				rqi(56) when "000111",
                rqi(4) when "001000",
    		    rqi(36) when "001001",
				rqi(20) when "001010",
				rqi(52) when "001011",
				rqi(12) when "001100",
				rqi(44) when "001101",
				rqi(28) when "001110",
				rqi(60) when "001111",
                rqi(2) when "010000",
    		    rqi(34) when "010001",
				rqi(18) when "010010",
				rqi(50) when "010011",
				rqi(10) when "010100",
				rqi(42) when "010101",
				rqi(26) when "010110",
				rqi(58) when "010111",
                rqi(6) when "011000",
    		    rqi(38) when "011001",
				rqi(22) when "011010",
				rqi(54) when "011011",
				rqi(14) when "011100",
				rqi(46) when "011101",
				rqi(30) when "011110",
				rqi(62) when "011111",
				rqi(1) when "100000",
    		    rqi(33) when "100001",
				rqi(17) when "100010",
				rqi(49) when "100011",
				rqi(9) when "100100",
				rqi(41) when "100101",
				rqi(25) when "100110",
				rqi(57) when "100111",
                rqi(5) when "101000",
    		    rqi(37) when "101001",
				rqi(21) when "101010",
				rqi(53) when "101011",
				rqi(13) when "101100",
				rqi(45) when "101101",
				rqi(29) when "101110",
				rqi(61) when "101111",
                rqi(3) when "110000",
    		    rqi(35) when "110001",
				rqi(19) when "110010",
				rqi(51) when "110011",
				rqi(11) when "110100",
				rqi(43) when "110101",
				rqi(27) when "110110",
				rqi(59) when "110111",
                rqi(7) when "111000",
    		    rqi(39) when "111001",
				rqi(23) when "111010",
				rqi(55) when "111011",
				rqi(15) when "111100",
				rqi(47) when "111101",
				rqi(31) when "111110",
				rqi(63) when "111111",
				rqi(0) when others;

end generate rmult64;

-- x[n] i component selector
-- inputs are listed in fft bit permutated order
imult64: if (SIZE = 6) generate

		with col select
		iinput <= iqi(0) when "000000",
    		    iqi(32) when "000001",
				iqi(16) when "000010",
				iqi(48) when "000011",
				iqi(8) when "000100",
				iqi(40) when "000101",
				iqi(24) when "000110",
				iqi(56) when "000111",
                iqi(4) when "001000",
    		    iqi(36) when "001001",
				iqi(20) when "001010",
				iqi(52) when "001011",
				iqi(12) when "001100",
				iqi(44) when "001101",
				iqi(28) when "001110",
				iqi(60) when "001111",
                iqi(2) when "010000",
    		    iqi(34) when "010001",
				iqi(18) when "010010",
				iqi(50) when "010011",
				iqi(10) when "010100",
				iqi(42) when "010101",
				iqi(26) when "010110",
				iqi(58) when "010111",
                iqi(6) when "011000",
    		    iqi(38) when "011001",
				iqi(22) when "011010",
				iqi(54) when "011011",
				iqi(14) when "011100",
				iqi(46) when "011101",
				iqi(30) when "011110",
				iqi(62) when "011111",
				iqi(1) when "100000",
    		    iqi(33) when "100001",
				iqi(17) when "100010",
				iqi(49) when "100011",
				iqi(9) when "100100",
				iqi(41) when "100101",
				iqi(25) when "100110",
				iqi(57) when "100111",
                iqi(5) when "101000",
    		    iqi(37) when "101001",
				iqi(21) when "101010",
				iqi(53) when "101011",
				iqi(13) when "101100",
				iqi(45) when "101101",
				iqi(29) when "101110",
				iqi(61) when "101111",
                iqi(3) when "110000",
    		    iqi(35) when "110001",
				iqi(19) when "110010",
				iqi(51) when "110011",
				iqi(11) when "110100",
				iqi(43) when "110101",
				iqi(27) when "110110",
				iqi(59) when "110111",
                iqi(7) when "111000",
    		    iqi(39) when "111001",
				iqi(23) when "111010",
				iqi(55) when "111011",
				iqi(15) when "111100",
				iqi(47) when "111101",
				iqi(31) when "111110",
				iqi(63) when "111111",
				iqi(0) when others;

end generate imult64;

cmultgen: for i in 0 to 2**(SIZE-1)-1 generate

-- only half of multiplications are performed in fft
-- top
rprod(i) <= std_logic_vector(signed(rinput)*signed(realcoeff(i))-signed(iinput)*signed(imagcoeff(i)));
iprod(i) <= std_logic_vector(signed(rinput)*signed(imagcoeff(i))+signed(iinput)*signed(realcoeff(i)));

--bottom
rprod(2**(SIZE-1)+i) <= rprod(i);
iprod(2**(SIZE-1)+i) <= iprod(i);

end generate cmultgen;

-- output layer

-- reduce from 36 bit signed accumulation to fixedpoint18
-- this keeps the sign bit, lower 7 integer bits, and upper 10 fractional bits

rdout <= rdout36(35) & rdout36(26 downto 10);
idout <= idout36(35) & idout36(26 downto 10);

fft64: if (SIZE = 6) generate

		with ldcntr select
		rdout36 <= rsum(0) when "000000",
    		    rsum(1) when "000001",
				rsum(2) when "000010",
				rsum(3) when "000011",
				rsum(4) when "000100",
				rsum(5) when "000101",
				rsum(6) when "000110",
				rsum(7) when "000111",
                rsum(8+0) when "001000",
    		    rsum(8+1) when "001001",
				rsum(8+2) when "001010",
				rsum(8+3) when "001011",
				rsum(8+4) when "001100",
				rsum(8+5) when "001101",
				rsum(8+6) when "001110",
				rsum(8+7) when "001111",
                rsum(16+0) when "010000",
    		    rsum(16+1) when "010001",
				rsum(16+2) when "010010",
				rsum(16+3) when "010011",
				rsum(16+4) when "010100",
				rsum(16+5) when "010101",
				rsum(16+6) when "010110",
				rsum(16+7) when "010111",
                rsum(24+0) when "011000",
    		    rsum(24+1) when "011001",
				rsum(24+2) when "011010",
				rsum(24+3) when "011011",
				rsum(24+4) when "011100",
				rsum(24+5) when "011101",
				rsum(24+6) when "011110",
				rsum(24+7) when "011111",
				rsum(32+0) when "100000",
    		    rsum(32+1) when "100001",
				rsum(32+2) when "100010",
				rsum(32+3) when "100011",
				rsum(32+4) when "100100",
				rsum(32+5) when "100101",
				rsum(32+6) when "100110",
				rsum(32+7) when "100111",
                rsum(40+0) when "101000",
    		    rsum(40+1) when "101001",
				rsum(40+2) when "101010",
				rsum(40+3) when "101011",
				rsum(40+4) when "101100",
				rsum(40+5) when "101101",
				rsum(40+6) when "101110",
				rsum(40+7) when "101111",
                rsum(48+0) when "110000",
    		    rsum(48+1) when "110001",
				rsum(48+2) when "110010",
				rsum(48+3) when "110011",
				rsum(48+4) when "110100",
				rsum(48+5) when "110101",
				rsum(48+6) when "110110",
				rsum(48+7) when "110111",
                rsum(56+0) when "111000",
    		    rsum(56+1) when "111001",
				rsum(56+2) when "111010",
				rsum(56+3) when "111011",
				rsum(56+4) when "111100",
				rsum(56+5) when "111101",
				rsum(56+6) when "111110",
				rsum(56+7) when "111111",
				rsum(0) when others;

		with ldcntr select
		idout36 <= isum(0) when "000000",
    		    isum(1) when "000001",
				isum(2) when "000010",
				isum(3) when "000011",
				isum(4) when "000100",
				isum(5) when "000101",
				isum(6) when "000110",
				isum(7) when "000111",
                isum(8+0) when "001000",
    		    isum(8+1) when "001001",
				isum(8+2) when "001010",
				isum(8+3) when "001011",
				isum(8+4) when "001100",
				isum(8+5) when "001101",
				isum(8+6) when "001110",
				isum(8+7) when "001111",
                isum(16+0) when "010000",
    		    isum(16+1) when "010001",
				isum(16+2) when "010010",
				isum(16+3) when "010011",
				isum(16+4) when "010100",
				isum(16+5) when "010101",
				isum(16+6) when "010110",
				isum(16+7) when "010111",
                isum(24+0) when "011000",
    		    isum(24+1) when "011001",
				isum(24+2) when "011010",
				isum(24+3) when "011011",
				isum(24+4) when "011100",
				isum(24+5) when "011101",
				isum(24+6) when "011110",
				isum(24+7) when "011111",
				isum(32+0) when "100000",
    		    isum(32+1) when "100001",
				isum(32+2) when "100010",
				isum(32+3) when "100011",
				isum(32+4) when "100100",
				isum(32+5) when "100101",
				isum(32+6) when "100110",
				isum(32+7) when "100111",
                isum(40+0) when "101000",
    		    isum(40+1) when "101001",
				isum(40+2) when "101010",
				isum(40+3) when "101011",
				isum(40+4) when "101100",
				isum(40+5) when "101101",
				isum(40+6) when "101110",
				isum(40+7) when "101111",
                isum(48+0) when "110000",
    		    isum(48+1) when "110001",
				isum(48+2) when "110010",
				isum(48+3) when "110011",
				isum(48+4) when "110100",
				isum(48+5) when "110101",
				isum(48+6) when "110110",
				isum(48+7) when "110111",
                isum(56+0) when "111000",
    		    isum(56+1) when "111001",
				isum(56+2) when "111010",
				isum(56+3) when "111011",
				isum(56+4) when "111100",
				isum(56+5) when "111101",
				isum(56+6) when "111110",
				isum(56+7) when "111111",
				isum(0) when others;

end generate fft64;

-- 64-point fft coefficients
-- 32 * 64 coefficients are evaluated

coeffgen: for i in 0 to 2**(SIZE-1)-1 generate
    index(i) <= std_logic_vector(to_unsigned(i,SIZE-1)) & col;

realcoeffrom : entity work.realcoeff64(dataflow)
    generic map(
    SIZE => SIZE,
    WIDTH => WIDTH
    )
    port map(
        index => index(i),
		coeff => realcoeff(i)
	);  

imagcoeffrom : entity work.imagcoeff64(dataflow)
    generic map(
    SIZE => SIZE,
    WIDTH => WIDTH
    )
    port map(
        index => index(i),
		coeff => imagcoeff(i)
	);  

end generate coeffgen;

col <= ldcntr;  

ctrl: entity work.controller(behavioral)
    generic map(
		SIZE => SIZE
	)
    port map (
		clk => clk,
		rst => rst,
	    start => start,
	    di_ready => di_ready,
		di_valid => di_valid,
		do_ready => do_ready,
		do_valid => do_valid,
		cntr => ldcntr,
		enld => enld,
		ensum => ensum,
		outreginit => outreginit
        );
	
end structural;