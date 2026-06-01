library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.board_type.all;


entity video is
  port (
    clk : in std_logic;
    reset_n : in std_logic;
    x : in integer;    -- x,y are counters from vga module
    y : in integer;
    visible : in std_logic;             --from vga module. are we in pixel data portion
    board : in board;                --board
    block_x : in integer range 0 to 8; --the aactive block
    block_y : in integer range 0 to 13;
    block_color : in std_logic_vector(11 downto 0);
	 score : in integer range 0 to 999999;
    
    r, g, b : out std_logic_vector(3 downto 0)
  );
 end;

 architecture rgb of video is 
 
 	component bitmap
	PORT(
		digit : in integer;
		row : in integer;
		pixel_data : out std_logic_vector(9 downto 0)
	);
	end component;

    constant CELL_SIZE : integer := 32;    -- BLOCK SIZE
    constant X0 : integer := 176;  -- x START position for grid (white lines)
    constant Y0 : integer := 60;   -- y START position for grid (white lines)

    signal cell_x : integer range -1 to 8 := -1;    -- grid of board
    signal cell_y : integer range -1 to 13 := -1;   -- grid of board
    signal on_grid, in_grid, score_area : std_logic := '0';              -- are we in the game grid?  
    signal occupied : std_logic := '0';             -- is the grid space occupied

    signal final_color : std_logic_vector(11 downto 0);
	 
	 signal px, py : integer;
	 
	 signal single_score : integer range 0 to 9 := 0;
	 signal row : integer range 0 to 9 := 0;
	 signal score_pixel_data : std_logic_vector(9 downto 0);
	 signal score_d : std_logic := '0';
	 signal single_digit : integer := 0;
	 signal s1, s2, s3, s4, s5, s6 : integer := 0;
	 
	 
	 signal draw_score : std_logic := '0';

    begin  
	 			bmp : bitmap
				PORT map(
					digit => single_digit,
					row => row,
					pixel_data => score_pixel_data
			);
        -- this process determines if we are in the grid or not
        process(clk)
        begin
				if (rising_edge(clk)) then
					--converts x and y to integers
					px <= x;
					py <= y; 
				end if;
			end process;
			
			process(clk)
			begin
				if rising_edge(clk) then
						in_grid <= '0';
						 on_grid <= '0';
						 cell_x <= -1;
						 cell_y <= -1;
						 score_d <= '0';
					--vert lines
					if (px = X0-1 or px = X0+288) and (py >= Y0-1 and py <= Y0+448) then
						on_grid <= '1';
						
					--horizontal lines
					elsif (py = Y0+448) and (px >= X0-1 and px <= X0+288) then
						on_grid <= '1';
					--inside grid
					elsif (px >= X0) and (px < X0 + 288) and (py >= Y0) and (py < Y0 + 448) then
						 in_grid <= '1';
						 cell_x <= (px - X0) / CELL_SIZE;
						 cell_y <= (py - Y0) / CELL_SIZE;
					elsif (px > 496 and px <= 506) and (py >= 200 and py < 210) then
						score_d <= '1';
						single_digit <= s6;
						row <= (py - 200);
						draw_score <= score_pixel_data(506-px);
					elsif (px > 508 and px <= 518) and (py >= 200 and py < 210) then
						score_d <= '1';
						single_digit <= s5;
						row <= (py - 200);
						draw_score <= score_pixel_data(518-px);
					elsif (px > 520 and px <= 530) and (py >= 200 and py < 210) then
						score_d <= '1';
						single_digit <= s4;
						row <= (py - 200);
						draw_score <= score_pixel_data(530-px);
					elsif (px > 532 and px <= 542) and (py >= 200 and py < 210) then
						score_d <= '1';
						single_digit <= s3;
						row <= (py - 200);
						draw_score <= score_pixel_data(542-px);
					elsif (px > 544 and px <= 554) and (py >= 200 and py < 210)then
						score_d <= '1';
						single_digit <= s2;
						row <= (py - 200);
						draw_score <= score_pixel_data(554-px);
					elsif (px > 556 and px <= 566) and (py >= 200 and py < 210) then
						score_d <= '1';
						single_digit <= s1;
						row <= (py - 200);
						draw_score <= score_pixel_data(566-px);

						 --
					end if;
				end if;
        end process;

        process(clk)
        begin
			if rising_edge(clk) then
				final_color <= (others => '0');

            if in_grid = '1' then
                final_color <= board(cell_y)(cell_x); -- final color is gathered from the board array

                if (cell_x = block_x) and (cell_y = block_y) then
                    final_color <= block_color;
                end if;
				elsif on_grid = '1' then
					final_color <= (others => '1');
					
				elsif score_d = '1' then
					final_color <= (others => draw_score);
					
					
            else    -- if its outside of the gird. need to add score drawing here.
                final_color <= (others => '0');
            end if;
			end if;
        end process;

        process(clk, reset_n)
        begin
            if reset_n = '0' then
                r <= (others => '0');
                g <= (others => '0');
                b <= (others => '0');
            elsif rising_edge(clk) then
                if visible = '1' then      --if x and y are in the grid we need to draw the colors
                        r <= final_color(11 downto 8);  --final color is gathered from the board array
                        g <= final_color(7 downto 4);
                        b <= final_color(3 downto 0);
                else
                    r <= (others => '0');
                    g <= (others => '0');
                    b <= (others => '0');
                end if;
                        
            end if;
        end process;
		  
		  process(score)
		  begin
				s1 <= score mod 10;
				s2 <= (score / 10) mod 10;
				s3 <= (score / 100) mod 10;
				s4 <= (score / 1000) mod 10;
				s5 <= (score / 10000) mod 10;
				s6 <= (score / 100000) mod 10;
				
		  end process;
		  
end architecture rgb;