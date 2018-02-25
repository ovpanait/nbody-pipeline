library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_f is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:				in std_logic;
		reset:			in std_logic;
		en_in:			in std_logic;

		diff_x:			in unsigned(DATA_W - 1 downto 0);
		diff_y:			in unsigned(DATA_W - 1 downto 0);		
		fisr_res:		in unsigned(DATA_W - 1 downto 0);
		p1, p2:			in unsigned(4*DATA_W - 1 downto 0);

		fx:				out unsigned(DATA_W - 1 downto 0);
		fy:				out unsigned(DATA_W - 1 downto 0);
		p1_buf: 			out unsigned(4*DATA_W - 1 downto 0);
		p2_buf:			out unsigned(4*DATA_W - 1 downto 0);
		en_out:			out std_logic
	);
	constant VELX_ST:	integer := 4*DATA_W - 1;
	constant	VELX_EN: integer := 3*DATA_W;
		
	constant	VELY_ST:	integer := 3*DATA_W - 1;
	constant	VELY_EN: integer := 2*DATA_W;
		
	constant RX_ST:	integer := 2*DATA_W - 1;
	constant RX_EN: 	integer := DATA_W;
		
	constant	RY_ST:	integer := DATA_W - 1;
	constant	RY_EN: 	integer := 0;
end calc_f;

architecture arch of calc_f is
signal p1_reg, p2_reg, p1_next, p2_next: 	unsigned(4*DATA_W - 1 downto 0);
begin
	process(clk, reset)
	begin
		if reset = '0' then
			p1_reg <= (others => '0');
			p2_reg <= (others => '0');
		elsif (clk'event and clk = '1') then
			p1_reg <= p1_next;
			p2_reg <= p2_next;
		end if;
	end process;
	
	process(en_in, p1, p2)
	begin
		if en_in = '1' then
			p1_next <= p1;
			p2_next <= p2;
		else
			p1_next <= (others => '0');
			p2_next <= (others => '0');
		end if;
	end process;

	fx_calc: work.fpmu
		port map(
			clk => clk,
			reset => reset,
			en_in => en_in,
			a => fisr_res,
			b => diff_x,
			result => fx,
			en_out => en_out);

	fy_calc: work.fpmu
		port map(
			clk => clk,
			reset => reset,
			en_in => en_in, 
			a => fisr_res,
			b => diff_y,
			result => fy,
			en_out => open);
		
	p1_buf <= p1_reg;
	p2_buf <= p2_reg;
end arch;