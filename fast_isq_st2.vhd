library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st2 is
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		x:				in unsigned(63 downto 0);
		in_half:		in unsigned(63 downto 0);
		
		x_sq:			out unsigned(63 downto 0);
		x_half_x:	out unsigned(63 downto 0);
		x_1_5:		out unsigned(63 downto 0);
		en_out:		out std_logic
	);
end fast_isq_st2;


architecture arch of fast_isq_st2 is
	-- floating point representation of 1.5F
	signal TH_F : 	unsigned(63 downto 0) := "0011111111111000000000000000000000000000000000000000000000000000";
	
	signal en_out_reg, en_out_next:		std_logic;
begin

	process(clk, reset)
	begin
		if (reset = '0') then
			en_out_reg 	<= '0';
		elsif(clk'event and clk='1') then
			en_out_reg 	<= en_out_next;
		end if;
	end process;
	
	process(x, in_half, en_in)
	begin
		if (en_in = '1') then
			en_out_next <= '1';
		else
			en_out_next <= '0';
		end if;
	end process;
	
	x_squared: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => x, b => x, result => x_sq, en_out => open);
	
	x_half_m_x: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => in_half, b => x, result => x_half_x, en_out => open);
	
	x_m_1_5: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => TH_F, b => x, result => x_1_5, en_out => open);
		
	en_out <= en_out_reg;
end arch;