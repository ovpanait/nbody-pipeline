library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fp_add is
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		a:				in unsigned(63 downto 0);
		b:				in unsigned(63 downto 0);
		
		result:		out unsigned(63 downto 0);
		en_out:		out std_logic
	);
end fp_add;

architecture arch of fp_add is
signal res_reg, res_next:			unsigned(63 downto 0);
signal en_out_reg, en_out_next:	std_logic;

-- tmp
signal a_sig, b_sig:		std_logic;
signal a_exp, b_exp:		unsigned(10 downto 0);
signal a_man, b_man:		unsigned(51 downto 0);

signal a_gt_b:				std_logic;
begin

-- extract fields
	a_sig <= a(63);
	a_exp <= a(62 downto 52);
	a_man <= a(51 downto 0);
	
	b_sig <= b(63);
	b_exp <= b(62 downto 52);
	b_man <= b(51 downto 0);
	
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
	variable diff: 				unsigned(10 downto 0);
	variable a_shift, b_shift:	unsigned(53 downto 0);
	variable tmp_add:				unsigned(53 downto 0);
	variable tmp_exp:				unsigned(10 downto 0);
	begin
		if (en_in = '1') then
			a_shift 	:= ("01" & a_man);
			b_shift 	:= ("01" & b_man);
			
	-- align mantissas for adding
			if (a_gt_b = '1') then
				diff 		:= a_exp - b_exp;
				tmp_exp  := a_exp;
				for I in 0 to 51 loop
					if (diff = I) then
						exit;
					else
						b_shift := ( '0' & b_shift(53 downto 1));
					end if;
				end loop;
			else
				diff 		:= b_exp - a_exp;
				tmp_exp	:= b_exp;
				for I in 0 to 51 loop
					if (diff = I) then
						exit;
					else
						a_shift := ('0' & a_shift(53 downto 1));
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

				if tmp_add(53) = '1' then
					tmp_exp := tmp_exp + 1;
					res_next(51 downto 0) 	<= tmp_add(52 downto 1);
				else
					for I in 0 to 52  loop
						if tmp_add(52) = '1' then
							tmp_exp := tmp_exp - I;
							exit;
						else
							tmp_add := (tmp_add(52 downto 0) & '0');
						end if;
					end loop;
					res_next(51 downto 0) 	<= tmp_add(51 downto 0);
				end if;
			
			if (a_gt_b = '1') then 
				res_next(63) <= a_sig;
			else
				res_next(63) <= b_sig;
			end if;
			
			en_out_next 				<= '1';
			res_next(62 downto 52) 	<= tmp_exp;
		else
			en_out_next <= '0';
			res_next 	<= (others => '0');
		end if;
	end process;
	
	result <= res_reg;
	en_out <= en_out_reg;
end arch;
		