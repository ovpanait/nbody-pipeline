library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- 3-stage pipelined fast inverse-square-root algorithm
entity fast_isq_st2 is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	port(
		clk:			in std_logic;
		reset:		in std_logic;
		en_in:		in std_logic;

		diff_x:		in unsigned(DATA_W - 1 downto 0);
		diff_y:		in unsigned(DATA_W - 1 downto 0);
		x:				in unsigned(DATA_W - 1 downto 0);
		in_half:		in unsigned(DATA_W - 1 downto 0);
		p1, p2:	in unsigned(4*DATA_W - 1 downto 0);
		
		x_sq:			out unsigned(DATA_W - 1 downto 0);
		x_half_x:	out unsigned(DATA_W - 1 downto 0);
		x_1_5:		out unsigned(DATA_W - 1 downto 0);
		diff_x_buf:		out unsigned(DATA_W - 1 downto 0);
		diff_y_buf:		out unsigned(DATA_W - 1 downto 0);
		p1_buf: 	out unsigned(4*DATA_W - 1 downto 0);
		p2_buf:	out unsigned(4*DATA_W - 1 downto 0);

		en_out:		out std_logic
	);
	constant VELX_ST:	integer := 4*DATA_W - 1;
	constant	VELX_EN: integer := 3*DATA_W;
		
	constant	VELY_ST:	integer := 3*DATA_W - 1;
	constant	VELY_EN: integer := 2*DATA_W;
		
	constant RX_ST:	integer := 2*DATA_W - 1;
	constant RX_EN: 	integer := DATA_W;
		
	constant	RY_ST:	integer := DATA_W - 1;
	constant	RY_EN: 	integer := 0;
end fast_isq_st2;

architecture arch of fast_isq_st2 is
	-- floating point representation of 1.5F
	signal TH_F : 	unsigned(DATA_W - 1 downto 0) := "0011111111111000000000000000000000000000000000000000000000000000";
	signal diff_x_reg, diff_x_next:	unsigned(DATA_W - 1 downto 0);
	signal diff_y_reg, diff_y_next:	unsigned(DATA_W - 1 downto 0);
	signal p1_reg, p2_reg, p1_next, p2_next: 	unsigned(4*DATA_W - 1 downto 0);
begin
	process(clk, reset)
	begin
		if (reset = '0') then
			diff_x_reg <= (others => '0');
			diff_y_reg <= (others => '0');
			p1_reg <= (others => '0');
			p2_reg <= (others => '0');
		elsif(clk'event and clk='1') then
			diff_x_reg <= diff_x_next;
			diff_y_reg <= diff_y_next;
			p1_reg <= p1_next;
			p2_reg <= p2_next;
		end if;
	end process;
	
	process(en_in, diff_x, diff_y)
	begin
		if (en_in = '1') then
			diff_x_next <= diff_x;
			diff_y_next <= diff_y;
			p1_next <= p1;
			p2_next <= p2;
		else 
			diff_x_next <= (others => '0');
			diff_y_next <= (others => '0');
			p1_next <= (others => '0');
			p2_next <= (others => '0');
		end if;
	end process;
	
	x_squared: work.fpmu
		port map(
			clk => clk,
			reset => reset,
			en_in => en_in,
			a => x,
			b => x,
			result => x_sq,
			en_out => en_out);
	
	x_half_m_x: work.fpmu
		port map(
			clk => clk,
			reset => reset,
			en_in => en_in,
			a => in_half,
			b => x,
			result => x_half_x,
			en_out => open);
	
	x_m_1_5: work.fpmu
		port map(clk => clk, reset => reset, en_in => en_in, a => TH_F, b => x, result => x_1_5, en_out => open);
		
	diff_x_buf	<= diff_x_reg;
	diff_y_buf 	<= diff_y_reg;
	p1_buf <= p1_reg;
	p2_buf <= p2_reg;
end arch;