library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.TCP_CONSTANTS.all;

entity Dispatcher_L34 is
  Port (
    CLK : in  STD_LOGIC;
    nRST : in  STD_LOGIC;

    RXDU : in  STD_LOGIC_VECTOR (7 downto 0);
    WrU : in  STD_LOGIC;
    RXER : in STD_LOGIC;
    RXEOP : in STD_LOGIC;
    RX_PROTOCOL : in L4_PROTOCOL;
    RX_SRC_IP_ADDR : in IP_ADDR_TYPE;

    RXDC_TCP : out  STD_LOGIC_VECTOR (7 downto 0);
    WrC_TCP : out  STD_LOGIC;
    RXER_TCP : out STD_LOGIC;
    RXEOP_TCP : out STD_LOGIC;
    RX_SRC_IP_ADDR_TCP : out IP_ADDR_TYPE;

    RXDC_UDP : out  STD_LOGIC_VECTOR (7 downto 0);
    WrC_UDP : out  STD_LOGIC;
    RXER_UDP : out STD_LOGIC;
    RXEOP_UDP : out STD_LOGIC;
    RX_SRC_IP_ADDR_UDP : out IP_ADDR_TYPE
  );
end Dispatcher_L34;

architecture Behavioral of Dispatcher_L34 is
begin
  RXDC_TCP <= RXDU;
  RXDC_UDP <= RXDU;
  RX_SRC_IP_ADDR_TCP <= RX_SRC_IP_ADDR;
  RX_SRC_IP_ADDR_UDP <= RX_SRC_IP_ADDR;

  control_proc: process (RX_PROTOCOL, WrU, RXER, RXEOP)
  begin
    WrC_TCP <= '0';
    RXER_TCP <= '0';
    RXEOP_TCP <= '0';
    WrC_UDP <= '0';
    RXER_UDP <= '0';
    RXEOP_UDP <= '0';

    case RX_PROTOCOL is
      when TCP =>
        WrC_TCP <= WrU;
        RXER_TCP <= RXER;
        RXEOP_TCP <= RXEOP;
      when UDP =>
        WrC_UDP <= WrU;
        RXER_UDP <= RXER;
        RXEOP_UDP <= RXEOP;
      when others =>
    end case;
  end process;
end Behavioral;
