library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st1 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		diff_x:		in unsigned(DATA_W - 1 downto 0);
		diff_y:		in unsigned(DATA_W - 1 downto 0);
		input:		in unsigned(DATA_W - 1 downto 0);
		
		x:				out unsigned(DATA_W - 1 downto 0);
		in_half:		out unsigned(DATA_W - 1 downto 0);
		diff_x_buf:	out unsigned(DATA_W - 1 downto 0);
		diff_y_buf:	out unsigned(DATA_W - 1 downto 0);

		en_out:		out std_logic
	);
end fast_isq_st1;


architecture arch of fast_isq_st1 is
	-- floating point representation of 0.5F
	signal OH_F: 				unsigned(DATA_W - 1 downto 0) := "0011111111100000000000000000000000000000000000000000000000000000";
	-- 64 bit magic number
	signal MN_F: 				unsigned(DATA_W - 1 downto 0) := "0101111111100110111010110101000011000111101101010011011110101001";
	-- 0.5F * input
	signal xhalf:				unsigned(DATA_W - 1 downto 0);
	-- registers
	signal x_reg, x_next:	unsigned(DATA_W - 1 downto 0);
	signal diff_x_reg, diff_x_next:	unsigned(DATA_W - 1 downto 0);
	signal diff_y_reg, diff_y_next:	unsigned(DATA_W - 1 downto 0);	
begin

	process(clk, reset)
	begin
		if (reset = '0') then
			x_reg 		<= (others => '0');
			diff_x_reg <= (others => '0');
			diff_y_reg <= (others => '0');
		elsif(clk'event and clk='1') then
			x_reg 		<= x_next;
			diff_x_reg <= diff_x_next;
			diff_y_reg <= diff_y_next;
		end if;
	end process;
	
	process(input, en_in, MN_F, diff_x, diff_y)
	begin
		if (en_in = '1') then
			x_next <= (MN_F - ('0' & input(DATA_W - 1 downto 1))); -- i  = MAGIC_NR - ( i >> 1 );
			diff_x_next <= diff_x;
			diff_y_next <= diff_y;
		else 
			x_next <= (others => '0');
			diff_x_next <= (others => '0');
			diff_y_next <= (others => '0');
		end if;
	end process;
	
	input_half: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => OH_F, b => input, result => in_half, en_out => en_out);

	x	 			<= x_reg;
	diff_x_buf	<= diff_x_reg;
	diff_y_buf 	<= diff_y_reg;
end arch;