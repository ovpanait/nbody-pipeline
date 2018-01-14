library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st1 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:		in std_logic;
		reset:	in std_logic;
		en_in:	in std_logic;
		
		rx_a:		in unsigned(DATA_W - 1 downto 0) ;
		rx_b:		in unsigned(DATA_W - 1 downto 0) ;
		ry_a:		in unsigned(DATA_W - 1 downto 0) ;
		ry_b:		in unsigned(DATA_W - 1 downto 0) ;
		
		diff_x:	out unsigned(DATA_W - 1 downto 0);
		diff_y:	out unsigned(DATA_W - 1 downto 0);
		en_out:	out std_logic
	);
end r_st1;

architecture arch of r_st1 is
begin
	calc_diffx: work.fp_add
		port map(clk => clk, reset => reset, en_in => en_in, a => rx_b, b => ('1' & rx_a(62 downto 0)), result => diff_x, en_out => en_out);

	calc_diffy: work.fp_add
		port map(clk => clk, reset => reset, en_in => en_in, a => ry_b, b => '1' & ry_a(62 downto 0), result => diff_y, en_out => open);
end arch;
