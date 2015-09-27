library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.TCP_CONSTANTS.all;

entity Dispatcher_L23 is
  Port (
    CLK : in  STD_LOGIC;
    nRST : in  STD_LOGIC;

    RXDU : in  STD_LOGIC_VECTOR (7 downto 0);
    WrU : in  STD_LOGIC;
    RXER : in STD_LOGIC;
    RXEOP : in STD_LOGIC;
    RX_PROTOCOL : in L3_PROTOCOL;

    RXDC_ARP : out  STD_LOGIC_VECTOR (7 downto 0);
    WrC_ARP : out  STD_LOGIC;
    RXER_ARP : out STD_LOGIC;
    RXEOP_ARP : out STD_LOGIC;

    RXDC_IP : out  STD_LOGIC_VECTOR (7 downto 0);
    WrC_IP : out  STD_LOGIC;
    RXER_IP : out STD_LOGIC;
    RXEOP_IP : out STD_LOGIC
  );
end Dispatcher_L23;

architecture Behavioral of Dispatcher_L23 is
begin
  RXDC_ARP <= RXDU;
  RXDC_IP <= RXDU;
  control_proc: process (RX_PROTOCOL, WrU, RXER, RXEOP)
  begin
    WrC_ARP <= '0';
    RXER_ARP <= '0';
    RXEOP_ARP <= '0';
    WrC_IP <= '0';
    RXER_IP <= '0';
    RXEOP_IP <= '0';

    case RX_PROTOCOL is
      when ARP =>
        WrC_ARP <= WrU;
        RXER_ARP <= RXER;
        RXEOP_ARP <= RXEOP;
      when IP =>
        WrC_IP <= WrU;
        RXER_IP <= RXER;
        RXEOP_IP <= RXEOP;
    end case;
  end process;
end Behavioral;
