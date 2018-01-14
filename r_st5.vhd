library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st5 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;		
		
		r:					in unsigned(DATA_W - 1 downto 0);
		r_sq:				in unsigned(DATA_W - 1 downto 0);
		
		r_cube:			out unsigned(DATA_W - 1 downto 0);
		
		en_out:			out std_logic
	);
end r_st5;

architecture arch of r_st5 is
begin
	-- calculate r**3
	calc_r_sq: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => r, b => r_sq, result => r_cube, en_out => en_out);
end arch;
