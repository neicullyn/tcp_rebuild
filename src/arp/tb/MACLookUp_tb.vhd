LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.TCP_CONSTANTS.ALL;

ENTITY MACLookUp_tb IS
END MACLookUp_tb;

ARCHITECTURE behavior OF MACLookUp_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT MACLookUp
    PORT(
         nRST : IN  std_logic;
         CLK : IN  std_logic;
         CLK_1K : IN  std_logic;
         InputIP : IN  IP_ADDR_TYPE;
         Start : IN  std_logic;
         OutputValid : OUT  std_logic;
         OutputMAC : OUT  MAC_ADDR_TYPE;
         RequestIP : OUT  IP_ADDR_TYPE;
         RequestValid : OUT  std_logic;
         RequestSent : IN  std_logic;
         ResponseIP : IN  IP_ADDR_TYPE;
         ResponseMAC : IN  MAC_ADDR_TYPE;
         ResponseValid : IN  std_logic
        );
    END COMPONENT;


   --Inputs
   signal nRST : std_logic := '0';
   signal CLK : std_logic := '0';
   signal CLK_1K : std_logic := '0';
   signal InputIP : IP_ADDR_TYPE;
   signal Start : std_logic := '0';
   signal RequestSent : std_logic := '0';
   signal ResponseIP : IP_ADDR_TYPE;
   signal ResponseMAC : MAC_ADDR_TYPE;
   signal ResponseValid : std_logic := '0';

 	--Outputs
   signal OutputValid : std_logic;
   signal OutputMAC : MAC_ADDR_TYPE;
   signal RequestIP : IP_ADDR_TYPE;
   signal RequestValid : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
   constant CLK_1K_period : time := 10 ns;

   constant InterestedIP : IP_ADDR_TYPE := (X"12", X"34", X"56", X"78");
   constant OtherIP : IP_ADDR_TYPE := (X"FF", X"34", X"56", X"78");

   constant InterestedMAC : MAC_ADDR_TYPE := (X"12", X"34", X"56", X"78", X"9A", X"BC");
   constant OtherMAC : MAC_ADDR_TYPE := (X"FF", X"34", X"56", X"78", X"9A", X"BC");

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: MACLookUp PORT MAP (
          nRST => nRST,
          CLK => CLK,
          CLK_1K => CLK_1K,
          InputIP => InputIP,
          Start => Start,
          OutputValid => OutputValid,
          OutputMAC => OutputMAC,
          RequestIP => RequestIP,
          RequestValid => RequestValid,
          RequestSent => RequestSent,
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

   CLK_1K_process :process
   begin
		CLK_1K <= '0';
		wait for CLK_1K_period/2;
		CLK_1K <= '1';
		wait for CLK_1K_period/2;
   end process;


   -- Stimulus process
   stim_proc: process
   begin
      nRST <= '0';
      wait for 100 ns;

		  nRST <= '1';
      wait for CLK_period*10;

      InputIP <= InterestedIP;
      Start <= '1';
      wait for CLK_period;
		Start <= '0';

      wait;
   end process;

   response_proc: process
   begin
	 -- Timeout test
    wait until RequestValid = '1';

    RequestSent <= '1';
    wait for 2 * CLK_period;

    RequestSent <= '0';
    wait for CLK_period;
	 
	 -- Reat test
	 
	 wait until RequestValid = '1';

    RequestSent <= '1';
    wait for 2 * CLK_period;

    RequestSent <= '0';
    wait for CLK_period;

    ResponseIP <= OtherIP;
    ResponseMAC <= OtherMAC;
    ResponseValid <= '1';

	 wait for CLK_period;
	 ResponseValid <= '0';

    wait until RequestValid = '1';

    RequestSent <= '1';
    wait for 2 * CLK_period;

    RequestSent <= '0';
    wait for CLK_period;

    ResponseIP <= InterestedIP;
    ResponseMAC <= InterestedMAC;
    ResponseValid <= '1';
	 wait for CLK_period;
	 ResponseValid <= '0';
    wait;
   end process;

END;
