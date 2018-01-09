library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity qtest is
port(
	 KEY:                in std_logic_vector(1 downto 0); 
    MAX10_CLK1_50:      in std_logic;
	 LEDR:               out std_logic_vector(9 downto 0);
	 GPIO:				   inout std_logic_vector(35 downto 0)
	 );
end qtest;

architecture arch of qtest is
-- debug and init
-- uart transmitter
signal uart_out:   	  	unsigned(7 downto 0); -- byte to transmit
signal uart_out_start: 	std_logic; -- start transmitting
signal uart_out_done:  	std_logic; -- byte sent
		  
-- uart receiver
signal uart_in_data: 	unsigned(7 downto 0); -- byte received
signal uart_in_flag:	  	std_logic; --received data
begin
    uart: entity work.uart
		generic map(baud => 9600, clock_frequency => 50000000)
		port map (MAX10_CLK1_50, KEY(0), GPIO(0), GPIO(1), uart_out, uart_out_start, uart_out_done, uart_in_data, uart_in_flag);
	 
	 nbody: entity work.nbody
		port map (MAX10_CLK1_50, KEY(0), uart_out, uart_out_start, uart_out_done, uart_in_data, uart_in_flag);
	 
	 LEDR(0) <= uart_in_flag;
end arch;
