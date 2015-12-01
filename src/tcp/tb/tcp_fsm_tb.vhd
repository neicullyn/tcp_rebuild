--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   15:24:56 11/30/2015
-- Design Name:
-- Module Name:   E:/Github/tcp_rebuild/src/tcp/tb/tcp_fsm_tb.vhd
-- Project Name:  tcp_rebuild
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: tcp_fsm
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY tcp_fsm_tb IS
END tcp_fsm_tb;

ARCHITECTURE behavior OF tcp_fsm_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT tcp_fsm
    PORT(
      CLK : in std_logic;
      nRST : in std_logic;

      tcp_passive_open : in std_logic;
      tcp_active_open : in std_logic;
      tcp_active_close : in std_logic;

      tcp_state_handle : in std_logic;

      RX_SRC_IP_ADDR : in IP_ADDR_TYPE;
      RX_SRC_PORT : in std_logic_vector(15 downto 0);
      RX_ACK_NUM : in unsigned(31 downto 0);

      RX_ACK_BIT : in std_logic;
      RX_SYN_BIT : in std_logic;
      RX_FIN_BIT : in std_logic;
      RX_RST_BIT : in std_logic;

      established : out std_logic;
      action  : out CORE_ACTION;
      action_valid : out std_logic;
      TX_DST_IP_ADDR : out IP_ADDR_TYPE;
      TX_DST_PORT : out std_logic_vector(15 downto 0)
    );
    END COMPONENT;


   --Inputs
   signal CLK : std_logic := '0';
   signal nRST : std_logic := '0';
   signal tcp_passive_open : std_logic := '0';
   signal tcp_active_open : std_logic := '0';
   signal tcp_active_close : std_logic := '0';
   signal tcp_state_handle : std_logic := '0';
   signal RX_SRC_IP_ADDR : IP_ADDR_TYPE := (others => X"00");
   signal RX_SRC_PORT : std_logic_vector(15 downto 0) := (others => '0');
   signal RX_ACK_NUM : unsigned(31 downto 0) := (others => '0');
   signal RX_ACK_BIT : std_logic := '0';
   signal RX_SYN_BIT : std_logic := '0';
   signal RX_FIN_BIT : std_logic := '0';
   signal RX_RST_BIT : std_logic := '0';

 	--Outputs
   signal established : std_logic;
   signal action : CORE_ACTION;
   signal action_valid : std_logic;
   signal TX_DST_IP_ADDR : IP_ADDR_TYPE;
   signal TX_DST_PORT : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: tcp_fsm PORT MAP (
          CLK => CLK,
          nRST => nRST,
          tcp_passive_open => tcp_passive_open,
          tcp_active_open => tcp_active_open,
          tcp_active_close => tcp_active_close,
          tcp_state_handle => tcp_state_handle,
          RX_SRC_IP_ADDR => RX_SRC_IP_ADDR,
          RX_SRC_PORT => RX_SRC_PORT,
          RX_ACK_NUM => RX_ACK_NUM,
          RX_ACK_BIT => RX_ACK_BIT,
          RX_SYN_BIT => RX_SYN_BIT,
          RX_FIN_BIT => RX_FIN_BIT,
          RX_RST_BIT => RX_RST_BIT,
          established => established,
          action => action,
          action_valid => action_valid,
          TX_DST_IP_ADDR => TX_DST_IP_ADDR,
          TX_DST_PORT => TX_DST_PORT
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

      -- Test active open
      tcp_active_open <= '1';
      wait for CLK_period;
      tcp_active_open <= '0';

      assert(action = MAKE_SYN);
      assert(action_valid = '1');
      assert(TX_DST_IP_ADDR = VAIO_IP_ADDR);
      assert(TX_DST_PORT = VAIO_LISTEN_PORT);

      wait for CLK_period;
      assert(action_valid = '0');

      -- Receive SYN and ACK, but IP and Port not matched, do nothing
      RX_SRC_IP_ADDR <= (others => X"FF");
      RX_SRC_PORT <= (others => '0');

      RX_SYN_BIT <= '1';
      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_SYN_BIT <= '0';
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(action_valid = '0');
      wait for CLK_period;

      -- Receive SYN and ACK, should send ACK and go to Established
      RX_SRC_IP_ADDR <= VAIO_IP_ADDR;
      RX_SRC_PORT <= VAIO_LISTEN_PORT;

      RX_SYN_BIT <= '1';
      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_SYN_BIT <= '0';
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(established = '1');
      assert(action = MAKE_ACK);
      assert(action_valid = '1');
      wait for CLK_period;

      -- Test Simutaneous open
      -- Reset
      RX_RST_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_RST_BIT <= '0';
      tcp_state_handle <= '0';

      tcp_active_open <= '1';
      wait for CLK_period;
      tcp_active_open <= '0';

      assert(action = MAKE_SYN);
      assert(action_valid = '1');
      assert(TX_DST_IP_ADDR = VAIO_IP_ADDR);
      assert(TX_DST_PORT = VAIO_LISTEN_PORT);

      wait for CLK_period;
      assert(action_valid = '0');

      -- Receive SYN, but IP and Port not matched, do nothing
      RX_SRC_IP_ADDR <= (others => X"FF");
      RX_SRC_PORT <= (others => '0');

      RX_SYN_BIT <= '1';
      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_SYN_BIT <= '0';
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(action_valid = '0');
      wait for CLK_period;

      -- Receive SYN, should send ACK and go to SYN_RECEIVED
      RX_SRC_IP_ADDR <= VAIO_IP_ADDR;
      RX_SRC_PORT <= VAIO_LISTEN_PORT;

      RX_SYN_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_SYN_BIT <= '0';
      tcp_state_handle <= '0';

      assert(established = '0');
      assert(action = MAKE_ACK);
      assert(action_valid = '1');
      wait for CLK_period;

      -- Receive ACK, should go to established
      RX_SRC_IP_ADDR <= VAIO_IP_ADDR;
      RX_SRC_PORT <= VAIO_LISTEN_PORT;

      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(established = '1');
      assert(action_valid = '0');
      wait for CLK_period;

      -- Test passive open
      -- Reset
      RX_RST_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_RST_BIT <= '0';
      tcp_state_handle <= '0';

      tcp_passive_open <= '1';
      wait for CLK_period;
      tcp_passive_open <= '0';

      assert(action_valid = '0');
      wait for CLK_period;

      -- Receive SYN
      RX_SRC_IP_ADDR <= (others => X"77");
      RX_SRC_PORT <= (others => '1');

      RX_SYN_BIT <= '1';
      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_SYN_BIT <= '0';
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(action = MAKE_SYN_ACK);
      assert(action_valid = '1');
      wait for CLK_period;
      assert(action_valid = '0');

      -- Receive ACK, but IP and Port not matched, do nothing
      RX_SRC_IP_ADDR <= (others => X"FF");
      RX_SRC_PORT <= (others => '0');

      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(action_valid = '0');
      wait for CLK_period;

      -- Receive ACK, should go to established
      RX_SRC_IP_ADDR <= (others => X"77");
      RX_SRC_PORT <= (others => '1');

      RX_ACK_BIT <= '1';
      tcp_state_handle <= '1';
      wait for CLK_period;
      RX_ACK_BIT <= '0';
      tcp_state_handle <= '0';

      assert(established = '1');
      assert(action_valid = '0');
      wait for CLK_period;

      wait;
   end process;

END;
