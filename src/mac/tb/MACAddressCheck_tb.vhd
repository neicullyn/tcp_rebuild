--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   16:29:22 09/23/2015
-- Design Name:
-- Module Name:   E:/Github/tcp_rebuild/src/mac/tb/MACAddressCheck_tb.vhd
-- Project Name:  tcp_rebuild
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: MACAddressCheck
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

ENTITY MACAddressCheck_tb IS
END MACAddressCheck_tb;

ARCHITECTURE behavior OF MACAddressCheck_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT MACAddressCheck
    PORT(
         CLK : IN  std_logic;
         EN : IN std_logic;
         DIN : IN  std_logic_vector(7 downto 0);
         AddrValid : OUT  std_logic
        );
    END COMPONENT;


   --Inputs
   signal CLK : std_logic := '0';
   signal EN : std_logic := '0';
   signal DIN : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal AddrValid : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: MACAddressCheck PORT MAP (
          CLK => CLK,
          EN => EN,
          DIN => DIN,
          AddrValid => AddrValid
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
      EN <= '0';

      wait for CLK_period*10;

      EN <= '1';
      for i in 0 to 5 loop
        DIN <= MAC_ADDR(i);
        wait for CLK_period;
      end loop;

      EN <= '0';
      wait for CLK_period;

      assert(AddrValid = '1');

      EN <= '1';
      for i in 0 to 5 loop
        DIN <= X"FF";
        wait for CLK_period;
      end loop;

      EN <= '0';
      wait for CLK_period;

      assert(AddrValid = '1');

     EN <= '1';
      for i in 0 to 5 loop
        DIN <= not MAC_ADDR(i);
        wait for CLK_period;
      end loop;

      EN <= '0';
      wait for CLK_period;

      assert(AddrValid = '0');

      wait;
   end process;

END;
