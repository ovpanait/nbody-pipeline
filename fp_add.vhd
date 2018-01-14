library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fp_add is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8;
		
		EXP_N:				integer := 11;
		MAN_N:				integer := 52
	);
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		a:				in unsigned(DATA_W - 1 downto 0);
		b:				in unsigned(DATA_W - 1 downto 0);
		
		result:		out unsigned(DATA_W - 1 downto 0);
		en_out:		out std_logic
	);
end fp_add;

architecture arch of fp_add is
signal res_reg, res_next:			unsigned(DATA_W - 1 downto 0);
signal en_out_reg, en_out_next:	std_logic;

-- tmp
signal a_sig, b_sig:		std_logic;
signal a_exp, b_exp:		unsigned(EXP_N - 1 downto 0);
signal a_man, b_man:		unsigned(MAN_N - 1 downto 0);

signal a_gt_b:				std_logic;
begin

-- extract fields
	a_sig <= a(DATA_W - 1);
	a_exp <= a(DATA_W - 2 downto MAN_N);
	a_man <= a(MAN_N - 1 downto 0);
	
	b_sig <= b(DATA_W - 1);
	b_exp <= b(DATA_W - 2 downto MAN_N);
	b_man <= b(MAN_N - 1 downto 0);
	
	a_gt_b <= 	'1' when (a_exp >= b_exp) or ((a_exp = b_exp) and (a_man >= b_man)) else
					'0';
	
	process(clk, reset)
	begin
		if (reset = '0') then
			res_reg 		<= (others => '0');
			en_out_reg	<= '0';
		elsif (clk'event and clk='1') then
			res_reg 		<= res_next;
			en_out_reg 	<= en_out_next;
		end if;
	end process;


	process(a_exp, a_man, a_sig, b_exp, b_man, b_sig, a_gt_b, en_in)
	variable diff: 				unsigned(EXP_N - 1 downto 0);
	variable a_shift, b_shift:	unsigned(MAN_N + 1 downto 0);
	variable tmp_add:				unsigned(MAN_N + 1 downto 0);
	variable tmp_exp:				unsigned(EXP_N - 1 downto 0);
	begin
		if (en_in = '1') then
			a_shift 	:= ("01" & a_man);
			b_shift 	:= ("01" & b_man);
			
	-- align mantissas for adding
			if (a_gt_b = '1') then
				diff 		:= a_exp - b_exp;
				tmp_exp  := a_exp;
				for I in 0 to MAN_N - 1 loop
					if (diff = I) then
						exit;
					else
						b_shift := ( '0' & b_shift(MAN_N + 1 downto 1));
					end if;
				end loop;
			else
				diff 		:= b_exp - a_exp;
				tmp_exp	:= b_exp;
				for I in 0 to MAN_N - 1 loop
					if (diff = I) then
						exit;
					else
						a_shift := ('0' & a_shift(MAN_N + 1 downto 1));
					end if;
				end loop;
			end if;
			
	-- calculate resulting mantissa
			if ((a_sig xor b_sig) = '0') then
				tmp_add := a_shift + b_shift;
			elsif (a_gt_b = '1') then
				tmp_add := a_shift - b_shift;
			else
				tmp_add := b_shift - a_shift;
			end if;
			
	-- normalize

				if tmp_add(MAN_N + 1) = '1' then
					tmp_exp := tmp_exp + 1;
					res_next(MAN_N - 1 downto 0) 	<= tmp_add(MAN_N downto 1);
				else
					for I in 0 to MAN_N  loop
						if tmp_add(MAN_N) = '1' then
							tmp_exp := tmp_exp - I;
							exit;
						else
							tmp_add := (tmp_add(MAN_N downto 0) & '0');
						end if;
					end loop;
					res_next(MAN_N - 1 downto 0) 	<= tmp_add(MAN_N - 1 downto 0);
				end if;
			
			if (a_gt_b = '1') then 
				res_next(DATA_W - 1) <= a_sig;
			else
				res_next(DATA_W - 1) <= b_sig;
			end if;
			
			en_out_next 				<= '1';
			res_next(DATA_W - 2 downto MAN_N) 	<= tmp_exp;
		else
			en_out_next <= '0';
			res_next 	<= (others => '0');
		end if;
	end process;
	
	result <= res_reg;
	en_out <= en_out_reg;
end arch;
		