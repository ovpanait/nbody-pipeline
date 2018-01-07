library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpmu is
	port(
		clk: 		in std_logic;
		reset:	in std_logic;
		en_in:	in std_logic;
		
		a:			in unsigned(63 downto 0);
		b:			in unsigned(63 downto 0);
		
		result:	out unsigned(63 downto 0);
		en_out:	out std_logic
	);
end fpmu;

architecture arch of fpmu is
signal result_reg, result_next:		unsigned(63 downto 0);
signal en_out_reg, en_out_next:		std_logic;
begin

	process(clk, reset)
	begin
		if (reset = '0') then
			result_reg <= (others => '0');
			en_out_reg <= '0';
		elsif (clk'event and clk = '1') then
			result_reg <= result_next;
			en_out_reg <= en_out_next;
		end if;
	end process;

	fp_mul: work.fp_mul
		port map(a => a, b => b, result => result_next);

	process(en_in)
	begin
		if (en_in = '1') then
			en_out_next <= '1';
		else 
			en_out_next <= '0';
		end if;
	end process;
	
	result <= result_reg;
	en_out <= en_out_reg;
end arch;