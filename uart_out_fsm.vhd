library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_out_fsm is
	generic(
		DATA_W:           integer := 64;
		BYTES_N:				integer := 8
	);
	
	port(
		clk, reset:			in	std_logic;
		
		-- uart transmitter
		uart_out:   	  	out unsigned(BYTES_N - 1 downto 0); -- byte to transmit
		uart_out_start: 	out std_logic; -- start transmitting
		uart_out_done:  	in std_logic; -- byte sent
		
		grav_result:		in unsigned(DATA_W - 1 downto 0);
		en_in:				in std_logic
	);
end uart_out_fsm;

architecture arch of uart_out_fsm is
signal byte_cnt_reg, byte_cnt_next:						unsigned(2 downto 0);
signal grav_res_reg, grav_res_next:						unsigned(DATA_W - 1 downto 0);

signal uart_out_reg, uart_out_next:						unsigned(7 downto 0);
signal uart_out_start_reg, uart_out_start_next:		std_logic;
signal start_reg, start_next:								std_logic;
begin
	process(clk, reset)
	begin
		if (reset = '0') then
			uart_out_reg 			<= (others => '0');
			uart_out_start_reg 	<= '0';
			
			byte_cnt_reg 	<= (others => '0');
			grav_res_reg	<= (others => '0');
			start_reg		<= '0';
		elsif (clk'event and clk = '1') then
			uart_out_reg 			<= uart_out_next;
			uart_out_start_reg 	<= uart_out_start_next;
			
			byte_cnt_reg 	<= byte_cnt_next;
			grav_res_reg	<= grav_res_next;
			start_reg		<= start_next;
		end if;
	end process;

	process(grav_result, en_in, uart_out_done, uart_out_reg, uart_out_start_reg, byte_cnt_reg, start_reg, grav_res_reg)
	begin
			uart_out_next 			<= uart_out_reg;
			uart_out_start_next 	<= '0';
			
			byte_cnt_next			<= byte_cnt_reg;
			grav_res_next			<= grav_res_reg;
			start_next 				<= start_reg;

		if en_in = '1' then
			grav_res_next 	<= grav_result;
			start_next		<= '1';
		elsif (uart_out_done = '1' and start_reg = '1') then
			if (byte_cnt_reg = BYTES_N - 1) then
				byte_cnt_next 	<= (others => '0');
				start_next		<= '0';
			else
				byte_cnt_next <= byte_cnt_reg + 1;
			end if;
			
			uart_out_next <= grav_res_reg(DATA_W - 1 downto DATA_W - 8);
			uart_out_start_next <= '1';
			grav_res_next <= grav_res_reg(DATA_W - 9 downto 0) & to_unsigned(0, uart_out'length);
		end if;
	end process;
	
	uart_out 		<= uart_out_reg;
	uart_out_start <= uart_out_start_reg;
end arch;
		