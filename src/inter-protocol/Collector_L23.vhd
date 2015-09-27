library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.TCP_CONSTANTS.all;

entity Collector_L23 is
  Port (
    CLK : in  STD_LOGIC;
    nRST : in  STD_LOGIC;

    TXDU : out  STD_LOGIC_VECTOR (7 downto 0);
    TXEN : out  STD_LOGIC;
    DST_MAC_ADDR: out MAC_ADDR_TYPE;
    RdU : in STD_LOGIC;
    TX_PROTOCOL : out L3_PROTOCOL;

    TXDC_ARP : in  STD_LOGIC_VECTOR (7 downto 0);
    TXDV_ARP : in  STD_LOGIC;
    DST_MAC_ADDR_ARP : in MAC_ADDR_TYPE;
    RdC_ARP : out  STD_LOGIC;

    TXDC_IP : in  STD_LOGIC_VECTOR (7 downto 0);
    TXDV_IP : in  STD_LOGIC;
    DST_MAC_ADDR_IP : in MAC_ADDR_TYPE;
    RdC_IP : out  STD_LOGIC
  );
end Collector_L23;

architecture Behavioral of Collector_L23 is
  type states is (Idle, Busy);
  signal state: states;
  signal TX_PROTOCOL_dummy : L3_PROTOCOL;
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
            if (TXDV_ARP = '1') then
              TX_PROTOCOL_dummy <= ARP;
              state <= Busy;
            elsif (TXDV_IP = '1') then
              TX_PROTOCOL_dummy <= IP;
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

  Data_proc: process (state, TX_PROTOCOL_dummy, TXDC_ARP, TXDV_ARP, DST_MAC_ADDR_ARP, TXDC_IP, TXDV_IP, DST_MAC_ADDR_IP)
  begin
    case TX_PROTOCOL_dummy is
      when ARP =>
        TXDU <= TXDC_ARP;
        DST_MAC_ADDR <= DST_MAC_ADDR_ARP;
        if (state = Busy) then
          TXEN_dummy <= TXDV_ARP;
        else
          TXEN_dummy <= '0';
        end if;
      when IP =>
        TXDU <= TXDC_IP;
        DST_MAC_ADDR <= DST_MAC_ADDR_IP;
        if (state = Busy) then
          TXEN_dummy <= TXDV_IP;
        else
          TXEN_dummy <= '0';
        end if;
    end case;
  end process;

  RdU_proc: process (state, TX_PROTOCOL_dummy, RdU)
  begin
    RdC_ARP <= '0';
    RdC_IP <= '0';
    case TX_PROTOCOL_dummy is
      when ARP =>
        RdC_ARP <= RdU;
      when IP =>
        RdC_IP <= RdU;
    end case;
  end process;
end Behavioral;
