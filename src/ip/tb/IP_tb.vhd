--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:34:58 10/06/2015
-- Design Name:
-- Module Name:   E:/Github/tcp_rebuild/src/ip/tb/IP_tb.vhd
-- Project Name:  tcp_rebuild
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: IP
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
use work.TCP_CONSTANTS.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY IP_tb IS
END IP_tb;

ARCHITECTURE behavior OF IP_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT IP
    PORT(
         CLK : IN  std_logic;
         nRST : IN  std_logic;
         TXDV : IN  std_logic;
         TXEN : OUT  std_logic;
         TXDC : IN  std_logic_vector(7 downto 0);
         TXDU : OUT  std_logic_vector(7 downto 0);
         TXIDLE : OUT  std_logic;
         RdC : OUT  std_logic;
         RdU : IN  std_logic;
         DST_IP_ADDR : IN  IP_ADDR_TYPE;
         TX_DataLength : IN  std_logic_vector(15 downto 0);
         DST_MAC_ADDR : OUT  MAC_ADDR_TYPE;
         MACLookUp_InputIP : OUT  IP_ADDR_TYPE;
         MACLookUp_Start : OUT  std_logic;
         MACLookUp_OutputMAC : in  MAC_ADDR_TYPE;
         MACLOokUP_OutputValid : in  std_logic;
         RXDC : OUT  std_logic_vector(7 downto 0);
         RXDU : IN  std_logic_vector(7 downto 0);
         WrC : OUT  std_logic;
         WrU : IN  std_logic;
         RXER : IN  std_logic;
         RXEOP : IN  std_logic;
			   RXER_out : OUT  std_logic;
         RXEOP_out : OUT  std_logic;
         RX_SRC_IP_ADDR : out IP_ADDR_TYPE;
         TX_PROTOCOL : IN  L4_PROTOCOL;
         RX_PROTOCOL : OUT  L4_PROTOCOL
        );
    END COMPONENT;


   --Inputs
   signal CLK : std_logic := '0';
   signal nRST : std_logic := '0';
   signal TXDV : std_logic := '0';
   signal TXDC : std_logic_vector(7 downto 0) := (others => '0');
   signal RdU : std_logic := '0';
   signal DST_IP_ADDR : IP_ADDR_TYPE;
   signal TX_DataLength : std_logic_vector(15 downto 0) := (others => '0');
   signal RXDU : std_logic_vector(7 downto 0) := (others => '0');
   signal WrU : std_logic := '0';
   signal RXER : std_logic := '0';
   signal RXEOP : std_logic := '0';
   signal TX_PROTOCOL : L4_PROTOCOL;

 	--Outputs
   signal TXEN : std_logic;
   signal TXDU : std_logic_vector(7 downto 0);
   signal TXIDLE : std_logic;
   signal RdC : std_logic;
   signal DST_MAC_ADDR : MAC_ADDR_TYPE;
   signal MACLookUp_InputIP : IP_ADDR_TYPE;
   signal MACLookUp_Start : std_logic;
   signal MACLookUp_OutputMAC : MAC_ADDR_TYPE;
   signal MACLOokUP_OutputValid : std_logic;
   signal RXDC : std_logic_vector(7 downto 0);
   signal WrC : std_logic;
   signal RX_PROTOCOL : L4_PROTOCOL;
   signal RXER_out : std_logic;
   signal RXEOP_out : std_logic;
   signal RX_SRC_IP_ADDR : IP_ADDR_TYPE;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;


   type RX_DATA_TYPE is array (0 to 68) of std_logic_vector(7 downto 0);
   signal RX_DATA: RX_DATA_TYPE := (X"45",X"00",X"00",X"41",X"00",X"00",X"00",X"00",X"07",X"1b",X"31",X"48",X"c0",X"a8",X"00",X"03",X"c0",X"a8",X"01",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"f6",X"4d",X"2f",X"21");

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: IP PORT MAP (
          CLK => CLK,
          nRST => nRST,
          TXDV => TXDV,
          TXEN => TXEN,
          TXDC => TXDC,
          TXDU => TXDU,
          TXIDLE => TXIDLE,
          RdC => RdC,
          RdU => RdU,
          DST_IP_ADDR => DST_IP_ADDR,
          TX_DataLength => TX_DataLength,
          DST_MAC_ADDR => DST_MAC_ADDR,
          MACLookUp_InputIP => MACLookUp_InputIP,
          MACLookUp_Start => MACLookUp_Start,
          MACLookUp_OutputMAC => MACLookUp_OutputMAC,
          MACLOokUP_OutputValid => MACLOokUP_OutputValid,
          RXDC => RXDC,
          RXDU => RXDU,
          WrC => WrC,
          WrU => WrU,
          RXER => RXER,
          RXEOP => RXEOP,
          RXER_out => RXER_out,
          RXEOP_out => RXEOP_out,
          RX_SRC_IP_ADDR => RX_SRC_IP_ADDR,
          TX_PROTOCOL => TX_PROTOCOL,
          RX_PROTOCOL => RX_PROTOCOL
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

	MACLookUP_proc : process
	begin
		MACLookUp_OutputMAC <= (others => X"FF");
    MACLookUp_OutputValid <= '0';

    wait until MACLookUp_Start = '1';

    wait for CLK_period * 10;

    MACLookUP_OutputMAC <= VAIO_MAC_ADDR;
    MACLookUP_OutputValid <= '1';

    wait for CLK_period;
	end process;

   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
      nRST <= '0';
      wait for 100 ns;
      nRST <= '1';

      wait for CLK_period*10;
      DST_IP_ADDR <= (X"C0",X"A8",X"01",X"03");
      TX_DataLength <= X"0001";
      TX_PROTOCOL <= TCP;
      TXDV <= '1';

      for i in 0 to 9 loop
        wait until RdC = '1';
        wait until RdC = '0';
      end loop;

      TXDV <= '0';
      -- insert stimulus here

      wait;
   end process;

   RdU_proc : process
   begin
      if (TXEN = '1') then
        RdU <= '0';
        wait for CLK_period * 9;
        RdU <= '1';
        wait for CLK_period * 1;
      else
        RdU <= '0';
        wait for CLK_period;
      end if;
   end process;

   RX_proc: process
   begin
    wait for 1000 ns;
    for i in 0 to 68 loop
      RXDU <= RX_DATA(i);
      WrU <= '0';
      wait for CLK_period * 9;
      WrU <= '1';
      wait for CLK_period * 1;
    end loop;
    WrU <= '0';
    wait for CLK_period * 20;
    RXEOP <= '1';
    wait for CLK_period;
    RXEOP <= '0';
    wait;
   end process;
END;
