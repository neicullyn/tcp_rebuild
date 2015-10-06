library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity MACLookUp is
  port (
    nRST : in std_logic;
    CLK : in std_logic;
    CLK_1K : in std_logic;

    InputIP : in IP_ADDR_TYPE;
    Start : in std_logic;
    OutputMAC : out MAC_ADDR_TYPE;
    OutputValid : out std_logic;

    RequestIP : out IP_ADDR_TYPE;
    RequestValid : out std_logic;
    RequestSent : in std_logic;

    ResponseIP : in IP_ADDR_TYPE;
    ResponseMAC : in MAC_ADDR_TYPE;
    ResponseValid : in std_logic
  );
end MACLookUp;

architecture Behavioral of MACLookUp is
  constant SIZE: integer := 4;

  signal LookUpIndex : integer range 0 to (SIZE - 1);
  signal StoreIndex : integer range 0 to (SIZE - 1);

  type IP_LIST_TYPE is array (0 to (SIZE - 1)) of IP_ADDR_TYPE;
  signal IP_LIST: IP_LIST_TYPE;

  type MAC_LIST_TYPE is array (0 to (SIZE - 1)) of MAC_ADDR_TYPE;
  signal MAC_LIST: MAC_LIST_TYPE;

  type STATE_TYPE is (Idle, LookUp, Request, WaitForResponse, Done);
  signal State : STATE_TYPE;

  signal InputIP_buf : IP_ADDR_TYPE;

  signal StoreIndex_next : integer range 0 to (SIZE - 1);

  signal LookUpIndex_next : integer range 0 to (SIZE - 1);
  signal LookUPIndex_end : integer range 0 to (SIZE - 1);

  signal TimeOutCounter : integer range 0 to 1000;
  signal TimeOut : std_logic;
begin
  StoreIndex_next <= (StoreIndex + 1) mod SIZE;
  LookUpIndex_next <= (LookUpIndex + 1) mod SIZE;

  Table_proc: process (nRST, CLK)
  begin
    if (nRST = '0') then
      for i in 0 to (SIZE - 1) loop
        IP_LIST(i) <= (X"00", X"00", X"00", X"00");
        MAC_LIST(i) <= (X"00", X"00", X"00", X"00", X"00", X"00");
      end loop;
      StoreIndex <= 0;
    elsif (rising_edge(CLK)) then
      if (ResponseValid = '1') then
        IP_LIST(StoreIndex) <= ResponseIP;
        MAC_LIST(StoreIndex) <= ResponseMAC;
        StoreIndex <= StoreIndex_next;
      end if;
    end if;
  end process;

  TimeOut_proc: process (CLK)
  begin
    if (State /= WaitForResponse) then
      TimeOutCounter <= 0;
    elsif (rising_edge (CLK)) then
      if (TimeOut = '0') then
        TimeOutCounter <= TimeOutCounter + 1;
      end if;
    end if;
  end process;
  TimeOut <= '1' when TimeOutCounter = 999 else '0';

  LookUp_proc: process (nRST, CLK)
  begin
    if (nRST = '0') then
      State <= Idle;
    elsif (rising_edge(CLK)) then
      case State is
        when Idle =>
          if (Start = '1') then
            LookUpIndex <= StoreIndex_next;
            LookUPIndex_end <= StoreIndex;
            InputIP_buf <= InputIP;
            State <= LookUp;
          end if;

        when LookUp =>
          if (IP_LIST(LookUpIndex) = InputIP_buf) then
            State <= Done;
          elsif (LookUpIndex = LookUPIndex_end) then
            -- Can't find the IP in the table
            State <= Request;
          else
            LookUpIndex <= LookUpIndex_next;
          end if;

        when Request =>
          if (RequestSent = '1') then
            State <= WaitForResponse;
          end if;

        when WaitForResponse =>
          if (ResponseValid = '1') then
            LookUpIndex <= StoreIndex_next;
            LookUPIndex_end <= StoreIndex;
            State <= LookUp;
          elsif (TimeOut = '1') then
            State <= Request;
          end if;

        when Done =>
          State <= Idle;
      end case;
    end if;
  end process;
  RequestIP <= InputIP_buf;
  RequestValid <= '1' when State = Request else '0';

  OutputValid <= '1' when State = Done else '0';

  OutputMAC <= MAC_LIST(LookUpIndex);
end Behavioral;