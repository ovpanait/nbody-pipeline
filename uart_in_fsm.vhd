library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_in_fsm is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	
	port(
		clk, reset:					in	std_logic;

		-- uart receiver
		uart_in_data:	  			in unsigned(7 downto 0);		
		uart_in_flag: 				in std_logic;
		
		rx_a, rx_b, ry_a, ry_b:	out unsigned(DATA_W - 1 downto 0);
		en_out:						out std_logic
--		debug:						out unsigned(7 downto 0)
	);
end uart_in_fsm;


architecture arch of uart_in_fsm is
constant OUT_NR:					integer := 4;

signal rxa_reg, rxa_next:		unsigned(DATA_W - 1 downto 0);
signal rxb_reg, rxb_next:		unsigned(DATA_W - 1 downto 0);
signal rya_reg, rya_next:		unsigned(DATA_W - 1 downto 0);
signal ryb_reg, ryb_next:		unsigned(DATA_W - 1 downto 0);
signal eno_reg, eno_next:		std_logic;

signal byte_cnt_reg, byte_cnt_next:		unsigned(2 downto 0);
signal in_cnt_reg, in_cnt_next:			unsigned(1 downto 0);
begin
	process(clk, reset)
	begin
		if (reset = '0') then
			rxa_reg <= (others => '0');
			rxb_reg <= (others => '0');
			rya_reg <= (others => '0');
			ryb_reg <= (others => '0');
			eno_reg <= '0';
			
			byte_cnt_reg 	<= (others => '0');
			in_cnt_reg		<= (others => '0');
		elsif (clk'event and clk = '1') then
			rxa_reg <= rxa_next;
			rxb_reg <= rxb_next;
			rya_reg <= rya_next;
			ryb_reg <= ryb_next;
			eno_reg <= eno_next;
			
			byte_cnt_reg 	<= byte_cnt_next;
			in_cnt_reg		<= in_cnt_next;
		end if;
	end process;

	process(uart_in_flag, ryb_reg, rxa_reg, rxb_reg, rya_reg, eno_reg, uart_in_data,
			byte_cnt_reg, in_cnt_reg)
	begin
		rxa_next <= rxa_reg;
		rxb_next <= rxb_reg;
		rya_next <= rya_reg;
		ryb_next <= ryb_reg;
		eno_next <= '0';
	
		byte_cnt_next 	<= byte_cnt_reg;
		in_cnt_next		<= in_cnt_reg;

		if (uart_in_flag = '1') then
			if (byte_cnt_reg = BYTES_N - 1) then
				if (in_cnt_reg = OUT_NR - 1) then
					in_cnt_next <=	(others => '0');
					eno_next 	<= '1';
				else 
					in_cnt_next 	<= in_cnt_reg + 1;
				end if;
				
				byte_cnt_next 	<= (others => '0');
			else
				byte_cnt_next <= byte_cnt_reg + 1;
			end if;

			case to_integer(in_cnt_reg) is
				when 0 => 
					rxa_next <= rxa_reg(DATA_W - 9 downto 0) & uart_in_data;
				when 1 =>
					rya_next <= rya_reg(DATA_W - 9 downto 0) & uart_in_data;
				when 2 => 
					rxb_next <= rxb_reg(DATA_W - 9 downto 0) & uart_in_data;
				when 3 =>
					ryb_next <= ryb_reg(DATA_W - 9 downto 0) & uart_in_data;
				when others =>

			end case;			
		end if;
		
--		eno_next 	<= '1';
--		rxa_next <= (others => '0');
--		rxb_next <= (others => '0');
--		rya_next <= (others => '0');
--		ryb_next <= (others => '0');
	end process;
	
	rx_a 		<= rxa_reg;
	rx_b 		<= rxb_reg;
	ry_a 		<= rya_reg;
	ry_b 		<= ryb_reg;
	en_out 	<= eno_reg;
	
--	debug <= to_unsigned(en_out, debug'length);
end arch;
		