library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fast_isq_st4 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;
		
		x_1_5:			in unsigned(DATA_W - 1 downto 0);
		x_sqMx_half_x:	in unsigned(DATA_W - 1 downto 0);

		result:			out unsigned(DATA_W - 1 downto 0);
		en_out:			out std_logic
	);
end fast_isq_st4;


architecture arch of fast_isq_st4 is
	signal x_1, x_1_5_next:			unsigned(DATA_W - 1 downto 0);
begin
	
	fast_isr: work.fp_add
		port map(clk => clk, reset => reset, en_in => en_in, a => x_1_5, b => '1' & x_sqMx_half_x(DATA_W - 2 downto 0),
		result => result, en_out => en_out);

end arch;