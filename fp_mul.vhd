library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- combinational floating point multiplier

entity fp_mul is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8;
		
		EXP_N:				integer := 11;
		MAN_N:				integer := 52
	);
	port(
		a:			in unsigned(DATA_W - 1 downto 0);
		b:			in unsigned(DATA_W - 1 downto 0);
		
		result:	out unsigned(DATA_W - 1 downto 0)
	);
end fp_mul;

architecture arch of fp_mul is
-- inputs
signal a_sig, b_sig:					std_logic;
signal a_exp, b_exp:					unsigned(EXP_N - 1 downto 0);
signal a_man, b_man:					unsigned(MAN_N - 1 downto 0);

-- temp
signal tmp_sig: 						std_logic;
signal tmp_exp:						unsigned(EXP_N downto 0);
signal tmp_man:						unsigned(MAN_N * 2 + 1 downto 0);

signal res_sig:						std_logic;
signal res_exp:						unsigned(EXP_N downto 0);
signal res_man:						unsigned(MAN_N - 1 downto 0);
begin
	-- inputs
	a_sig <= a(DATA_W - 1);
	b_sig <= b(DATA_W - 1);
	
	a_exp <= a(DATA_W - 2 downto MAN_N);
	b_exp <= b(DATA_W - 2 downto MAN_N);
	
	a_man <= a(MAN_N - 1 downto 0);
	b_man <= b(MAN_N - 1 downto 0);
	
	--next-state-logic	
	tmp_sig <= a_sig xor b_sig;
	tmp_exp <= (('0' & a_exp) + ('0' & b_exp));
	tmp_man <= ('1' & a_man) * ('1' & b_man);	
	
	res_sig	<= tmp_sig;
	
	res_exp 	<= 
					(tmp_exp - to_unsigned(1022, tmp_exp'length)) when tmp_man(MAN_N * 2 + 1) = '1' else 	-- result needs to be re-normalized
					(tmp_exp - to_unsigned(1023, tmp_exp'length)); 										-- result is already normalized
					
	res_man 	<= 
					tmp_man(MAN_N * 2 downto MAN_N + 1) when tmp_man(MAN_N * 2 + 1) = '1' else
					tmp_man(MAN_N * 2 - 1 downto MAN_N);
					
	result 	<= 
					(others => '0') when (tmp_exp < to_unsigned(1024, tmp_exp'length)) or 
												(a_exp = to_unsigned(0, a_exp'length)) or
												(b_exp = to_unsigned(0, b_exp'length)) else
					(res_sig & res_exp(EXP_N - 1 downto 0) & res_man);
					
end arch;