library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st2 is
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;
		
		diff_x:			in unsigned(63 downto 0);
		diff_y:			in unsigned(63 downto 0);
		
		diff_x_sq:		out unsigned(63 downto 0);
		diff_y_sq:		out unsigned(63 downto 0);
		en_out:			out std_logic
	);
end r_st2;

architecture arch of r_st2 is
signal en_out_reg, en_out_next: 	std_logic;
begin

process(clk, reset)
	begin
	if reset = '0' then
		en_out_reg 	<= '0';
	elsif (clk'event and clk='1') then
		en_out_reg 	<= en_out_next;
	end if;
	end process;

	-- Next state logic
	process(en_in)
	begin
		if en_in = '1' then
			en_out_next 	<= '1';
		else
			en_out_next 	<= '0';
		end if;
	end process;

	calc_diffx_sq: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => diff_x, b => diff_x, result => diff_x_sq,
		en_out => open);
	
	calc_diffy_sq: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => diff_y, b => diff_y, result => diff_y_sq,
		en_out => open);
		
	en_out 	<= en_out_reg;
end arch;
