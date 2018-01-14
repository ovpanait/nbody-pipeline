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
		
		-- uart transmitter
		uart_out:   	  	out unsigned(BYTES_N - 1 downto 0); -- byte to transmit
		uart_out_start: 	out std_logic; -- start transmitting
		uart_out_done:  	in std_logic; -- byte sent

		-- uart receiver
		uart_in_data:	  	in unsigned(BYTES_N - 1 downto 0); --received data		
		uart_in_flag: 		in std_logic -- byte received
		);
end nbody;
		
architecture arch of nbody is
-----------------------------------------------------------------------------------
-- ***************************** Math processor ***********************************
----------------------------------------------------------------------------------
signal rx_a, rx_b, ry_a, ry_b:	unsigned(DATA_W - 1 downto 0);
signal start:	std_logic;

-- 5 stage pipeline for calculating (rx_b - rx_a) ^ 2 + (ry_b - ry_a) ^ 2
signal diff_x:	   unsigned(DATA_W - 1 downto 0);
signal diff_y:	   unsigned(DATA_W - 1 downto 0);

signal diff_x_sq:	unsigned(DATA_W - 1 downto 0);
signal diff_y_sq:	unsigned(DATA_W - 1 downto 0);

signal r:			unsigned(DATA_W - 1 downto 0);

signal r_sq:		unsigned(DATA_W - 1 downto 0);
signal r_buf:		unsigned(DATA_W - 1 downto 0);

signal r_cube:		unsigned(DATA_W - 1 downto 0);

-- 4 stage pipeline FAST INVERSE SQUARE ROOT
signal x:				unsigned(DATA_W - 1 downto 0);	
signal in_half:		unsigned(DATA_W - 1 downto 0);

signal x_sq:			unsigned(DATA_W - 1 downto 0);
signal x_half_x:		unsigned(DATA_W - 1 downto 0);
signal x_1_5:			unsigned(DATA_W - 1 downto 0);

signal x_sqMx_half_x:	unsigned(DATA_W - 1 downto 0);
signal x_1_5b:				unsigned(DATA_W -1 downto 0);

signal en_out9:	std_logic;
signal fisr_res:	unsigned(DATA_W - 1 downto 0);

-- enable signals
signal en_vec:		std_logic_vector(9 downto 1);
begin		
----------------------------------------------------------------------------------
--****************************** UART *****************************************
----------------------------------------------------------------------------------
	uart_input:	work.uart_in_fsm
		port map(clk, reset, uart_in_data, uart_in_flag, rx_a, rx_b, ry_a, ry_b, start);

	uart_output: work.uart_out_fsm
		port map(clk, reset, uart_out, uart_out_start, uart_out_done, fisr_res, en_vec(9));
-----------------------------------------------------------------------------------
-- ***************************** Math processor ***********************************
-----------------------------------------------------------------------------------
	-- 5 stage pipeline to calculate ((rx_a - rx_b)**2 + (ry_a -ry_b)**2)**3
	-- calculate (rx_a - rx_b) and (ry_a - ry_b)
	r_stage1: work.r_st1
		port map(clk, reset, start, 
		rx_a, 
		rx_b,
		ry_a,
		ry_b,
		diff_x, diff_y, en_vec(1));
	
	-- calculate diffx ** 2 + diffy ** 2
	r_stage2: work.r_st2
		port map(clk, reset,en_vec(1), diff_x, diff_y, diff_x_sq, diff_y_sq, en_vec(2)); 
	
	-- calculate r
	r_stage3: work.r_st3
		port map(clk, reset, en_vec(2), diff_x_sq, diff_y_sq, r, en_vec(3));
	
	-- calculate r**2
	r_stage4: work.r_st4
		port map(clk, reset, en_vec(3), r, r_buf, r_sq, en_vec(4));
	
	-- calculate r**3
	r_stage5: work.r_st5
		port map(clk, reset, en_vec(4), r_buf, r_sq, r_cube, en_vec(5));

	-- 4-stage pipelined fst inverse squared root
	fast_isq1: work.fast_isq_st1
		port map(clk, reset, en_vec(5), r_cube, x, in_half, en_vec(6));
	
	fast_isq2: work.fast_isq_st2
		port map(clk, reset, en_vec(6), x, in_half, x_sq, x_half_x, x_1_5, en_vec(7));
	
	fast_isq3: work.fast_isq_st3
		port map(clk, reset, en_vec(7), x_sq, x_half_x, x_1_5, x_sqMx_half_x, x_1_5b, en_vec(8));
	
	fast_isq4: work.fast_isq_st4
		port map(clk, reset, en_vec(8), x_1_5b, x_sqMx_half_x, fisr_res, en_vec(9));
end arch;