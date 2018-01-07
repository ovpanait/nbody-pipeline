library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- combinational floating point multiplier

entity fp_mul is 
	port(
		a:			in unsigned(63 downto 0);
		b:			in unsigned(63 downto 0);
		
		result:	out unsigned(63 downto 0)
	);
end fp_mul;

architecture arch of fp_mul is
-- inputs
signal a_sig, b_sig:					std_logic;
signal a_exp, b_exp:					unsigned(10 downto 0);
signal a_man, b_man:					unsigned(51 downto 0);

-- temp
signal tmp_sig: 						std_logic;
signal tmp_exp:						unsigned(11 downto 0);
signal tmp_man:						unsigned(105 downto 0);

signal res_sig:						std_logic;
signal res_exp:						unsigned(11 downto 0);
signal res_man:						unsigned(51 downto 0);
begin
	-- inputs
	a_sig <= a(63);
	b_sig <= b(63);
	
	a_exp <= a(62 downto 52);
	b_exp <= b(62 downto 52);
	
	a_man <= a(51 downto 0);
	b_man <= b(51 downto 0);
	
	--next-state-logic	
	tmp_sig <= a_sig xor b_sig;
	tmp_exp <= (('0' & a_exp) + ('0' & b_exp));
	tmp_man <= ('1' & a_man) * ('1' & b_man);	
	
	res_sig	<= tmp_sig;
	
	res_exp 	<= 
					(tmp_exp - to_unsigned(1022, tmp_exp'length)) when tmp_man(105) = '1' else 	-- result needs to be re-normalized
					(tmp_exp - to_unsigned(1023, tmp_exp'length)); 										-- result is already normalized
					
	res_man 	<= 
					tmp_man(104 downto 53) when tmp_man(105) = '1' else
					tmp_man(103 downto 52);
					
	result 	<= 
					(others => '0') when (tmp_exp < to_unsigned(1024, tmp_exp'length)) or 
												(a_exp = to_unsigned(0, a_exp'length)) or
												(b_exp = to_unsigned(0, b_exp'length)) else
					(res_sig & res_exp(10 downto 0) & res_man);
					
end arch;