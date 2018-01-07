library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nbody is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	
	port (
		clk:		in std_logic;
		reset: 	in std_logic;
		
		-- debug and init
		-- uart transmitter
		uart_out:   	  	out unsigned(7 downto 0); -- byte to transmit
		uart_out_start: 	out std_logic; -- start transmitting
		uart_out_done:  	in std_logic; -- byte sent

		-- uart receiver
		uart_in_data:	  	in unsigned(7 downto 0); --received data		
		uart_in_flag: 		in std_logic -- byte received
		);
end nbody;
		
architecture arch of nbody is
-----------------------------------------------------------------------------------
-- ***************************** Math processor ***********************************
----------------------------------------------------------------------------------
signal rx_a, rx_b, ry_a, ry_b:	unsigned(DATA_W - 1 downto 0);
signal start:	std_logic;

signal diff_x:	   unsigned(63 downto 0);
signal diff_y:	   unsigned(63 downto 0);
signal en_out1:	std_logic;

signal diff_x_sq:	unsigned(63 downto 0);
signal diff_y_sq:	unsigned(63 downto 0);
signal en_out2:	std_logic;

signal r:			unsigned(63 downto 0);
signal en_out3:	std_logic;

signal r_sq:		unsigned(63 downto 0);
signal r_buf:		unsigned(63 downto 0);
signal en_out4:	std_logic;

signal r_cube:		unsigned(63 downto 0);
signal en_out5:	std_logic;

signal en_out6:	std_logic;

signal en_out7:	std_logic;

-- fast inv square root - stage 1
signal x:				unsigned(63 downto 0);	
signal in_half:		unsigned(63 downto 0);

-- fast inv square root - stage 2
signal x_sq:			unsigned(63 downto 0);
signal x_half_x:		unsigned(63 downto 0);
signal x_1_5:			unsigned(63 downto 0);

-- fast inv square root - stage 3
signal en_out8:			std_logic;
signal x_sqMx_half_x:	unsigned(63 downto 0);
signal x_1_5b:			unsigned(63 downto 0);
	
-- fast inv square root - stage 4 
signal en_out9:	std_logic;
signal fisr_res:	unsigned(63 downto 0);
begin		
----------------------------------------------------------------------------------
--****************************** UART *****************************************
----------------------------------------------------------------------------------
	uart_in:	work.uart_in_fsm
		port map(clk, reset, uart_in_data, uart_in_flag, rx_a, rx_b, ry_a, ry_b, start);

-----------------------------------------------------------------------------------
-- ***************************** Math processor ***********************************
-----------------------------------------------------------------------------------
	-- 5 stage pipeline to calculate ((rx_a - rx_b)**2 + (ry_a -ry_b)**2)**3
	-- calculate (rx_a - rx_b) and (ry_a - ry_b)
	r_stage1: work.r_st1
		port map(clk, reset, start, 
		rx_a, 
		rx_b ,
		ry_a ,
		ry_b ,
		diff_x => diff_x, diff_y => diff_y, en_out=> en_out1);
	
	-- calculate diffx ** 2 + diffy ** 2
	r_stage2: work.r_st2
		port map(clk, reset,en_out1, diff_x => diff_x, diff_y => diff_y, 
		diff_x_sq => diff_x_sq, diff_y_sq => diff_y_sq, en_out  => en_out2); 
	
	-- calculate r
	r_stage3: work.r_st3
		port map(clk, reset, en_out2, diff_x_sq => diff_x_sq, diff_y_sq => diff_y_sq,
		r => r, en_out => en_out3);
	
	-- calculate r**2
	r_stage4: work.r_st4
		port map(clk, reset, en_out3, r => r, r_buf => r_buf, r_sq => r_sq,
		en_out => en_out4);
	
	-- calculate r**3
	r_stage5: work.r_st5
		port map(clk, reset, en_out4, r => r, r_sq => r_sq, r_cube => r_cube,
		en_out => en_out5);

	-- 4-stage pipelined fst inverse squared root
	fast_isq1: work.fast_isq_st1
		port map(clk, reset, en_out5, input => r_cube, x => x, in_half => in_half,
		en_out => en_out6);
	
	fast_isq2: work.fast_isq_st2
		port map(clk, reset, en_out6, x => x, in_half => in_half, x_sq => x_sq, 
		x_half_x => x_half_x, x_1_5 => x_1_5, en_out => en_out7);
	
	fast_isq3: work.fast_isq_st3
		port map(clk, reset, en_out7, x_sq => x_sq, x_half_x => x_half_x, x_1_5 => x_1_5, 
		x_sqMx_half_x => x_sqMx_half_x, x_1_5_b => x_1_5b, en_out => en_out8);
	
	fast_isq4: work.fast_isq_st4
		port map(clk, reset, en_out8, x_1_5 => x_1_5b, x_sqMx_half_x => x_sqMx_half_x, 
		result => fisr_res, en_out => en_out9);

-----------------------------------------------------------------------------
-- **************************** DEBUG ***************************************
-----------------------------------------------------------------------------
end arch;