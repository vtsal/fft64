library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity text_tb is

end text_tb;

architecture behavioral of text_tb is

constant period : time:= 10 ns;
constant SIZE : integer:=6;
constant WIDTH : integer:=18;

signal clk, rst : std_logic:='0';
signal di_ready, do_ready, di_valid, do_valid : std_logic;
signal rdin, idin, rdout, idout : std_logic_vector(WIDTH-1 downto 0);
signal start: std_logic:='0';

-- input signals will arrive through these files
FILE rinFile: TEXT OPEN READ_MODE is "rinfile.txt";
FILE iinFile: TEXT OPEN READ_MODE is "iinfile.txt";

-- output DFT will depart through these files
FILE routFile: TEXT OPEN WRITE_MODE is "routfile.txt";
FILE ioutFile: TEXT OPEN WRITE_MODE is "ioutfile.txt";

begin

-- generation of tb clock signal
clk <= not clk after period/2;
do_ready <= '1';

test_process: process
begin
    rst <= '1';
    wait for period * 3;
    rst <= '0';
    start <= '1';
    wait for period;
    start <= '0';
    wait;
		
end process;

rreadVec: PROCESS(clk)

  VARIABLE VectorLine: LINE;
  VARIABLE VectorValid : BOOLEAN;
  VARIABLE x :    STD_LOGIC_VECTOR(19 DOWNTO 0);
  VARIABLE space: CHARACTER;

BEGIN

if (rising_edge(clk)) then
    if (di_ready = '1') then
        if (not endfile(rinFile)) then
            readline(rinFile, VectorLine);
            hread(VectorLine, x, good => VectorValid);
            rdin <= x(WIDTH-1 downto 0);
            di_valid <= '1';
        else 
            di_valid <= '0';
        end if;
     end if;
end if;

ASSERT VectorValid
Report "Vector Not Valid"

SEVERITY ERROR;
--wait for period/2;

end process;

ireadVec: PROCESS(clk)

  VARIABLE VectorLine: LINE;
  VARIABLE VectorValid : BOOLEAN;
  VARIABLE x :    STD_LOGIC_VECTOR(19 DOWNTO 0);
  VARIABLE space: CHARACTER;

BEGIN

if (rising_edge(clk)) then
    if (di_ready = '1') then
        if (not endfile(iinFile)) then
            readline(iinFile, VectorLine);
            hread(VectorLine, x, good => VectorValid);
            idin <= x(WIDTH-1 downto 0);
            di_valid <= '1';
        else 
            di_valid <= '0';
        end if;
     end if;
end if;

ASSERT VectorValid
Report "Vector Not Valid"

SEVERITY ERROR;
--wait for period/2;

end process;

rwriteVec: PROCESS(clk)

   VARIABLE VectorLine: LINE;

BEGIN

 if (rising_edge(clk)) then
        if (do_valid = '1') then
          hwrite(VectorLine, ("00" & rdout));        
          writeline(routFile, VectorLine);
        end if;
end if;

--IF (rising_edge(CLK)) THEN
--	IF (writestrobe = '1') then
--		writeline(outFile, VectorLine);
--	end if;
--end if;

ASSERT False
Report "Writing Result"
SEVERITY NOTE;
--wait for period/2;

end process;

iwriteVec: PROCESS(clk)

   VARIABLE VectorLine: LINE;

BEGIN

 if (rising_edge(clk)) then
        if (do_valid = '1') then
          hwrite(VectorLine, ("00" & idout));        
          writeline(ioutFile, VectorLine);
        end if;
end if;

--IF (rising_edge(CLK)) THEN
--	IF (writestrobe = '1') then
--		writeline(outFile, VectorLine);
--	end if;
--end if;

ASSERT False
Report "Writing Result"
SEVERITY NOTE;
--wait for period/2;

end process;

uut: entity work.nfft(structural)
    generic map(
	SIZE => SIZE,
	WIDTH => wIDTH
	)
    port map(
    clk => clk,
	rst => rst,
	start => start,
	rdin => rdin,
	idin => idin,
	rdout => rdout,
	idout => idout,
	di_ready => di_ready,
	di_valid => di_valid,
	do_ready => do_ready,
	do_valid => do_valid
	);

end behavioral;

