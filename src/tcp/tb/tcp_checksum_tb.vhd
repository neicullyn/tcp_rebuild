--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:07:56 11/06/2015
-- Design Name:   
-- Module Name:   E:/Github/tcp_rebuild/src/tcp/tb/tcp_checksum_tb.vhd
-- Project Name:  tcp_rebuild
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tcp_checksum_calc
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
 
ENTITY tcp_checksum_tb IS
END tcp_checksum_tb;
 
ARCHITECTURE behavior OF tcp_checksum_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT tcp_checksum_calc
    PORT(
         feed : IN  std_logic_vector(15 downto 0);
         calc : IN  std_logic;
         reset : IN  std_logic;
         CLK : IN  std_logic;
         valid : OUT  std_logic;
         checksum : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal feed : std_logic_vector(15 downto 0) := (others => '0');
   signal calc : std_logic := '0';
   signal reset : std_logic := '0';
   signal CLK : std_logic := '0';

 	--Outputs
   signal valid : std_logic;
   signal checksum : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: tcp_checksum_calc PORT MAP (
          feed => feed,
          calc => calc,
          reset => reset,
          CLK => CLK,
          valid => valid,
          checksum => checksum
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
		constant RX_DATA_LENGTH: integer :=32;
		type RX_DATA_TYPE is array (0 to (RX_DATA_LENGTH - 1)) of std_logic_vector(7 downto 0);
		constant RX_DATA: RX_DATA_TYPE := (X"0a",X"02",X"0b",X"c7",X"ad",X"c2",X"ca",X"bc",X"00",X"06",X"00",X"15",X"d4",X"2e",X"14",X"6c",X"d6",X"9c",X"79",X"b9",X"79",X"50",X"62",X"13",X"50",X"10",X"01",X"00",X"00",X"00",X"00",X"00");
		-- Checksum should be 0c37
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		reset <= '1';
      wait for CLK_period*10;
		reset <= '0';
		
		for i in 0 to RX_DATA_LENGTH / 2 - 1 loop
			feed <= RX_DATA(2 * i) & RX_DATA(2 * i + 1);
			calc <= '1';
			wait for CLK_period;
		end loop;
		calc <= '0';

      wait;
   end process;

END;
