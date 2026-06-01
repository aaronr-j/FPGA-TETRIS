library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	
entity RNG is
	port (
		clk : in std_logic;
		color_out: out std_logic_vector(1 downto 0);

		KEY : in std_logic_vector(1 downto 0)
	);
end;	

architecture bbbb of RNG is
	type MY_MEM is array (0 to 15) of std_logic_vector(7 downto 0);
	--										0		1			2		3		 4			5		6		 7 		8		9		 A      b		C		  d	  E		F
	constant table : MY_MEM := (X"C0", X"F9", X"A4", X"B0", X"99", X"92", X"82", X"F8", X"80", X"90", x"88", X"83", X"A7", X"A1", X"86", X"8E");
	signal lfr : std_logic_vector(9 downto 0);
	signal bittt : std_logic;

	begin
		process (clk, KEY(0))
		begin
			if KEY(0) = '0' then
				lfr <= "0000000001";
				bittt <= '1';
			elsif rising_edge(clk) then
				bittt <= lfr(9) xor lfr(6);
				lfr <= bittt & lfr(9 downto 1);
			end if;
		
		end process;
		
		color_out <= lfr(3 downto 2);


end architecture bbbb;