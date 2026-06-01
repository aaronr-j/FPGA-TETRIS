library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package board_type is 
	type board_row is array(0 to 8) of std_logic_vector(11 downto 0);
	type board is array(0 to 13) of board_row;
end package ;
