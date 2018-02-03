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
		
		fx:					in unsigned(DATA_W - 1 downto 0);
		fy:					in unsigned(DATA_W - 1 downto 0);

		en_in:				in std_logic
	);
end uart_out_fsm;

architecture arch of uart_out_fsm is
constant OUT_NR:					integer := 2;

signal in_cnt_reg, in_cnt_next:							unsigned(1 downto 0);
signal byte_cnt_reg, byte_cnt_next:						unsigned(2 downto 0);

type state_type is (waiting, sending);
signal uart_out_reg, uart_out_next:						unsigned(BYTES_N - 1 downto 0);
signal uart_out_start_reg, uart_out_start_next:		std_logic;
signal state_reg, state_next:								state_type;

signal fx_reg, fy_reg:										unsigned(DATA_W - 1 downto 0);
signal fx_next, fy_next:									unsigned(DATA_W - 1 downto 0);
begin
	process(clk, reset)
	begin
		if (reset = '0') then
			uart_out_reg 			<= (others => '0');
			uart_out_start_reg 	<= '0';
			
			in_cnt_reg 		<= (others => '0');
			byte_cnt_reg 	<= (others => '0');
			state_reg <= waiting;
			
			fx_reg 	<= (others => '0');
			fy_reg 	<= (others => '0');
		elsif (clk'event and clk = '1') then
			uart_out_reg 			<= uart_out_next;
			uart_out_start_reg 	<= uart_out_start_next;
			
			in_cnt_reg		<= in_cnt_next;
			byte_cnt_reg 	<= byte_cnt_next;
			state_reg		<= state_next;
			
			fx_reg 	<= fx_next;
			fy_reg 	<= fy_next;
		end if;
	end process;

	process(en_in, uart_out_done, uart_out_reg, uart_out_start_reg, byte_cnt_reg, state_reg, fx, fy,
				in_cnt_reg, fx_reg, fy_reg)
	begin
			uart_out_next 			<= uart_out_reg;
			uart_out_start_next 	<= uart_out_start_reg;
			
			in_cnt_next 			<= in_cnt_reg;
			byte_cnt_next			<= byte_cnt_reg;
			state_next 				<= state_reg;

			fx_next <= fx_reg;
			fy_next <= fy_reg;

			case to_integer(in_cnt_reg) is
				when 0 => 
					uart_out_next <= fx_reg(DATA_W - 1 downto DATA_W - 8);
				when 1 =>
					uart_out_next <= fy_reg(DATA_W - 1 downto DATA_W - 8);
				when others =>
			end case;
				
		case state_reg is
			when waiting =>
				if en_in = '1' then
					fx_next 	<= fx;
					fy_next  <= fy;
					state_next		<= sending;
				end if;
				uart_out_start_next 	<= '0';
			when sending =>
				uart_out_start_next 	<= '1';
				state_next <= sending;
			if (uart_out_done = '1') then
			
				case to_integer(in_cnt_reg) is
					when 0 => 
						fx_next <= fx_reg(DATA_W - 9 downto 0) & to_unsigned(0, uart_out'length);
					when 1 =>
						fy_next <= fy_reg(DATA_W - 9 downto 0) & to_unsigned(0, uart_out'length);
					when others =>
				end case;
			
				if (byte_cnt_reg = BYTES_N - 1) then
					if (in_cnt_reg = OUT_NR - 1) then
						in_cnt_next <=	(others => '0');
						
						fx_next <= (others => '0');
						fy_next <= (others => '0');
						
						in_cnt_next 	<= (others => '0');
						state_next <= waiting;
						uart_out_start_next <= '0';
					else 
						in_cnt_next 	<= in_cnt_reg + 1;
					end if;
					byte_cnt_next 	<= (others => '0');
				else
					byte_cnt_next <= byte_cnt_reg + 1;
				end if;
		end if;
			when others =>
				state_next <= waiting;
			end case;
	end process;
	
	uart_out 		<= uart_out_reg;
	uart_out_start <= uart_out_start_reg;
end arch;
		