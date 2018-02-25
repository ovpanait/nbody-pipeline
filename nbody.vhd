library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nbody is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8;
		
		VGA_DW:				integer := 10
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
		uart_in_flag: 		in std_logic; -- byte received
		
		-- VGA signals
		hsync, vsync:   	out std_logic;
		rgb:            	out std_logic_vector(11 downto 0)
		);
end nbody;
		
architecture arch of nbody is
-----------------------------------------------------------------------------------
-- ***************************** Math processor ***********************************
----------------------------------------------------------------------------------
signal rx_a, rx_b, ry_a, ry_b:	unsigned(DATA_W - 1 downto 0);
signal start:	std_logic;

-- 5 stage pipeline for calculating (rx_b - rx_a) ^ 2 + (ry_b - ry_a) ^ 2
signal diff_x:	   		unsigned(DATA_W - 1 downto 0);
signal diff_y:	   		unsigned(DATA_W - 1 downto 0);

signal diff_x_sq:			unsigned(DATA_W - 1 downto 0);
signal diff_y_sq:			unsigned(DATA_W - 1 downto 0);
signal diff_x_buf1:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf1:	   unsigned(DATA_W - 1 downto 0);

signal r:					unsigned(DATA_W - 1 downto 0);
signal diff_x_buf2:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf2:	   unsigned(DATA_W - 1 downto 0);

signal r_sq:				unsigned(DATA_W - 1 downto 0);
signal r_buf:				unsigned(DATA_W - 1 downto 0);
signal diff_x_buf3:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf3:	   unsigned(DATA_W - 1 downto 0);

signal r_cube:				unsigned(DATA_W - 1 downto 0);
signal diff_x_buf4:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf4:	   unsigned(DATA_W - 1 downto 0);

-- 4 stage pipeline FAST INVERSE SQUARE ROOT
signal x:					unsigned(DATA_W - 1 downto 0);	
signal in_half:			unsigned(DATA_W - 1 downto 0);
signal diff_x_buf5:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf5:	   unsigned(DATA_W - 1 downto 0);

signal x_sq:				unsigned(DATA_W - 1 downto 0);
signal x_half_x:			unsigned(DATA_W - 1 downto 0);
signal x_1_5:				unsigned(DATA_W - 1 downto 0);
signal diff_x_buf6:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf6:	   unsigned(DATA_W - 1 downto 0);

signal x_sqMx_half_x:	unsigned(DATA_W - 1 downto 0);
signal x_1_5b:				unsigned(DATA_W -1 downto 0);
signal diff_x_buf7:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf7:	   unsigned(DATA_W - 1 downto 0);

signal fisr_res:			unsigned(DATA_W - 1 downto 0);
signal diff_x_buf8:	   unsigned(DATA_W - 1 downto 0);
signal diff_y_buf8:	   unsigned(DATA_W - 1 downto 0);

-- 1 stage pipeline that calculates fx and fy
signal fx, fy:				unsigned(DATA_W - 1 downto 0);

-- enable signals
signal en_vec:				std_logic_vector(10 downto 1);

-- Particle Controller --
signal p1_new, p2_new, p1_cur, p2_cur:		unsigned(4*DATA_W - 1 downto 0);
signal u_pos1, u_pos2:							unsigned(2*DATA_W - 1 downto 0);
signal vga_ready, vga_start:					std_logic;

type p_buf is array (5 downto 0) of unsigned(4*DATA_W - 1 downto 0);
signal p1_buf, p2_buf:	p_buf;
begin		
----------------------------------------------------------------------------------
--****************************** UART *****************************************
----------------------------------------------------------------------------------
--	uart_input:	work.uart_in_fsm
--		port map(clk, reset, uart_in_data, uart_in_flag, rx_a, rx_b, ry_a, ry_b, start);

	uart_output: work.uart_out_fsm
		port map(clk, reset, uart_out, uart_out_start, uart_out_done, fx, fy, en_vec(10));

---------------------------------------------------------------------------------
-- ***************************** Particle Controller ****************************
---------------------------------------------------------------------------------
	particle_controller: work.grav_controller
		port map(
			clk => clk, 
			reset => reset,
			pipe_din_p1 => p1_new, 
			pipe_din_p2 => p2_new, 
			pipe_done => en_vec(10),
			pipe_dout_p1 => p1_cur,
			pipe_dout_p2 => p2_cur,
			pipe_start => start,
			vga_done => vga_ready,
			vga_dout_p1 => u_pos1, 
			vga_dout_p2 => u_pos2,
			vga_start => vga_start);

-----------------------------------------------------------------------------------
-- *****************************VGA Controller ***********************************
----------------------------------------------------------------------------------
	pixel_generator: work.pixel_gen
		port map(
			clk => clk,
			reset => reset, 
			hsync => hsync, 
			vsync => vsync,
			rgb => rgb, 
			p1 => u_pos1, 
			p2 => u_pos2, 
			start => vga_start, 
			ready => vga_ready);
-----------------------------------------------------------------------------------
-- ***************************** Math processor ***********************************
-----------------------------------------------------------------------------------
	-- 5 stage pipeline to calculate ((rx_a - rx_b)**2 + (ry_a -ry_b)**2)**3
	-- calculate (rx_a - rx_b) and (ry_a - ry_b)
	r_stage1: work.r_st1
		port map(
			clk => clk,
			reset => reset,
			en_in => start, 
			p1 => p1_cur,
			p2 => p2_cur,
			diff_x => diff_x,
			diff_y => diff_y,
			p1_buf => p1_buf(0),
			p2_buf => p2_buf(0),
			en_out => en_vec(1)
			);
	
	-- calculate diffx ** 2 + diffy ** 2
	r_stage2: work.r_st2
		port map(
			clk => clk,
			reset => reset,
			en_in => en_vec(1),
			diff_x => diff_x,
			diff_y => diff_y,
			p1 => p1_cur,
			p2 => p2_cur,
			diff_x_sq => diff_x_sq,
			diff_y_sq => diff_y_sq,
			diff_x_buf => diff_x_buf1,
			diff_y_buf => diff_y_buf1,
			p1_buf => p1_buf(1),
			p2_buf => p2_buf(1),
			en_out => en_vec(2)); 
	
	-- calculate r
	r_stage3: work.r_st3
		port map(clk, reset, en_vec(2), diff_x_buf1, diff_y_buf1, diff_x_sq, diff_y_sq, r, diff_x_buf2, diff_y_buf2, en_vec(3));
	
	-- calculate r**2
	r_stage4: work.r_st4
		port map(clk, reset, en_vec(3), diff_x_buf2, diff_y_buf2, r, r_buf, r_sq, diff_x_buf3, diff_y_buf3, en_vec(4));
	
	-- calculate r**3
	r_stage5: work.r_st5
		port map(clk, reset, en_vec(4), diff_x_buf3, diff_y_buf3, r_buf, r_sq, r_cube, diff_x_buf4, diff_y_buf4, en_vec(5));

	-- 4-stage pipeline to calculate fast inverse square root
	fast_isq1: work.fast_isq_st1
		port map(clk, reset, en_vec(5), diff_x_buf4, diff_y_buf4, r_cube, x, in_half, diff_x_buf5, diff_y_buf5, en_vec(6));
	
	fast_isq2: work.fast_isq_st2
		port map(clk, reset, en_vec(6), diff_x_buf5, diff_y_buf5, x, in_half, x_sq, x_half_x, x_1_5, diff_x_buf6, diff_y_buf6, en_vec(7));
	
	fast_isq3: work.fast_isq_st3
		port map(clk, reset, en_vec(7), diff_x_buf6, diff_y_buf6, x_sq, x_half_x, x_1_5, x_sqMx_half_x, x_1_5b, diff_x_buf7, diff_y_buf7, en_vec(8));
	
	fast_isq4: work.fast_isq_st4
		port map(clk, reset, en_vec(8), diff_x_buf7, diff_y_buf7, x_1_5b, x_sqMx_half_x, fisr_res, diff_x_buf8, diff_y_buf8, en_vec(9));
		
	-- 1 stage pipeline to calculate gravitational forces
	fx_fy: work.calc_f
		port map(clk, reset, en_vec(9), diff_x_buf8, diff_y_buf8, fisr_res, fx, fy, en_vec(10));
		
end arch;