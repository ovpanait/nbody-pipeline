library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st3 is
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
		x_sq:			in unsigned(DATA_W - 1 downto 0);
		x_half_x:	in unsigned(DATA_W - 1 downto 0);
		x_1_5:		in unsigned(DATA_W - 1 downto 0);

		x_sqMx_half_x:	out unsigned(DATA_W - 1 downto 0);
		x_1_5_b:			out unsigned(DATA_W - 1 downto 0);
		diff_x_buf:		out unsigned(DATA_W - 1 downto 0);
		diff_y_buf:		out unsigned(DATA_W - 1 downto 0);

		en_out:			out std_logic
	);
end fast_isq_st3;


architecture arch of fast_isq_st3 is
	signal x_1_5_reg, x_1_5_next:		unsigned(DATA_W - 1 downto 0);
	signal diff_x_reg, diff_x_next:	unsigned(DATA_W - 1 downto 0);
	signal diff_y_reg, diff_y_next:	unsigned(DATA_W - 1 downto 0);
begin

	process(clk, reset)
	begin
		if (reset = '0') then
			x_1_5_reg	<= (others => '0');
			diff_x_reg <= (others => '0');
			diff_y_reg <= (others => '0');
		elsif(clk'event and clk='1') then
			x_1_5_reg 	<= x_1_5_next;
			diff_x_reg <= diff_x_next;
			diff_y_reg <= diff_y_next;
		end if;
	end process;
	
	process(x_1_5, en_in, diff_x, diff_y)
	begin
		if (en_in = '1') then
			x_1_5_next 	<= x_1_5;
			diff_x_next <= diff_x;
			diff_y_next <= diff_y;
		else
			x_1_5_next  <= (others => '0');
			diff_x_next <= (others => '0');
			diff_y_next <= (others => '0');
		end if;
	end process;
	
	fin_mul: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => x_half_x, b => x_sq, result => x_sqMx_half_x, en_out => en_out);

	x_1_5_b	<= x_1_5_reg;
	diff_x_buf	<= diff_x_reg;
	diff_y_buf 	<= diff_y_reg;
end arch;