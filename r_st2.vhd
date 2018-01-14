library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st2 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;
		
		diff_x:			in unsigned(DATA_W - 1 downto 0);
		diff_y:			in unsigned(DATA_W - 1 downto 0);
		
		diff_x_sq:		out unsigned(DATA_W - 1 downto 0);
		diff_y_sq:		out unsigned(DATA_W - 1 downto 0);
		en_out:			out std_logic
	);
end r_st2;

architecture arch of r_st2 is
begin
	calc_diffx_sq: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => diff_x, b => diff_x, result => diff_x_sq,
		en_out => en_out);
	
	calc_diffy_sq: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => diff_y, b => diff_y, result => diff_y_sq,
		en_out => open);
end arch;
