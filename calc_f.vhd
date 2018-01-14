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

		fx:				out unsigned(DATA_W - 1 downto 0);
		fy:				out unsigned(DATA_W - 1 downto 0);

		en_out:			out std_logic
	);
end calc_f;


architecture arch of calc_f is
begin
	fx_calc: work.fpmu
		port map(clk, reset, en_in, fisr_res, diff_x, fx, en_out);

	fy_calc: work.fpmu
		port map(clk, reset, en_in, fisr_res, diff_y, fy, open);
end arch;