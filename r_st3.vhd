library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st3 is
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;
		
		diff_x_sq:		in unsigned(63 downto 0);
		diff_y_sq:		in unsigned(63 downto 0);
		
		r:					out unsigned(63 downto 0);
		en_out:			out std_logic
	);
end r_st3;

architecture arch of r_st3 is
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
	
	calc_r: work.fp_add
		port map(clk => clk, reset => reset, en_in => en_in, a => diff_x_sq, b => diff_y_sq, result => r, en_out => open);
		
	en_out 	<= en_out_reg;

end arch;
