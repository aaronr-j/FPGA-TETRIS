library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.board_type.all;

entity game_logic is
	port (
		clk : in std_logic;
		game_board : out board;
		reset : in std_logic;
		start : in std_logic;
		
		block_x : out integer range -1 to 8;
		block_y : out integer range -1 to 13;
		active_color : out std_logic_vector(11 downto 0);
		score : out integer range 0 to 999999;
		clk50 : in std_logic;
		clkADC : in std_logic
	);
		
end;

architecture game of game_logic is
	component WADC
		port (
			MAX10_CLK1_50 : in std_logic;
			ADC_CLK_10 : in std_logic;
			KEY : in std_logic_vector(1 downto 0);
			control : out std_logic_vector(11 downto 0)
		);
	end component;
	
	component RNG
		port (
			clk : in std_logic;
			color_out: out std_logic_vector(1 downto 0);
			KEY : in std_logic_vector(1 downto 0)
		);
	
	end component;
	
	type game_state is (falling, setclear, checking, fall_all, check_all, clear, spawn, end_game);
	type clear_row is array (0 to 8) of std_logic;
	type clear_grid is array (0 to 13) of clear_row;

	signal active_block : std_logic := '0';
	signal counter : integer := 0;
	signal total_score, t_score : integer := 0;
	signal blocks_stable : std_logic := '0';
	
	signal color : std_logic_vector(11 downto 0);
	signal state : game_state;
	signal active_x: integer range -1 to 8 := -1;
	signal active_y: integer range -1 to 13 := -1;
	signal g_board : board := (others => (others => (others => '0')));
	signal v_counter : integer;
	signal h_counter : integer;
	signal counting : integer;
	signal clear_blocks : clear_grid;
	signal block_moved : std_logic;
	signal color_out : std_logic_vector(1 downto 0);
	signal rst : std_logic;
	signal control : std_logic_vector(11 downto 0);
	signal counter_controller : integer;
	signal block_cleared : std_logic := '0';
	
	begin
	
		rngesus : RNG
			port map(
				clk => clk,
				color_out => color_out,
				KEY(0) => reset
			);
			
		controller : WADC
			port map(
				MAX10_CLK1_50 => clk50,
				ADC_CLK_10 => clkADC,
				KEY(0) => reset,
				control => control
			);
				
	process(clk)
		variable k : integer;
		variable colr : std_logic_vector(11 downto 0);
	begin
		if rising_edge(clk) then
			if reset = '0' then
				state <= end_game;
				total_score <= 0;
				active_x <= -1;
				active_y <= -1;
				block_cleared <= '0';
				g_board <= (others => (others => (others => '0')));
			else
				case(state) is
					when end_game =>
						if start = '0' then
							state <= spawn;
						end if;
						
					when spawn =>
						active_block <= '1';
						active_x <= 4;
						active_y <= 0;
						state <= falling;
						counter <= 0;
						counter_controller <= 0;
						t_score <= 0;
						-- active_color <= randomly generated color
						case(color_out) is
							when "00" =>
								color <= "000011110000";
							when "01" =>
								color <= "111100000000";
							when "10" =>
								color <= "000000001111";
							when "11" =>
								color <= "111111110000";
							when others =>
								color <= "111111111111";
							end case;
							
					when falling =>
--						if to_integer(to_unsigned(control)) <= 455 then
--							active_x <= 0;
--						elsif to_integer(to_unsigned(control)) > 455 and to_integer(to_unsigned(control)) <= 910 then
--							active_x <= 1;
--						elsif to_integer(to_unsigned(control)) > 910 and to_integer(to_unsigned(control)) <= 1365 then
--							active_x <= 2;
--						elsif to_integer(to_unsigned(control)) > 1365 and to_integer(to_unsigned(control)) <= 1820 then
--							active_x <= 3;
--						elsif to_integer(to_unsigned(control)) > 1820 and to_integer(to_unsigned(control)) <= 2275 then
--							active_x <= 4;
--						elsif to_integer(to_unsigned(control)) > 2275 and to_integer(to_unsigned(control)) <= 2730 then
--							active_x <= 5;
--						elsif to_integer(to_unsigned(control)) > 2730 and to_integer(to_unsigned(control)) <= 3185 then
--							active_x <= 6;
--						elsif to_integer(to_unsigned(control)) > 3185 and to_integer(to_unsigned(control)) <= 3640 then
--							active_x <= 7;
--						else
--							active_x <= 8;
--						end if;

						if counter_controller = 6250000 then
							if to_integer(unsigned(control)) <= 1365 and active_x > 0 then
								if g_board(active_y)(active_x - 1) = "000000000000" then
									active_x <= active_x - 1;
								end if;
							elsif to_integer(unsigned(control)) > 2730 and active_x < 8 then
								if g_board(active_y)(active_x + 1) = "000000000000" then
									active_x <= active_x + 1;
								end if;
							end if;
							counter_controller <= 0;
						else
							counter_controller <= counter_controller + 1;
						end if;
						
						if counter = 12500000 then
							if active_y = 13 then --if at bottom
								state <= setclear;
								active_block <= '0';
								h_counter <= 0;
								v_counter <= 0;
								g_board(active_y)(active_x) <= color;
							elsif not (g_board(active_y + 1)(active_x) = "000000000000") then
								-- add check for too high => game over
								if active_y <= 2 then
									state <= end_game;
								else
									g_board(active_y)(active_x) <= color;
									state <= setclear;
									active_block <= '0';
									h_counter <= 0;
									v_counter <= 0;
									t_score <= 0;
								end if;
								
							else
								active_y <= active_y + 1;
								
							end if;
							counter <= 0;
							
						else
							counter <= counter + 1;
						end if;
					
					--resets the clear_blocks grid
					when setclear => 
						if h_counter < 9 then
							if v_counter < 14 then
								clear_blocks(v_counter)(h_counter) <= '0';
								v_counter <= v_counter + 1;
							else
								v_counter <= 0;
								h_counter <= h_counter + 1;
							end if;
						else
							state <= checking;
							h_counter <= 0;
							v_counter <= 0;
						end if;
						
					--checks for blocks to be cleared. sets them in reset grid.
					when checking => 
						for row in 0 to 13 loop
							for col in 0 to 8 loop
								colr := g_board(row)(col);
								
								if not (colr = "000000000000") then
									if col <= 6 then
										if (g_board(row)(col + 1) = colr) and
												(g_board(row)(col + 2) = colr) then
											k := col;
											
											while (k <= 8) and (g_board(row)(k) = colr) loop
												clear_blocks(row)(k) <= '1';	--set matching colors in col to clear
												k := k + 1;
											end loop;
										end if;
									end if;
									
									if row <= 11 then
										if (g_board(row + 1)(col) = colr) and
												(g_board(row + 2)(col) = colr) then
												
											k := row;
												
											while (k <= 13) and (g_board(k)(col) = colr) loop
												clear_blocks(k)(col) <= '1';	--set matching colors in row to clear
												k := k + 1;
											end loop;
										end if;
									end if;
								end if;
							end loop;
						end loop;
						state <= clear;
						
					when clear =>
						if h_counter < 9 then
							if v_counter < 14 then
								if clear_blocks(v_counter)(h_counter) = '1' then
									g_board(v_counter)(h_counter) <= (others => '0');
									block_cleared <= '1';
									t_score <= t_score + 1;
									
								end if;
								v_counter <= v_counter + 1;
							else
								v_counter <= 0;
								h_counter <= h_counter + 1;

							end if;
						else
							state <= fall_all;
							h_counter <= 8;
							v_counter <= 13;
							blocks_stable <= '1';
							total_score <= total_score + t_score;
						end if;
				
					-- goes through the grid and checks for empty spaces. makes blocks fall if it is empty
					when fall_all =>
						if h_counter >= 0 then
							if v_counter > 0 then
								if (g_board(v_counter)(h_counter) = "000000000000") and 
									(not (g_board(v_counter - 1)(h_counter) = "000000000000")) then --if the current block is empty and the space above is not empty, fall
									g_board(v_counter)(h_counter) <= g_board(v_counter - 1)(h_counter);
									g_board(v_counter - 1)(h_counter) <= "000000000000";
									blocks_stable <= '0';
								end if;
								v_counter <= v_counter - 1;
							else
								v_counter <= 13;
								h_counter <= h_counter - 1;
							end if;
						else
							state <= check_all;
							h_counter <= 8;
							v_counter <= 13;
						end if;
						
						
					when check_all =>
						if blocks_stable = '1' then
							if block_cleared = '0' then
								state <= spawn;
							else
								state <= setclear;
								h_counter <= 0;
								v_counter <= 0;
								block_cleared <= '0';
							end if;
						else
							state <= fall_all;
							blocks_stable <= '1';
						end if;
						
					when others =>
				end case;
			end if;
				
				
		end if;
	end process;
	
	active_color <= color;
	block_x <= active_x;
	block_y <= active_y;
	game_board <= g_board;
	score <= total_score;

				
					
					
	
	

end architecture;