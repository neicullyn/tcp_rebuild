--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   12:12:49 10/07/2015
-- Design Name:
-- Module Name:   E:/Github/tcp_rebuild/src/shell_tb.vhd
-- Project Name:  tcp_rebuild
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: shell
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY shell_tb IS
END shell_tb;

ARCHITECTURE behavior OF shell_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT shell
    PORT(
         CLK : IN  std_logic;
         SW : IN  std_logic_vector(7 downto 0);
         BTN : IN  std_logic_vector(4 downto 0);
         SSEG_CA : OUT  std_logic_vector(7 downto 0);
         SSEG_AN : OUT  std_logic_vector(3 downto 0);
         LED : OUT  std_logic_vector(7 downto 0);
         UART_RXD : IN  std_logic;
         UART_TXD : OUT  std_logic;
         RAM_ADDR : OUT  std_logic_vector(25 downto 0);
         RAM_DATA : INOUT  std_logic_vector(15 downto 0);
         RAM_CLK_out : OUT  std_logic;
         RAM_nCE : OUT  std_logic;
         RAM_nWE : OUT  std_logic;
         RAM_nOE : OUT  std_logic;
         RAM_nADV : OUT  std_logic;
         RAM_CRE : OUT  std_logic;
         RAM_nLB : OUT  std_logic;
         RAM_nUB : OUT  std_logic;
         RAM_WAIT_in : IN  std_logic;
         PHY_MDIO : INOUT  std_logic;
         PHY_MDC : OUT  std_logic;
         PHY_nRESET : OUT  std_logic;
         PHY_COL : IN  std_logic;
         PHY_CRS : IN  std_logic;
         PHY_TXD : OUT  std_logic_vector(3 downto 0);
         PHY_nINT : OUT  std_logic;
         PHY_TXEN : OUT  std_logic;
         PHY_TXCLK : IN  std_logic;
         PHY_RXD : IN  std_logic_vector(3 downto 0);
         PHY_RXER : IN  std_logic;
         PHY_RXDV : IN  std_logic;
         PHY_RXCLK : IN  std_logic
        );
    END COMPONENT;


   --Inputs
   signal CLK : std_logic := '0';
   signal SW : std_logic_vector(7 downto 0) := (others => '0');
   signal BTN : std_logic_vector(4 downto 0) := (others => '0');
   signal UART_RXD : std_logic := '0';
   signal RAM_WAIT_in : std_logic := '0';
   signal PHY_COL : std_logic := '0';
   signal PHY_CRS : std_logic := '0';
   signal PHY_TXCLK : std_logic := '0';
   signal PHY_RXD : std_logic_vector(3 downto 0) := (others => '0');
   signal PHY_RXER : std_logic := '0';
   signal PHY_RXDV : std_logic := '0';
   signal PHY_RXCLK : std_logic := '0';

	--BiDirs
   signal RAM_DATA : std_logic_vector(15 downto 0);
   signal PHY_MDIO : std_logic;

 	--Outputs
   signal SSEG_CA : std_logic_vector(7 downto 0);
   signal SSEG_AN : std_logic_vector(3 downto 0);
   signal LED : std_logic_vector(7 downto 0);
   signal UART_TXD : std_logic;
   signal RAM_ADDR : std_logic_vector(25 downto 0);
   signal RAM_CLK_out : std_logic;
   signal RAM_nCE : std_logic;
   signal RAM_nWE : std_logic;
   signal RAM_nOE : std_logic;
   signal RAM_nADV : std_logic;
   signal RAM_CRE : std_logic;
   signal RAM_nLB : std_logic;
   signal RAM_nUB : std_logic;
   signal PHY_MDC : std_logic;
   signal PHY_nRESET : std_logic;
   signal PHY_TXD : std_logic_vector(3 downto 0);
   signal PHY_nINT : std_logic;
   signal PHY_TXEN : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
   constant PHY_period : time := 1000 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: shell PORT MAP (
          CLK => CLK,
          SW => SW,
          BTN => BTN,
          SSEG_CA => SSEG_CA,
          SSEG_AN => SSEG_AN,
          LED => LED,
          UART_RXD => UART_RXD,
          UART_TXD => UART_TXD,
          RAM_ADDR => RAM_ADDR,
          RAM_DATA => RAM_DATA,
          RAM_CLK_out => RAM_CLK_out,
          RAM_nCE => RAM_nCE,
          RAM_nWE => RAM_nWE,
          RAM_nOE => RAM_nOE,
          RAM_nADV => RAM_nADV,
          RAM_CRE => RAM_CRE,
          RAM_nLB => RAM_nLB,
          RAM_nUB => RAM_nUB,
          RAM_WAIT_in => RAM_WAIT_in,
          PHY_MDIO => PHY_MDIO,
          PHY_MDC => PHY_MDC,
          PHY_nRESET => PHY_nRESET,
          PHY_COL => PHY_COL,
          PHY_CRS => PHY_CRS,
          PHY_TXD => PHY_TXD,
          PHY_nINT => PHY_nINT,
          PHY_TXEN => PHY_TXEN,
          PHY_TXCLK => PHY_TXCLK,
          PHY_RXD => PHY_RXD,
          PHY_RXER => PHY_RXER,
          PHY_RXDV => PHY_RXDV,
          PHY_RXCLK => PHY_RXCLK
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

   PHY_TXCLK_process :process
   begin
    wait for PHY_period / 4;
		PHY_TXCLK <= '0';
		wait for PHY_period/2;
		PHY_TXCLK <= '1';
		wait for PHY_period/4;
   end process;

   PHY_RXCLK_process :process
   begin
    wait for PHY_period / 4;
		PHY_RXCLK <= '0';
		wait for PHY_period/2;
		PHY_RXCLK <= '1';
		wait for PHY_period/4;
   end process;

	RX_proc: process
constant RX_DATA_LENGTH: integer :=174;
type RX_DATA_TYPE is array (0 to (RX_DATA_LENGTH - 1)) of std_logic_vector(3 downto 0);
constant RX_DATA: RX_DATA_TYPE := (X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"5",X"D",X"8",X"4",X"8",X"4",X"8",X"4",X"8",X"4",X"8",X"4",X"8",X"4",X"4",X"5",X"2",X"4",X"9",X"4",X"2",X"6",X"C",X"6",X"2",X"6",X"8",X"0",X"0",X"0",X"5",X"4",X"0",X"0",X"0",X"0",X"E",X"2",X"0",X"0",X"0",X"0",X"0",X"4",X"0",X"0",X"0",X"4",X"6",X"0",X"7",X"B",X"F",X"6",X"0",X"C",X"8",X"A",X"1",X"0",X"3",X"0",X"0",X"C",X"8",X"A",X"1",X"0",X"7",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"5",X"0",X"0",X"F",X"F",X"C",X"F",X"0",X"8",X"9",X"B",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"B",X"A",X"D",X"C",X"F",X"E",X"B",X"A",X"D",X"C",X"F",X"E",X"B",X"A",X"D",X"C",X"F",X"E",X"B",X"A",X"B",X"A",X"B",X"A",X"2",X"1",X"4",X"3",X"6",X"5",X"8",X"7",X"0",X"9",X"8",X"B",X"A",X"4",X"D",X"2",X"0",X"6");
	begin
    wait for 1000 ns;
	 PHY_RXDV <= '1';
	 for i in 0 to (RX_DATA_LENGTH - 1) loop
		PHY_RXD <= RX_DATA(i);
    wait for PHY_period;
	 end loop;
	 PHY_RXDV <= '0';
    wait;
	end process;


   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
      BTN(4) <= '1';
      wait for 100 ns;
      BTN(4) <= '0';
      wait for CLK_period*10;

      -- insert stimulus here

      wait;
   end process;

END;
