library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st4 is
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;
		
		x_1_5:			in unsigned(63 downto 0);
		x_sqMx_half_x:	in unsigned(63 downto 0);

		result:			out unsigned(63 downto 0);
		en_out:			out std_logic
	);
end fast_isq_st4;


architecture arch of fast_isq_st4 is
	signal x_1, x_1_5_next:			unsigned(63 downto 0);
begin
	
	fast_isr: work.fp_add
		port map(clk => clk, reset => reset, en_in => en_in, a => x_1_5, b => '1' & x_sqMx_half_x(62 downto 0),
		result => result, en_out => en_out);

end arch;