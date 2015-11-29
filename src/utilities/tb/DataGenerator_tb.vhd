--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:28:41 11/28/2015
-- Design Name:   
-- Module Name:   E:/Github/tcp_rebuild/src/utilities/tb/DataGenerator_tb.vhd
-- Project Name:  tcp_rebuild
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: DataGenerator
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
 
ENTITY DataGenerator_tb IS
END DataGenerator_tb;
 
ARCHITECTURE behavior OF DataGenerator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT DataGenerator
    PORT(
         CLK : IN  std_logic;
         nRST : IN  std_logic;
         data_addr : IN  std_logic_vector(22 downto 0);
         data_len : IN  std_logic_vector(11 downto 0);
         prepare_data : IN  std_logic;
         data_checksum : OUT  std_logic_vector(15 downto 0);
         data_ready : OUT  std_logic;
         data_valid : OUT  std_logic;
         rd : IN  std_logic;
         rewind : IN  std_logic;
         data_over : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal nRST : std_logic := '0';
   signal data_addr : std_logic_vector(22 downto 0) := (others => '0');
   signal data_len : std_logic_vector(11 downto 0) := (others => '0');
   signal prepare_data : std_logic := '0';
   signal rd : std_logic := '0';
   signal rewind : std_logic := '0';

 	--Outputs
   signal data_checksum : std_logic_vector(15 downto 0);
   signal data_ready : std_logic;
   signal data_valid : std_logic;
   signal data_over : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: DataGenerator PORT MAP (
          CLK => CLK,
          nRST => nRST,
          data_addr => data_addr,
          data_len => data_len,
          prepare_data => prepare_data,
          data_checksum => data_checksum,
          data_ready => data_ready,
          data_valid => data_valid,
          rd => rd,
          rewind => rewind,
          data_over => data_over
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
		
      wait for CLK_period*10;

		data_addr <= "0000000" & X"FF" & X"F0";
		data_len <= std_logic_vector(to_unsigned(9, data_len'length));
		prepare_data <= '1';
		
		wait for CLK_period;
		prepare_data <= '0';
		
		wait until data_ready = '1';
		
		rd <= '1';
		wait until data_over = '1';
		
		rd <= '0';		
      wait for CLK_period;
		
		wait;
   end process;
END;
