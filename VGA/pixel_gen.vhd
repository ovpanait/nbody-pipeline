library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_gen is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8;
		
		VGA_DW:				integer := 10;
		PART_NO:				integer := 2
	);
	port(
		-- FPGA communication with the FPGA VGA pins
		clk, reset:      	in std_logic;
		hsync, vsync:   	out std_logic;
		rgb:            	out std_logic_vector(11 downto 0);
		
		-- particles
		p1:					in unsigned(2*DATA_W - 1 downto 0);
		p2:					in unsigned(2*DATA_W - 1 downto 0);
		start:				in std_logic;
		ready:				out std_logic
		);
end pixel_gen;

architecture arch of pixel_gen is
	signal rgb_reg, rgb_next:    	std_logic_vector(11 downto 0);
	signal video_on:              std_logic;
	signal pixel_x, pixel_y:      unsigned(9 downto 0);
	
  -- particle buffers
	signal p1_reg, p1_next:				  	unsigned(2*DATA_W - 1 downto 0);
	signal p2_reg ,p2_next:					unsigned(2*DATA_W - 1 downto 0);
begin
  -- instantiate VGA sync circuit
  vga_sync_unit: entity work.vga_sync
    port map(
		clk => clk,
		reset => reset, 
		hsync => hsync,
      vsync => vsync,
		video_on => video_on,
		p_tick => open,
		pixel_x => pixel_x,
		pixel_y => pixel_y,
		start => start,
		ready => ready
		);

  -- reg buffer
  process (clk, reset)
  begin
    if reset = '0' then
		rgb_reg <= (others => '0');
    elsif (clk'event and clk='1') then
		rgb_reg <= rgb_next;
	 end if;
  end process;

	process(pixel_x, pixel_y, p1, p2)
	begin
		if (((pixel_x - 1 = p1(72 downto 64))	and (pixel_y - 1 = p1(9 downto 0)))
			or ((pixel_x - 1 = p2(72 downto 64)) and (pixel_y - 1 = p2(9 downto 0)))) then
				rgb_next <= (others => '1');
		else 
			rgb_next <= (others => '0');
		end if;
	end process;

	rgb <= rgb_reg;
end arch;
