library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st1 is
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;
		
		input:		in unsigned(63 downto 0);
		
		x:				out unsigned(63 downto 0);
		in_half:		out unsigned(63 downto 0);
		en_out:		out std_logic
	);
end fast_isq_st1;


architecture arch of fast_isq_st1 is
	-- floating point representation of 0.5F
	signal OH_F: unsigned(63 downto 0) := "0011111111100000000000000000000000000000000000000000000000000000"; -- 0.5
	-- 64 bit magic number
	signal MN_F: 	unsigned(63 downto 0) := "0101111111100110111010110101000011000111101101010011011110101001";
	-- 0.5F * input
	signal xhalf:		unsigned(63 downto 0);
	-- registers
	signal x_reg, x_next:					unsigned(63 downto 0);
	signal en_out_reg, en_out_next:		std_logic;					
begin

	process(clk, reset)
	begin
		if (reset = '0') then
			x_reg 		<= (others => '0');
			en_out_reg 	<= '0';
		elsif(clk'event and clk='1') then
			x_reg 		<= x_next;
			en_out_reg 	<= en_out_next;
		end if;
	end process;
	
	process(input, en_in, MN_F)
	begin
		if (en_in = '1') then
			x_next <= (MN_F - ('0' & input(63 downto 1))); -- i  = MAGIC_NR - ( i >> 1 );
			en_out_next <= '1';
		else 
			x_next <= (others => '0');
			en_out_next <= '0';
		end if;
	end process;
	
	input_half: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => OH_F, b => input, result => in_half, en_out => open);

	x 			<= x_reg;
	en_out 	<= en_out_reg;
end arch;