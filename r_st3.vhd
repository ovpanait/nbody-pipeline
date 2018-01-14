library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st3 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;
		
		diff_x_sq:		in unsigned(DATA_W - 1 downto 0);
		diff_y_sq:		in unsigned(DATA_W - 1 downto 0);
		
		r:					out unsigned(DATA_W - 1 downto 0);
		en_out:			out std_logic
	);
end r_st3;

architecture arch of r_st3 is
begin
	calc_r: work.fp_add
		port map(clk => clk, reset => reset, en_in => en_in, a => diff_x_sq, b => diff_y_sq, result => r, en_out => en_out);
end arch;
