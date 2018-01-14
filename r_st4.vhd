library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r_st4 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;		
		
		r:					in unsigned(DATA_W - 1 downto 0);
		
		r_sq:				out unsigned(DATA_W - 1 downto 0);
		r_buf:			out unsigned(DATA_W - 1 downto 0);
		
		en_out:			out std_logic
	);
end r_st4;

architecture arch of r_st4 is
signal r_reg, r_next:				unsigned(DATA_W - 1 downto 0);
begin

process(clk, reset)
begin
	if reset = '0' then
		r_reg <= (others => '0');
	elsif (clk'event and clk='1') then
		r_reg 		<= r_next;
	end if;
	end process;

-- Next state logic
	process(en_in, r)
	begin
		if en_in = '1' then
			r_next 		<= r;
		else
			r_next 		<= (others => '0');
		end if;
	end process;
	
	-- calculate r**2
	calc_r_sq: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => r, b => r, result => r_sq, en_out => en_out);

	r_buf 	<= r_reg;
end arch;
