library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity f_to_u is
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		input:		in unsigned(63 downto 0);
		
		output:		out unsigned(63 downto 0);
		en_out:		out std_logic
	);
end f_to_u;

architecture arch of f_to_u is
signal in_exp:							unsigned(10 downto 0);
signal in_man:							unsigned(51 downto 0);

signal out_reg, out_next:			unsigned(63 downto 0);
signal en_out_reg, en_out_next:	std_logic;
begin
	in_exp <= input(62 downto 52);
	in_man <= input(51 downto 0);

	process(clk, reset)
	begin
		if (reset = '0') then
			out_reg 		<= (others => '0');
			en_out_reg 	<= '0';
		elsif (clk'event and clk='1') then
			out_reg 		<= out_next;
			en_out_reg 	<= en_out_next;
		end if;
	end process;
	
	-- next-state logic
	process(in_exp, in_man, en_in)
	variable tmp_out:		unsigned(63 downto 0);
	variable tmp_exp:		unsigned(10 downto 0);
	variable tmp_man:		unsigned(51 downto 0);
	begin
		if (en_in = '1') then
			if (in_exp < to_unsigned(1023, tmp_exp'length)) then
				out_next <= (others => '0');
			elsif (in_exp = to_unsigned(1023, tmp_exp'length)) then
				-- normalized
				out_next <= '0' & in_exp & to_unsigned(1, in_man'length);
			elsif in_exp > to_unsigned(1023 + 63, tmp_exp'length) then
				out_next <= (others => '1');
			else
				tmp_exp := (in_exp - to_unsigned(1024, tmp_exp'length));
				tmp_man := in_man;
				tmp_out := to_unsigned(1, tmp_out'length);
				
			for I in 0 to 62 loop
					if (tmp_exp < to_unsigned(I, tmp_exp'length)) then
						exit;
					end if;
				
					if (I < 52) then
						tmp_out := tmp_out(62 downto 0) & tmp_man(51);
						tmp_man := tmp_man(50 downto 0) & '0';
					else
						tmp_out := tmp_out(62 downto 0) & '0';
					end if;
				end loop;
				out_next <= tmp_out;
			end if;	
			en_out_next <= '1';
		else
			en_out_next <= '0';
			out_next 	<= (others => '0');
		end if;
	end process;
	
output <= out_reg;
en_out <= en_out_reg;
end arch;