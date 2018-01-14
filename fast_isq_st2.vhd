library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st2 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		x:				in unsigned(DATA_W - 1 downto 0);
		in_half:		in unsigned(DATA_W - 1 downto 0);
		
		x_sq:			out unsigned(DATA_W - 1 downto 0);
		x_half_x:	out unsigned(DATA_W - 1 downto 0);
		x_1_5:		out unsigned(DATA_W - 1 downto 0);
		en_out:		out std_logic
	);
end fast_isq_st2;


architecture arch of fast_isq_st2 is
	-- floating point representation of 1.5F
	signal TH_F : 	unsigned(DATA_W - 1 downto 0) := "0011111111111000000000000000000000000000000000000000000000000000";
begin
	x_squared: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => x, b => x, result => x_sq, en_out => en_out);
	
	x_half_m_x: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => in_half, b => x, result => x_half_x, en_out => open);
	
	x_m_1_5: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => TH_F, b => x, result => x_1_5, en_out => open);
end arch;