LIBRARY ieee  ; 
LIBRARY std  ; 
USE ieee.NUMERIC_STD.all  ; 
USE ieee.std_logic_1164.all  ; 
USE ieee.std_logic_textio.all  ; 
USE ieee.std_logic_unsigned.all  ; 
USE std.textio.all  ; 
ENTITY tb  IS 
  GENERIC (
    VGA_DW  : INTEGER   := 10 ;  
    BYTES_N  : INTEGER   := 8 ;  
    DATA_W  : INTEGER   := 64 ;  
    PART_NO  : INTEGER   := 2 ); 
END ; 
 
ARCHITECTURE tb_arch OF tb IS
  SIGNAL vga_dout_p1   :  UNSIGNED (2 * DATA_W - 1 downto 0)  ; 
  SIGNAL vga_dout_p2   :  UNSIGNED (2 * DATA_W - 1 downto 0)  ; 
  SIGNAL reset   :  STD_LOGIC  ; 
  SIGNAL pipe_done   :  STD_LOGIC  ; 
  SIGNAL pipe_start   :  STD_LOGIC  ; 
  SIGNAL pipe_din_p1   :  UNSIGNED (4 * DATA_W - 1 downto 0)  ; 
  SIGNAL pipe_din_p2   :  UNSIGNED (4 * DATA_W - 1 downto 0)  ; 
  SIGNAL pipe_dout_p1   :  UNSIGNED (4 * DATA_W - 1 downto 0)  ; 
  SIGNAL clk   :  STD_LOGIC  ; 
  SIGNAL pipe_dout_p2   :  UNSIGNED (4 * DATA_W - 1 downto 0)  ; 
  SIGNAL vga_done   :  STD_LOGIC  ; 
  SIGNAL vga_start   :  STD_LOGIC  ; 
  COMPONENT grav_controller  
    GENERIC ( 
      VGA_DW  : INTEGER ; 
      BYTES_N  : INTEGER ; 
      DATA_W  : INTEGER ; 
      PART_NO  : INTEGER  );  
    PORT ( 
      vga_dout_p1  : out UNSIGNED (2 * DATA_W - 1 downto 0) ; 
      vga_dout_p2  : out UNSIGNED (2 * DATA_W - 1 downto 0) ; 
      reset  : in STD_LOGIC ; 
      pipe_done  : in STD_LOGIC ; 
      pipe_start  : out STD_LOGIC ; 
      pipe_din_p1  : in UNSIGNED (4 * DATA_W - 1 downto 0) ; 
      pipe_din_p2  : in UNSIGNED (4 * DATA_W - 1 downto 0) ; 
      pipe_dout_p1  : out UNSIGNED (4 * DATA_W - 1 downto 0) ; 
      clk  : in STD_LOGIC ; 
      pipe_dout_p2  : out UNSIGNED (4 * DATA_W - 1 downto 0) ; 
      vga_done  : in STD_LOGIC ; 
      vga_start  : out STD_LOGIC ); 
  END COMPONENT ; 
BEGIN
  DUT  : grav_controller  
    GENERIC MAP ( 
      VGA_DW  => VGA_DW  ,
      BYTES_N  => BYTES_N  ,
      DATA_W  => DATA_W  ,
      PART_NO  => PART_NO   )
    PORT MAP ( 
      vga_dout_p1   => vga_dout_p1  ,
      vga_dout_p2   => vga_dout_p2  ,
      reset   => reset  ,
      pipe_done   => pipe_done  ,
      pipe_start   => pipe_start  ,
      pipe_din_p1   => pipe_din_p1  ,
      pipe_din_p2   => pipe_din_p2  ,
      pipe_dout_p1   => pipe_dout_p1  ,
      clk   => clk  ,
      pipe_dout_p2   => pipe_dout_p2  ,
      vga_done   => vga_done  ,
      vga_start   => vga_start   ) ; 



-- "Clock Pattern" : dutyCycle = 50
-- Start Time = 0 ns, End Time = 1 us, Period = 10 ns
  Process
	Begin
	 clk  <= '0'  ;
	wait for 5 ns ;
-- 5 ns, single loop till start period.
	for Z in 1 to 99
	loop
	    clk  <= '1'  ;
	   wait for 5 ns ;
	    clk  <= '0'  ;
	   wait for 5 ns ;
-- 995 ns, repeat pattern in loop.
	end  loop;
	 clk  <= '1'  ;
	wait for 5 ns ;
-- dumped values till 1 us
	wait;	
 End Process;


-- "Constant Pattern"
-- Start Time = 0 ns, End Time = 1 us, Period = 0 ns
  Process
	Begin
	 reset  <= '1'  ;
	wait for 1 us ;
-- dumped values till 1 us
	wait;
 End Process;
 
 -- "Constant Pattern"
-- Start Time = 0 ns, End Time = 1 us, Period = 0 ns
  Process
	Begin
	wait on pipe_start;
	
	pipe_din_p1 <= (others => '0');
	pipe_din_p2 <= (others => '1');
	
	wait for 10 ns;

	vga_done <= '1';
	wait for 10 ns;
	
	pipe_done <= '1';

	wait for 50 ns;
	
	pipe_din_p1 <= (others => '1');
	pipe_din_p2 <= (others => '0');
	
	wait for 150 ns;
	End Process;

END;
