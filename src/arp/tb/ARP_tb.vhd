--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   04:39:47 06/01/2015
-- Design Name:
-- Module Name:   C:/Users/Lydia/Desktop/Caltech Spring2015/EE119C/topics/TCP/ARP/ARP_tb.vhd
-- Project Name:  ARP
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: ARP
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.TCP_CONSTANTS.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY ARP_tb IS
END ARP_tb;

ARCHITECTURE behavior OF ARP_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT ARP
    PORT(
      CLK : in  STD_LOGIC;  -- global clock
      nRST: in  STD_LOGIC;  -- global reset, active low

      TXEN: out STD_LOGIC; -- transmission data ready for underlying layer (MAC)
      TXDU: out  STD_LOGIC_VECTOR (7 downto 0); -- transmission data bus to underlying layer
      TXIDLE: out STD_LOGIC;

      RXDU: in  STD_LOGIC_VECTOR (7 downto 0); -- receive data bus from the underlying layer
      RXER: in STD_LOGIC; -- Receive data error
      RXEOP: in STD_LOGIC; -- End of a packet

      RdU: in STD_LOGIC; -- Read pulse from MAC
      WrU: in STD_LOGIC; -- Write pulse from MAC

      DST_MAC_ADDR :  out MAC_ADDR_TYPE;
      RequestIP: in IP_ADDR_TYPE;
      RequestValid: in STD_LOGIC;

      ResponseIP: out IP_ADDR_TYPE;
      ResponseMAC: out MAC_ADDR_TYPE;
      ResponseValid: out STD_LOGIC
    );
    END COMPONENT;

   --Inputs
   signal CLK : std_logic := '0';
   signal nRST : std_logic := '0';
   signal RXDU : std_logic_vector(7 downto 0) := (others => '0');
   signal RXER : std_logic := '0';
   signal RXEOP : std_logic := '0';
   signal RdU : std_logic := '0';
   signal WrU : std_logic := '0';

   signal RequestIP: IP_ADDR_TYPE := (X"12", X"34", X"56", X"78");
   signal RequestValid : std_logic := '0';

 	--Outputs
   signal TXEN : std_logic;
   signal TXDU : std_logic_vector(7 downto 0);
   signal RXDC : std_logic_vector(7 downto 0);
   signal ResponseIP: IP_ADDR_TYPE;
   signal ResponseMAC: MAC_ADDR_TYPE;
   signal ResponseValid: std_logic;
	
	type data_type is array (0 to 49) of std_logic_vector(7 downto 0);
	signal data: data_type := (X"00",X"01",X"08",X"00",X"06",X"04",X"00",X"02",X"54",X"42",X"49",X"62",X"6C",X"62",X"C0",X"A8",X"01",X"03",X"48",X"48",X"48",X"48",X"48",X"48",X"C0",X"A8",X"01",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"8E",X"90",X"26",X"5B");

   -- Clock period definitions
   constant CLK_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: ARP PORT MAP (
          CLK => CLK,
          nRST => nRST,
          TXEN => TXEN,
          TXDU => TXDU,
          RXDU => RXDU,
          RXER => RXER,
          RXEOP => RXEOP,
          RdU => RdU,
          WrU => WrU,
          DST_MAC_ADDR => open,
          RequestIP => RequestIP,
          RequestValid => RequestValid,
          ResponseIP => ResponseIP,
          ResponseMAC => ResponseMAC,
          ResponseValid => ResponseValid
    );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;


   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
    nRST <= '0';

    wait for 100 ns;

    nRST <= '1';

    wait for CLK_period*10;

    RequestValid <= '1';

	 wait for CLK_period;

    RequestValid <= '0';
	 RXDU <= data(0);
	 
	 for i in 0 to 48 loop
		RdU <= '1';
		WrU <= '1';
		wait for CLK_period;
		RXDU <= data(i + 1);
		RdU <= '0';
		WrU <= '0';
		wait for CLK_period * 39;
	end loop;
	
	RdU <= '1';
	WrU <= '1';
	wait for CLK_period;
	RdU <= '0';
	WrU <= '0';
	wait for CLK_period * 39;
	
	RXEOP <= '1';
	RdU <= '1';
	WrU <= '1';
	wait for CLK_period;
	RXEOP <= '0';
	RdU <= '0';
	WrU <= '0';
	wait for CLK_period * 39;

		for i in 0 to 1000 loop
			RdU <= '1';
			WrU <= '1';
			wait for CLK_period;
			RdU <= '0';
			WrU <= '0';
			wait for CLK_period * 39;
		end loop;

		wait;

   end process;

END;
