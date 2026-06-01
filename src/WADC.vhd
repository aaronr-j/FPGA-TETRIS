library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WADC is 
	port (
		MAX10_CLK1_50 : in std_logic;
		ADC_CLK_10 : in std_logic;
		KEY : in std_logic_vector(1 downto 0);
		control : out std_logic_vector(11 downto 0)
		
	);
end;

architecture behavior of WADC is
		type the_state is (IDLE, SEND);
		
		component PLL
			PORT
			(
				areset		: IN STD_LOGIC  := '0';
				inclk0		: IN STD_LOGIC  := '0';
				c0		: OUT STD_LOGIC ;
				locked		: OUT STD_LOGIC 
			);
		end component;
	
		component our_adc is
			port (
				adc_pll_clock_clk      : in  std_logic                     := 'X';             -- clk
				adc_pll_locked_export  : in  std_logic                     := 'X';             -- export
				clock_clk              : in  std_logic                     := 'X';             -- clk
				command_valid          : in  std_logic                     := 'X';             -- valid
				command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
				command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
				command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
				command_ready          : out std_logic;                                        -- ready
				reset_sink_reset_n     : in  std_logic                     := 'X';             -- reset_n
				response_valid         : out std_logic;                                        -- valid
				response_channel       : out std_logic_vector(4 downto 0);                     -- channel
				response_data          : out std_logic_vector(11 downto 0);                    -- data
				response_startofpacket : out std_logic;                                        -- startofpacket
				response_endofpacket   : out std_logic                                         -- endofpacket
			);
		end component our_adc;
		
	
	
	
	
	
	signal pll_locked : std_logic;
	signal counter : integer := 0;
	signal state : the_state;
	signal dummy, locked : integer;
	signal c10 : std_logic;
	signal reset_n : std_logic;
	signal valid, startofpacket, endofpacket, sink_reset : std_logic;
	signal ready, rsp_valid,  rs_sop, rs_eop : std_logic;
	signal rsp_channel, channel : std_logic_vector(4 downto 0);
	signal data : std_logic_vector(11 downto 0);
	signal buf : std_logic_vector(11 downto 0);
		
	begin
		P1: PLL
			port map(
			areset => '0',
			inclk0 => MAX10_CLK1_50,
			c0 => c10,
			locked => pll_locked
		);
		
		ADC1: our_adc
			port map(
				adc_pll_clock_clk      => c10,                               
				adc_pll_locked_export  => pll_locked,                             
				clock_clk   			  => MAX10_CLK1_50,               
				command_valid          => valid,                         
				command_channel        => "00001",
				command_startofpacket  => startofpacket,                            
				command_endofpacket    => endofpacket,                         
				command_ready          => ready,                                        
				reset_sink_reset_n     => reset_n,                        
				response_valid         => rsp_valid,                                      
				response_channel       => open,                     
				response_data          => buf,                   
				response_startofpacket => open,                                      
				response_endofpacket   => open                                       
			);
		
		
		process(MAX10_CLK1_50)
		begin
		
			if rising_edge(MAX10_CLK1_50) then
				if KEY(0) = '0' then
					valid <= '0';
					state <= IDLE;
					data <= "000000000000";
					counter <= 0;
					startofpacket <= '0';
					endofpacket <= '0';
				else
					case(state) is
						when IDLE =>
							
							counter <= counter + 1;
							dummy <= 0;
							if counter > 5000 then
								valid <= '1';
							end if;
							if ready = '1' then
								state <= SEND;
							end if;


						when SEND =>

							valid <= '0';
							dummy <= 1;

							
							if rsp_valid = '1' then
								state <= IDLE;
								counter <= 0;
								data <= buf;
							end if;
					end case;
				end if;
			
			end if;
			
			
		end process;
		reset_n <= KEY(0) and pll_locked;

		locked <= 1 when pll_locked = '1' else 0;
		control <= data;
		
end architecture behavior;