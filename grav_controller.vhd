library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity grav_controller is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8;
		
		VGA_DW:				integer := 10;
		PART_NO:				integer := 2
	);
	
	port(
		-- control
		clk:					in std_logic;
		reset:				in std_logic;
		
		-- pipeline I/O
		pipe_din_p1:		in unsigned(4*DATA_W - 1 downto 0);
		pipe_din_p2:		in unsigned(4*DATA_W - 1 downto 0);
		pipe_done:			in std_logic;
		
		pipe_dout_p1:		out unsigned(4*DATA_W - 1 downto 0);
		pipe_dout_p2:		out unsigned(4*DATA_W - 1 downto 0);
		pipe_start:			out std_logic;
		
		-- VGA I/O
		vga_done:			in std_logic;
		
		vga_dout_p1:		out unsigned(2*VGA_DW - 1 downto 0);
		vga_dout_p2:		out unsigned(2*VGA_DW - 1 downto 0);
		vga_start:			out std_logic
	);
end grav_controller;

architecture arch of grav_controller is
-- Pipeline
signal pipe_dout_p1_reg, pipe_dout_p1_next:			unsigned(4*DATA_W - 1 downto 0);
signal pipe_dout_p2_reg, pipe_dout_p2_next:			unsigned(4*DATA_W - 1 downto 0);
signal pipe_start_reg, pipe_start_next:				std_logic;

-- VGA
signal vga_dout_p1_reg, vga_dout_p1_next:				unsigned(2*VGA_DW - 1 downto 0);
signal vga_dout_p2_reg, vga_dout_p2_next:				unsigned(2*VGA_DW - 1 downto 0);
signal vga_start_reg, vga_start_next:					std_logic;
signal en_to_unsigned_reg, en_to_unsigned_next:		std_logic;

-- register file
type reg_file_type is array (PART_NO downto 0) of
    unsigned(4*DATA_W - 1 downto 0);
signal part_regfile: reg_file_type;

-- State machine
type state_type is (init, waiting, display);
signal state_reg, state_next:		state_type;
begin
	process(clk, reset)
	begin
		if (reset = '0') then
			pipe_dout_p1_reg <= (others => '0');
			pipe_dout_p2_reg <= (others => '0');
			pipe_start_reg <= '0';
			
			vga_dout_p1_reg <= (others => '0');
			vga_dout_p2_reg <= (others => '0');
			vga_start_reg <= '0';
			en_to_unsigned_reg <= '0';

			part_regfile <= (others => (others => '0'));
			state_reg <= init;
		else
			pipe_dout_p1_reg <= pipe_dout_p1_next;
			pipe_dout_p2_reg <= pipe_dout_p2_next;
			pipe_start_reg <= pipe_start_next;
			
			vga_dout_p1_reg <= vga_dout_p1_next;
			vga_dout_p2_reg <= vga_dout_p2_next;
			vga_start_reg <= vga_start_next;
			en_to_unsigned_reg <= en_to_unsigned_next;
			
			state_reg <= state_next;
		end if;
	end process;

	process(pipe_dout_p1_reg, pipe_dout_p2_reg, pipe_start_reg, vga_start_reg, pipe_done, vga_done)
		variable data_ready:		std_logic;
	begin
		pipe_start_next 	<= '0';
		pipe_dout_p1_next <= pipe_dout_p1_reg;
		pipe_dout_p2_next	<= pipe_dout_p2_reg;

		vga_start_next 	<= '0';
		en_to_unsigned_reg <= '0';

		case (state_reg) is
			when init =>
				pipe_start_next <= '1';
				pipe_dout_p1_next <= part_regfile(0);
				pipe_dout_p2_next <= part_regfile(1);
				state_next <= waiting;
			when waiting =>
				state_next <= waiting;
				
				if (pipe_done = '1') then
					-- This is only a two-particle proof-of-concept -> Hardcode this
					part_regfile(0) <= pipe_din_p1;
					part_regfile(1) <= pipe_din_p2;
					data_ready := '1';
				else
					data_ready := '0';
				end if;
				
				if (vga_done = '1' and data_ready = '1') then
						state_next <= display;
						en_to_unsigned_next <= '1';
				end if;
			when display =>
				vga_start_next <= '1';
				state_next <= init;
			end case;
	end process;
	
	-- Turn particles' positions to unsigned
	tr_u1: work.f_to_u
		port map(clk, reset, en_to_unsigned_reg, part_regfile(0), vga_dout_p1_next, open);
	tr_u2: work.f_to_u
		port map(clk, reset, en_to_unsigned_reg, part_regfile(1), vga_dout_p2_next, open);
end arch;
