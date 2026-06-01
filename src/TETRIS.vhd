library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity TETRIS is
	port (
	ADC_CLK_10 : in std_logic;
	MAX10_CLK1_50 : in std_logic;
	MAX10_CLK2_50 : in std_logic;
	KEY : in std_logic_vector(1 downto 0);
	SW : in std_logic_vector(9 downto 0);
	--LED
	LED : out std_logic_vector(9 downto 0);

	--SDRAM
	DRAM_ADDR : out std_logic_vector(12 downto 0);
	DRAM_BA : out std_logic_vector(1 downto 0);
	DRAM_CAS_N : out std_logic;
	DRAM_CKE: out std_logic;
	DRAM_CLK: out std_logic;
	DRAM_CS_N : out std_logic;
	DRAM_DQ : inout std_logic_vector(15 downto 0);		
	DRAM_LDQM : out std_logic;
	DRAM_RAS_N : out std_logic;
	DRAM_UDQM : out std_logic;
	DRAM_WE_N : out std_logic;

	--SEG7
	HEX0 : out std_logic_vector(7 downto 0);
	HEX1 : out std_logic_vector(7 downto 0);
	HEX2 : out std_logic_vector(7 downto 0);
	HEX3 : out std_logic_vector(7 downto 0);
	HEX4 : out std_logic_vector(7 downto 0);
	HEX5 : out std_logic_vector(7 downto 0);

	VGA_VS : out std_logic;
	VGA_HS : out std_logic;
	VGA_B  : out std_logic_vector(3 downto 0);
	VGA_G  : out std_logic_vector(3 downto 0);
	VGA_R  : out std_logic_vector(3 downto 0)

	);
end;


architecture game of TETRIS is
	type board_row is array(0 to 8) of std_logic_vector(11 downto 0);
	type board is array(0 to 13) of board_row;
	
	
	component PLL
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	end component;
	
	component VGA_FLAGS
	PORT(
		MAX10_CLK1_50 : in std_logic;
		KEY : in std_logic_vector(1 downto 0);
		
		VGA_VS : out std_logic;
		VGA_HS : out std_logic;
		VGA_B  : out std_logic_vector(3 downto 0);
		VGA_G  : out std_logic_vector(3 downto 0);
		VGA_R  : out std_logic_vector(3 downto 0);
		counter_x: out integer;
		counter_y: out integer;
		visible : out std_logic;
		pll_clk : out std_logic
	);
	end component;

	component video
	PORT(
		clk : in std_logic;
		reset_n : in std_logic;
		x : in integer;    -- x,y are counters from vga module
		y : in integer;
		visible : in std_logic;             --from vga module. are we in pixel data portion
		board : in board;                 --board
		block_x : in integer range 0 to 8; --the aactive block
		block_y : in integer range 0 to 13;
		block_color : in std_logic_vector(11 downto 0);
		score : in integer range 0 to 999999;
		
		r, g, b : out std_logic_vector(3 downto 0)
	);
	end component;
	
	component game_logic
	port(
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
	end component;
	

	
		

	signal game_board : board;
	--signal game_board : board := (others => (others => (others => '0')));

	signal active_x : integer range -1 to 8;
	signal active_y : integer range -1 to 13;
	signal active_color : std_logic_vector(11 downto 0) := (others => '0');
	signal x : integer;
	signal y : integer;
	signal visible : std_logic;
	signal VGA_B1, VGA_B2, VGA_B3: std_logic_vector(3 downto 0);
	signal r, g, b : std_logic_vector(3 downto 0);
	signal pll_clk : std_logic;
	signal c25, pll_locked : std_logic;
	signal score : integer range 0 to 999999 := 0;


	
	begin
		VGA: VGA_FLAGS
			port map(
				MAX10_CLK1_50 => MAX10_CLK1_50,
				KEY => KEY,
				VGA_VS => VGA_VS,
				VGA_HS => VGA_HS,
				VGA_B  => VGA_B1,
				VGA_G  => VGA_B2,
				VGA_R  => VGA_B3,
				counter_x => x,
				counter_y => y,
				visible => visible
			);

		VID: video
			port map(
				clk => c25,
				reset_n => KEY(0),
				x => x,    -- x,y are counters from vga module
				y => y,
				visible => visible,        --from vga module. are we in pixel data portion
				board => game_board,                 --board
				block_x => active_x, --the aactive block
				block_y => active_y,
				block_color => active_color,
				score => score,
				r => VGA_R,
				g => VGA_G,
				b => VGA_B
			);
			
			P1: PLL
				port map(
				areset => '0',
				inclk0 => MAX10_CLK1_50,
				c0 => c25,
				locked => pll_locked
			);
			
			gam: game_logic
				port map(
					clk => c25,
					game_board => game_board,
					reset => KEY(0),
					start => KEY(1),
					
					block_x => active_x,
					block_y => active_y,
					active_color => active_color,
					score => score,
					clk50 => MAX10_CLK1_50,
					clkADC => ADC_CLK_10
				);
		
			
			process(MAX10_CLK1_50)
			begin
			
			if rising_edge(MAX10_CLK1_50) then
				if KEY(0) = '0' then
					--game_board <= (others => (others => (others => '0')));
				end if;
					
			-- if visible = '1' then
			-- 	if y < 487 and y > 84 then -- outisde the U black parts
			-- 		if x = 177 or x = 463 then -- white vertical lines
			-- 			line_data(11 downto 0) <= (others => '1');
			-- 		else
			-- 			if x >230 and x < 262 and y > 300 and y < 332 then
			-- 				line_data(11 downto 0) <= "111100000000";
			-- 			else
			-- 				line_data(11 downto 0) <= (others => '0');
			-- 			end if;
			-- 		end if;
			-- 	elsif y = 487 then
			-- 		if x >= 177 and x <= 463 then
			-- 			line_data(11 downto 0) <= (others => '1'); --white horizontal lines
			-- 		else
			-- 			line_data(11 downto 0) <= (others => '0');
			-- 		end if;
					
			-- 	end if;
			-- else
			-- 	line_data <= "000000000000";

			end if;
			end process;
			
			-- VGA_B  <= line_data(11 downto 8);
			-- VGA_G  <= line_data(7 downto 4);
			-- VGA_R  <= line_data(3 downto 0);
	

end architecture game;



