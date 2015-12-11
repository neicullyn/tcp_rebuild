--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   13:05:48 06/04/2015
-- Design Name:
-- Module Name:   E:/Github/TCP_full_stack/src/tcp_trs_task_scheduler_tb.vhd
-- Project Name:  project_full_stack
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: tcp_trs_task_scheduler
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
USE ieee.numeric_std.ALL;

ENTITY tcp_trs_task_scheduler_tb IS
END tcp_trs_task_scheduler_tb;

ARCHITECTURE behavior OF tcp_trs_task_scheduler_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT tcp_trs_task_scheduler
    port(
      -- For protocol core
      core_dst_addr : in IP_ADDR_TYPE;
      core_dst_port : in std_logic_vector(15 downto 0);
      core_ack_num : in std_logic_vector(31 downto 0);
      core_ack : in std_logic;
      core_rst : in std_logic;
      core_syn : in std_logic;
      core_fin : in std_logic;

      -- Push the core packet info into the scheduler
      -- Note that core_push has higher priority than app_push
      core_push : in std_logic;
      core_pushing : out std_logic;

      -- Packet generate by the protocol doesn't have payload
      -- en_data : in std_logic;
      -- data_addr : in std_logic_vector(22 downto 0);
      -- data_len : in std_logic_vector(10 downto 0);

      -- For upper layer (application)
      app_dst_addr : in IP_ADDR_TYPE;
      app_dst_port : in std_logic_vector(15 downto 0);
      app_ack_num : in std_logic_vector(31 downto 0);

      -- Application layer doesn't set flags (for our simplified implementation)
      -- ack : in std_logic;
      -- rst : in std_logic;
      -- syn : in std_logic;
      -- fin : in std_logic;

      app_en_data : in std_logic;
      app_data_addr : in std_logic_vector(22 downto 0);
      app_data_len : in std_logic_vector(10 downto 0);

      -- Push the app packet info into the scheduler
      app_push : in std_logic;
      app_pushing : out std_logic;

      -- Output
      dst_addr : out IP_ADDR_TYPE;
      dst_port : out std_logic_vector(15 downto 0);
      ack_num : out std_logic_vector(31 downto 0);

      ack_bit : out std_logic;
      rst_bit : out std_logic;
      syn_bit : out std_logic;
      fin_bit : out std_logic;

      en_data : out std_logic;
      data_addr : out std_logic_vector(22 downto 0);
      data_len : out std_logic_vector(10 downto 0);

      -- Control signals for output
      valid : out std_logic;
      update : in std_logic; -- indicates that the output has been used
                             -- and needs updating
      empty : out std_logic; -- indicates the queue is empty

      -- Asynchronous reset and CLK
      nRST : in std_logic;
      CLK : in std_logic
    );
    END COMPONENT;


   --Inputs
   signal core_dst_addr : IP_ADDR_TYPE := (others => X"00");
   signal core_dst_port : std_logic_vector(15 downto 0) := (others => '0');
   signal core_ack_num : std_logic_vector(31 downto 0) := (others => '0');
   signal core_ack : std_logic := '0';
   signal core_rst : std_logic := '0';
   signal core_syn : std_logic := '0';
   signal core_fin : std_logic := '0';
   signal core_push : std_logic := '0';
   signal app_dst_addr : IP_ADDR_TYPE := (others => X"00");
   signal app_dst_port : std_logic_vector(15 downto 0) := (others => '0');
   signal app_ack_num : std_logic_vector(31 downto 0) := (others => '0');
   signal app_en_data : std_logic := '0';
   signal app_data_addr : std_logic_vector(22 downto 0) := (others => '0');
   signal app_data_len : std_logic_vector(10 downto 0) := (others => '0');
   signal app_push : std_logic := '0';
   signal update : std_logic := '0';
   signal nRST : std_logic := '0';
   signal CLK : std_logic := '0';

 	--Outputs
	signal core_pushing : std_logic;
	signal app_pushing : std_logic;
   signal dst_addr : IP_ADDR_TYPE;
   signal dst_port : std_logic_vector(15 downto 0);
   signal ack_num : std_logic_vector(31 downto 0);

   signal en_data : std_logic;
   signal data_addr : std_logic_vector(22 downto 0);
   signal data_len : std_logic_vector(10 downto 0);
   signal valid : std_logic;
   signal empty : std_logic;

   signal ack_bit : std_logic;
   signal rst_bit : std_logic;
   signal syn_bit : std_logic;
   signal fin_bit : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: tcp_trs_task_scheduler PORT MAP (
          core_dst_addr => core_dst_addr,
          core_dst_port => core_dst_port,
          core_ack_num => core_ack_num,
          core_ack => core_ack,
          core_rst => core_rst,
          core_syn => core_syn,
          core_fin => core_fin,
          core_push => core_push,
		      core_pushing => core_pushing,
          app_dst_addr => app_dst_addr,
          app_dst_port => app_dst_port,
          app_ack_num => app_ack_num,
          app_en_data => app_en_data,
          app_data_addr => app_data_addr,
          app_data_len => app_data_len,
          app_push => app_push,
		      app_pushing => app_pushing,
          dst_addr => dst_addr,
          dst_port => dst_port,
          ack_num => ack_num,
          ack_bit => ack_bit,
          rst_bit => rst_bit,
          syn_bit => syn_bit,
          fin_bit => fin_bit,
          en_data => en_data,
          data_addr => data_addr,
          data_len => data_len,
          valid => valid,
          update => update,
          empty => empty,
          nRST => nRST,
          CLK => CLK
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
   stim_proc1: process
   begin
      -- hold reset state for 100 ns.
		nRST <= '0';
      wait for 100 ns;
		nRST <= '1';

      wait for CLK_period*10;

      core_dst_addr <= (x"ff", x"00", x"ff", x"00");
      core_dst_port <= x"1234";
      core_ack_num <= x"00000001";
      core_ack <= '1';
      core_rst <= '0';
      core_syn <= '1';
      core_fin <= '0';

      core_push <= '1';

		wait until core_pushing = '1';

      core_push <= '0';

      wait;
   end process;

   stim_proc2: process
   begin
      -- hold reset state for 100 ns.
      wait for 100 ns;

      wait for CLK_period*10;

      app_dst_addr <= (x"23", x"45", x"12", x"34");
      app_dst_port <= x"4321";
      app_ack_num  <= x"00001000";
      app_en_data <= '1';
      app_data_addr <= (others => '0');
      app_data_addr(7 downto 0) <= x"FF";
      app_data_len <= std_logic_vector(to_unsigned(7, app_data_len'length));

      app_push <= '1';

		wait until app_pushing = '1';

		app_push <= '0';

		wait until app_pushing = '0';

		app_dst_addr <= (x"21", x"21", x"12", x"12");
      app_dst_port <= x"1111";
      app_ack_num  <= x"00001000";
      app_en_data <= '1';
      app_data_addr <= (others => '0');
      app_data_addr(7 downto 0) <= x"11";
      app_data_len <= std_logic_vector(to_unsigned(11, app_data_len'length));

      app_push <= '1';

		wait until app_pushing = '1';

		app_push <= '0';

      wait;
   end process;

	read_proc: process
	begin
	   wait for 100 ns;

      wait for CLK_period*10;

		wait until empty = '0';
		update <= '1';
		wait for 3 * CLK_period;
		update <= '0';

		wait until valid = '1' and empty = '0';
		update <= '1';
		wait for 3 * CLK_period;
		update <= '0';

		wait until valid = '1' and empty = '0';
		update <= '1';
		wait for 3 * CLK_period;
		update <= '0';
	end process;

END;
