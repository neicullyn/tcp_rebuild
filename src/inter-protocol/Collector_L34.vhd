library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.TCP_CONSTANTS.all;

entity Collector_L34 is
  Port (
    CLK : in  STD_LOGIC;
    nRST : in  STD_LOGIC;

    TXDU : out  STD_LOGIC_VECTOR (7 downto 0);
    TXEN : out  STD_LOGIC;
    DST_IP_ADDR: out IP_ADDR_TYPE;
    RdU : in STD_LOGIC;
    TX_PROTOCOL : out L4_PROTOCOL;
    TX_DataLength: out STD_LOGIC_VECTOR(15 downto 0);

    TXDC_TCP : in  STD_LOGIC_VECTOR (7 downto 0);
    TXDV_TCP : in  STD_LOGIC;
    DST_IP_ADDR_TCP : in IP_ADDR_TYPE;
    RdC_TCP : out  STD_LOGIC;
    TX_DataLength_TCP: in STD_LOGIC_VECTOR(15 downto 0);

    TXDC_UDP : in  STD_LOGIC_VECTOR (7 downto 0);
    TXDV_UDP : in  STD_LOGIC;
    DST_IP_ADDR_UDP : in IP_ADDR_TYPE;
    RdC_UDP : out  STD_LOGIC;
    TX_DataLength_UDP : in STD_LOGIC_VECTOR(15 downto 0)
  );
end Collector_L34;

architecture Behavioral of Collector_L34 is
  type states is (Idle, Busy);
  signal state: states;
  signal TX_PROTOCOL_dummy : L4_PROTOCOL;
  signal TXEN_dummy : STD_LOGIC;
begin
  TX_PROTOCOL <= TX_PROTOCOL_dummy;
  TXEN <= TXEN_dummy;

  SM: process (CLK, nRST, RdU)
  begin
    if (nRST = '0') then
      state <= Idle;
    else
      if (rising_edge(CLK)) then
        case state is
          when Idle =>
            if (TXDV_TCP = '1') then
              TX_PROTOCOL_dummy <= TCP;
              TX_DataLength <= TX_DataLength_TCP;
              state <= Busy;
            elsif (TXDV_UDP = '1') then
              TX_PROTOCOL_dummy <= UDP;
              TX_DataLength <= TX_DataLength_UDP;
              state <= Busy;
            end if;

          when Busy =>
            if (TXEN_dummy = '0') then
              state <= Idle;
            end if;
        end case;
      end if;
    end if;
  end process;

  Data_proc: process (state, TX_PROTOCOL_dummy, TXDC_TCP, TXDV_TCP, DST_IP_ADDR_TCP, TXDC_UDP, TXDV_UDP, DST_IP_ADDR_UDP)
  begin
    case TX_PROTOCOL_dummy is
      when TCP =>
        TXDU <= TXDC_TCP;
        DST_IP_ADDR <= DST_IP_ADDR_TCP;
        if (state = Busy) then
          TXEN_dummy <= TXDV_TCP;
        else
          TXEN_dummy <= '0';
        end if;
      when UDP =>
        TXDU <= TXDC_UDP;
        DST_IP_ADDR <= DST_IP_ADDR_UDP;
        if (state = Busy) then
          TXEN_dummy <= TXDV_UDP;
        else
          TXEN_dummy <= '0';
        end if;
      when others =>
      	TXDU <= X"00";
      	DST_IP_ADDR <= IP_ADDR;
      	TXEN_dummy <= '0';
    end case;
  end process;

  RdU_proc: process (state, TX_PROTOCOL_dummy, RdU)
  begin
    RdC_TCP <= '0';
    RdC_UDP <= '0';
    case TX_PROTOCOL_dummy is
      when TCP =>
        RdC_TCP <= RdU;
      when UDP =>
        RdC_UDP <= RdU;
		when others =>
    end case;
  end process;
end Behavioral;
