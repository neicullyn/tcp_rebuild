--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:01:34 05/10/2015
-- Design Name:
-- Module Name:   E:/Github/TCP_full_stack/src/tb/FIFO_tb.vhd
-- Project Name:  project_full_stack
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: FIFO
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
USE ieee.numeric_std.ALL;

ENTITY FIFO_with_flush_tb IS
END FIFO_with_flush_tb;

ARCHITECTURE behavior OF FIFO_with_flush_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT FIFO_with_flush
    PORT(
         nRST : IN  std_logic;
         CLK : IN  std_logic;
         DIN : IN  std_logic_vector(7 downto 0);
         DOUT : OUT  std_logic_vector(7 downto 0);
         PUSH : IN  std_logic;
         POP : IN  std_logic;
         EMPTY : OUT  std_logic;
         FULL : OUT  std_logic;
         FLUSH : in std_logic;
         CLEAR : in std_logic
        );
    END COMPONENT;


   --Inputs
   signal nRST : std_logic := '0';
   signal CLK : std_logic := '0';
   signal DIN : std_logic_vector(7 downto 0) := (others => '0');
   signal PUSH : std_logic := '0';
   signal POP : std_logic := '0';
   signal FLUSH : std_logic := '0';
   signal CLEAR : std_logic := '0';

 	--Outputs
   signal DOUT : std_logic_vector(7 downto 0);
   signal EMPTY : std_logic;
   signal FULL : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: FIFO_with_flush PORT MAP (
          nRST => nRST,
          CLK => CLK,
          DIN => DIN,
          DOUT => DOUT,
          PUSH => PUSH,
          POP => POP,
          EMPTY => EMPTY,
          FULL => FULL,
			    FLUSH => FLUSH,
          CLEAR => CLEAR
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
		nRST <= '0';
      wait for 100 ns;
		nRST <= '1';

    PUSH <= '1';
    FLUSH <= '0';
    DIN <= X"01";
    wait for CLK_period;

    PUSH <= '1';
    FLUSH <= '0';
    DIN <= X"02";
    wait for CLK_period;

    PUSH <= '1';
    FLUSH <= '0';
    DIN <= X"03";
    wait for CLK_period;

    PUSH <= '0';
    FLUSH <= '1';
    wait for CLK_period * 1;

    PUSH <= '0';
    FLUSH <= '0';
    wait for CLK_period * 3;

    PUSH <= '1';
    FLUSH <= '1';
    DIN <= X"01";
    wait for CLK_period;

    PUSH <= '1';
    FLUSH <= '1';
    DIN <= X"02";
    wait for CLK_period;

    PUSH <= '1';
    FLUSH <= '1';
    DIN <= X"03";
    wait for CLK_period;

    PUSH <= '1';
    FLUSH <= '0';
    DIN <= X"03";
    wait for 10 * CLK_period;

    PUSH <= '0';
    FLUSH <= '0';
    CLEAR <= '1';
    wait for CLK_period;
    CLEAR <= '0';

    wait;
   end process;

   POP <= '1' when EMPTY = '0' else '0';
END;
