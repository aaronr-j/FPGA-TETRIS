library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity VGA_FLAGS is
	port (
		MAX10_CLK1_50 : in std_logic;
		KEY : in std_logic_vector(1 downto 0);
		
		VGA_VS : out std_logic;
		VGA_HS : out std_logic;
		VGA_B  : out std_logic_vector(3 downto 0);
		VGA_G  : out std_logic_vector(3 downto 0);
		VGA_R  : out std_logic_vector(3 downto 0);
		
		
		counter_x : out integer;
		counter_y : out integer;
		visible : out std_logic;
		pll_clk : out std_logic
	);
end;



architecture bhr of VGA_FLAGS is
	component PLL
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
	end component;
	type line_state_type is (A,B,C,D);
	signal c25, pll_locked, dbb : std_logic;
	signal counter_h : integer range 0 to 1000;
	signal counter_v : integer range 0 to 1000;
	signal counter, state_btn, l_limit, u_limit : integer;
	signal state_line : line_state_type;
	signal line_data : std_logic_vector(13 downto 0);
	signal clock_link : std_logic;
	begin
		P1: PLL
			port map(
			areset => '0',
			inclk0 => MAX10_CLK1_50,
			c0 => c25,
			locked => pll_locked
		);
		
		process(c25, KEY(0))
		begin
			if rising_edge(c25) then
				if KEY(0) = '0' then
						state_line <= A;
						VGA_B  <= "0000";
						VGA_G  <= "0000";
						VGA_R  <= "0000";
						line_data(13 downto 12) <= "00";
						counter_h <= 0;
						counter_v <= 0;
						counter <= 0;
						dbb <= '0';
				else
					case(state_btn) is
						when 0 =>
							if KEY(1) = '0' then
								state_btn <= 1;
								counter <= 0;
							else
								state_btn <= 0;
							end if;
							dbb <= '0';
						when 1 =>
							if counter < 10 then
								counter <= counter + 1;
							else
								if KEY(1) = '0' then
									dbb <= '1';
									state_btn <= 2;
								else
									state_btn <= 0;
								end if;
							end if;
						when 2 =>
							dbb <= '0';
							if KEY(1) = '1' then
								state_btn <= 0;
							end if;
						when others =>
						state_btn <= 0;
					end case;
					
					case(state_line) is
						when A =>
						
							line_data(12) <= '0';
							
							if counter_h < 16 then
								counter_h <= counter_h + 1;
							else
								state_line <= B;
								counter_h <= 0;
							end if;
							
						when B =>
						
							line_data(12) <= '1';
							
							if counter_h < 96 then
								counter_h <= counter_h + 1;
							else
								state_line <= C;
								counter_h <= 0;
							end if;
							
						when C =>
						
							line_data(12) <= '0';
							
							if counter_h < 48 then
								counter_h <= counter_h + 1;
							else
								state_line <= D;
								counter_h <= 0;
							end if;
							
						when D =>
						
							line_data(12) <= '0';
	
							if counter_v > 44 then
							visible <= '1';
								VGA_B  <= line_data(11 downto 8);
								VGA_G  <= line_data(7 downto 4);
								VGA_R  <= line_data(3 downto 0);
							end if;
							
							if counter_h < 640 then
								counter_h <= counter_h + 1;
							else
								visible <= '0';
								state_line <= A;
								counter_h <= 0;
								VGA_B  <= "0000";
								VGA_G  <= "0000";
								VGA_R  <= "0000";
								if counter_v < 525 then
									counter_v <= counter_v + 1;
								else
									counter_v <= 0;
								end if;
							end if;
							
						when others =>
							state_line <= A;
							VGA_B  <= "0000";
							VGA_G  <= "0000";
							VGA_R  <= "0000";
							counter_h <= 0;
							counter_v <= 0;
					end case;
					if counter_v < 487 and counter_v > 84 then -- outisde the U black parts
						if counter_h = 177 or counter_h = 463 then -- white vertical lines
							line_data(11 downto 0) <= (others => '1');
						else
							if counter_h >230 and counter_h < 262 and counter_v > 300 and counter_v < 332 then
								line_data(11 downto 0) <= "111100000000";
							else
								line_data(11 downto 0) <= (others => '0');
							end if;
						end if;
					elsif counter_v = 487 then
						if counter_h >= 177 and counter_h <= 463 then
							line_data(11 downto 0) <= (others => '1'); --white horizontal lines
						else
							line_data(11 downto 0) <= (others => '0');
						end if;
					end if;
						
					if (counter_v > 9) and (counter_v) < 12 then
						line_data(13) <= '1';
					else
						line_data(13) <= '0';
					end if;
				end if;
			end if;
		end process;
		
		VGA_VS <= not line_data(13);
		VGA_HS <= not line_data(12);
		counter_x <= counter_h;
		counter_y <= counter_v;
		pll_clk <= c25;
		
end architecture bhr;