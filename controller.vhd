library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity controller is
    generic(
		SIZE: integer:= 8
	);
    PORT ( clk, rst : in std_logic;
	       start: in std_logic;
	       di_ready: out std_logic;
		   di_valid : in std_logic;
		   do_ready : in std_logic;
           do_valid : out std_logic;
		   cntr : out std_logic_vector(SIZE-1 downto 0);
		   enld : out std_logic;
		   ensum : out std_logic;
		   outreginit : out std_logic
		   );
end controller;

architecture behavioral of controller is
    type state is (INIT, LOAD, RUN, DUMP);
    
	constant ZEROES : std_logic_vector(SIZE-1 downto 0):=(others => '0');
	constant MAXCNTR : integer:= 2**SIZE-1;
	signal current_state : state;
    signal next_state : state;
	signal encntr: std_logic;
	signal cntr_signal : std_logic_vector(SIZE-1 downto 0);
		
begin

cntr <= cntr_signal;

sync_process: process(clk)
begin

IF (rising_edge(clk)) THEN
	if (rst = '1') then
		current_state <= INIT;
	else
	   current_state <= next_state;
	END if;
	  
END IF;

end process;

counter_process: process(clk)
begin
	if rising_edge(clk) then
		if (rst = '1') then
			cntr_signal <= ZEROES;
	    end if;
		if (encntr = '1') then
			cntr_signal <= std_logic_vector(unsigned(cntr_signal) + 1);
		end if;
	end if;
end process;

test_process: process(current_state, di_valid, do_ready, cntr_signal, start)
begin
	 -- defaults

di_ready <= '0';
do_valid <= '0';
encntr <= '0';
enld <= '0';
ensum <= '0';
outreginit <= '0';

case current_state is
		 		 
	 when INIT =>
		  if (start = '1') then
			next_state <= LOAD;
		  else
			next_state <= INIT;
		  end if;
        
     when LOAD =>
	    di_ready <= '1';
        if (di_valid = '1') then
            encntr <= '1';
			enld <= '1';
			ensum <= '1';
			outreginit <= '1'; -- this is clearing each accumulation register
            if (cntr_signal = MAXCNTR) then
				next_state <= RUN;
			else
				next_state <= LOAD;
			end if;
		end if;
		
	  when RUN =>
	     encntr <= '1';
	     ensum <= '1';
	     if (cntr_signal = MAXCNTR) then
	        next_state <= DUMP;
	     else
		    next_state <= RUN;
		 end if;
	
	  when DUMP =>
		 do_valid <= '1';
		 if (do_ready = '1') then
			encntr <= '1';
			if (cntr_signal = MAXCNTR) then
				next_state <= INIT;
			else
				next_state <= DUMP;
			end if;
		end if;

	WHEN OTHERS =>
	
		  next_state <= INIT;
			  
	end case; 

END process;
		
END behavioral; 
