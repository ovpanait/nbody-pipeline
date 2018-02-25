library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
  port(
    clk, reset:         in  std_logic;
    hsync, vsync:       out std_logic;
    video_on, p_tick:   out std_logic;
    pixel_x, pixel_y:   out unsigned(9 downto 0);
	 
	 start:					in std_logic;
	 ready:					out std_logic
    );
end vga_sync;

architecture arch of vga_sync is
  -- VGA 640 by 480 sync parameters
  constant HD:  integer := 640; -- horizontal display area
  constant HF:  integer := 16;  -- h. front porch
  constant HB:  integer := 48;  -- h. back porch
  constant HR:  integer := 96;  -- h. retrace
  constant VD:  integer := 480; -- vertical display area
  constant VF:  integer := 10;  -- v. front porch
  constant VB:  integer := 33;  -- v. back porch
  constant VR:  integer := 2;   -- v. retrace

  -- mod-2 counter
  signal mod2_reg, mod2_next:           std_logic := '0';

-- sync counters
  signal v_count_reg, v_count_next:     unsigned(9 downto 0) := (others => '0');
  signal h_count_reg, h_count_next:     unsigned(9 downto 0)  := (others => '0');

-- output buffer
  signal v_sync_reg, h_sync_reg:         std_logic;
  signal v_sync_next, h_sync_next:       std_logic;
  -- status signals
  signal h_end, v_end, pixel_tick:       std_logic;
  signal ready_reg, ready_next:				std_logic;
  
  
begin
  -- registers
  process(clk, reset)
  begin
    if reset = '0' then
      mod2_reg <= '0';
      v_count_reg <= (others => '0');
      h_count_reg <= (others => '0');
      v_sync_reg <= '0';
      h_sync_reg <= '0';
		ready_reg <= '0';
    elsif (clk'event and clk='1') then
      mod2_reg <= mod2_next;
      v_count_reg <= v_count_next;
      h_count_reg <= h_count_next;
      v_sync_reg <= v_sync_next;
      h_sync_reg <= h_sync_next;
		ready_reg <= ready_next;
    end if;
  end process;

  -- mod-2 circuit to generate 25MHz enable tick
  mod2_next <= not mod2_reg;

  -- 25 MHz pixel tick
  pixel_tick <= '1' when mod2_reg = '1' else '0';

--status
  h_end <= -- end of horizontal counter
     '1' when h_count_reg=(HD + HF + HB + HR - 1) else '0';
  v_end <= -- end of vertical counter
	  '1' when v_count_reg = (VD + VF + VB + VR - 1) else '0';

-- mod 800 horizontal sync counter
  process(h_count_reg, h_end, v_end, start, pixel_tick)
  begin
	h_count_next <= h_count_reg;
    if pixel_tick = '1' then -- 25 MHz tick
      if h_end = '1' then
			h_count_next <= (others => '0');
			if v_end = '1' and start = '0' then
				h_count_next <= h_count_reg;
			end if;
      else
        h_count_next <= h_count_reg + 1;
      end if;
    end if;
  end process;

--mod 525 vertical sync counter
  process(v_count_reg, h_end, v_end, start, pixel_tick)
  begin
	ready_next <= '0';
	v_count_next <= v_count_reg;
    if pixel_tick = '1' and h_end = '1' then
      if v_end = '1' then
			if start = '1' then
				v_count_next <= (others => '0');
			else
				ready_next <= '1';
			end if;
      else
        v_count_next <= v_count_reg + 1;
      end if;
    end if;
  end process;

  -- horizontal and vertical sync, buffered to avoid glitches
  h_sync_next <=
    '1' when (h_count_reg >= (HD + HF)) and (h_count_reg <= (HD + HF + HR - 1))
        else '0';
  v_sync_next <=
    '1' when (v_count_reg >= (VD + VF)) and (v_count_reg <= (VD + VF + VR - 1))
    else '0';

  -- video on/off
  video_on <=
    '1' when (h_count_reg < HD) and (v_count_reg < VD) else '0';

  -- output signal
  hsync <= h_sync_reg;
  vsync <= v_sync_reg;
  pixel_x <= h_count_reg;
  pixel_y <= v_count_reg;
  p_tick <= pixel_tick;
  ready <= ready_reg;
end arch;
