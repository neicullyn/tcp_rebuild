library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity ARP is
  Port (
    CLK : in  STD_LOGIC;  -- global clock
    nRST: in  STD_LOGIC;  -- global reset, active low

    TXEN: out STD_LOGIC; -- transmission data ready for underlying layer (MAC)
    TXDU: out  STD_LOGIC_VECTOR (7 downto 0); -- transmission data bus to underlying layer
    TXIDLE: out STD_LOGIC;

    RXDU: in  STD_LOGIC_VECTOR (7 downto 0); -- receive data bus from the underlying layer
    RXER: in STD_LOGIC; -- Receive data error
    RXEOP: in STD_LOGIC; -- End of a packet

    RdU: in STD_LOGIC; -- Read pulse from MAC
    WrU: in STD_LOGIC; -- Write pulse from MAC

    DST_MAC_ADDR :  out MAC_ADDR_TYPE;
    RequestIP: in IP_ADDR_TYPE;
    RequestValid: in STD_LOGIC;

    ResponseIP: out IP_ADDR_TYPE;
    ResponseMAC: out MAC_ADDR_TYPE;
    ResponseValid: out STD_LOGIC
  );
end ARP;

architecture Behavioral of ARP is
  -- ARP states and counters
  type TX_states is (Idle, Request);
  type RX_states is (Header, SHA, SPA, THA, TPA, WaitForEOP, EOP, ERR);

  signal TX_state: TX_states;
  signal RX_state: RX_states;
  signal TX_counter: integer range 0 to 31;
  signal RX_counter: integer range 0 to 31;

  -- TX and RX registers
  signal TX_register: STD_LOGIC_VECTOR(7 downto 0);
  signal RX_register: STD_LOGIC_VECTOR(7 downto 0);

  -- Header data
  type DATA_ARRAY is array (0 to 27) of STD_LOGIC_VECTOR(7 downto 0);
  signal request_data : DATA_ARRAY;

  type HEADER_ARRAY is array (0 to 7) of STD_LOGIC_VECTOR(7 downto 0);
  signal response_header : HEADER_ARRAY;

  signal RequestIP_buf: IP_ADDR_TYPE;
  signal ResponseIP_dummy: IP_ADDR_TYPE;
  signal ResponseMAC_dummy: MAC_ADDR_TYPE;

  signal RX_ARP_ERR: STD_LOGIC;

begin
  DST_MAC_ADDR <= (X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");

  -- Header
  -- 0x0001: Hardware Type: Ethernet
  -- 0x0800: Protocol Type: IPv4
  -- 0x06: Hardare Address Length, 0x04: Protocol Address Length
  -- 0x0001: Operation: Request | 0x0002 Operation: Response
  request_data(0 to 7) <= (X"00", X"01", X"08", X"00", X"06", X"04", X"00", X"01");
  request_data(8 to 13) <= (MAC_ADDR(0), MAC_ADDR(1), MAC_ADDR(2), MAC_ADDR(3), MAC_ADDR(4), MAC_ADDR(5));
  request_data(14 to 17) <= (IP_ADDR(0), IP_ADDR(1), IP_ADDR(2), IP_ADDR(3));
  request_data(18 to 23) <= (X"00", X"00", X"00", X"00", X"00", X"00");
  request_data(24 to 27) <= (RequestIP_buf(0), RequestIP_buf(1), RequestIP_buf(2), RequestIP_buf(3));

  response_header(0 to 7) <= (X"00", X"01", X"08", X"00", X"06", X"04", X"00", X"02");

  TX_SM: process (nRST, CLK)
  begin
    if (nRST = '0') then
      TX_state <= Idle;
      TX_counter <= 0;
    elsif (rising_edge(CLK)) then
      case TX_state is
        when Idle =>
          if (RequestValid = '1') then
            RequestIP_buf <= RequestIP;
            TX_state <= Request;
            TX_counter <= 0;
          end if;

        when Request =>
          if (RdU = '1') then
            if (TX_counter = 27) then
              TX_state <= Idle;
              TX_counter <= 0;
            else
              TX_counter <= TX_counter + 1;
            end if;
          end if;
      end case;
    end if;
  end process;

  TXEN <= '1' when TX_state = Request else '0';
  TXIDLE <= '0' when TX_state = Request else '1';

  TX_DATA: process (TX_state, TX_counter)
  begin
    case TX_state is
      when Idle =>
        TXDU <= X"00";
      when Request =>
        TXDU <= request_data(TX_counter);
    end case;
  end process;

  RX_SM: process (nRST, CLK)
  begin
    if (nRST = '0') then
      RX_state <= Header;
      RX_counter <= 0;
    elsif (rising_edge(CLK)) then
      if (RXER = '1' and RXEOP = '1') then
        RX_state <= ERR;
      else
        case RX_state is
          when Header =>
            if (WrU = '1') then
              if (RX_counter = 7) then
                RX_state <= SHA;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when SHA =>
            if (WrU = '1') then
              if (RX_counter = 5) then
                RX_state <= SPA;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when SPA =>
            if (WrU = '1') then
              if (RX_counter = 3) then
                RX_state <= THA;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when THA =>
            if (WrU = '1') then
              if (RX_counter = 5) then
                RX_state <= TPA;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when TPA =>
            if (WrU = '1') then
              if (RX_counter = 3) then
                RX_state <= WaitForEOP;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when WaitForEOP =>
            if (RXEOP = '1') then
              RX_state <= EOP;
              RX_counter <= 0;
            end if;

          when EOP =>
            RX_state <= Header;
            RX_counter <= 0;

          when ERR =>
            RX_state <= Header;
            RX_counter <= 0;
        end case;
      end if;
    end if;
  end process;

  ResponseMAC <= ResponseMAC_dummy;
  ResponseIP <= ResponseIP_dummy;
  RX_DATA: process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (RX_state = THA and WrU = '1') then
        for i in 0 to 4 loop
          ResponseMAC_dummy(i) <= ResponseMAC_dummy(i + 1);
        end loop;
        ResponseMAC_dummy(5) <= RXDU;
      end if;

      if (RX_state = TPA and WrU = '1') then
        for i in 0 to 2 loop
          ResponseIP_dummy(i) <= ResponseIP_dummy(i + 1);
        end loop;
        ResponseIP_dummy(3) <= RXDU;
      end if;
    end if;
  end process;

  RX_ERR: process (CLK)
  begin
    if (RX_state = Header) then
      if (WrU = '1') then
        if (RX_counter = 0) then
          if (RXDU = response_header(0)) then
            RX_ARP_ERR <= '0';
          else
            RX_ARP_ERR <= '1';
          end if;
        else
          if (RXDU /= response_header(RX_counter)) then
            RX_ARP_ERR <= '1';
          end if;
        end if;
      end if;
    end if;

    if (RX_state = WaitForEOP and RXEOP = '1') then
      if (RXER = '1') then
        RX_ARP_ERR <= '1';
      end if;
    end if;
  end process;

  RX_output: process (RX_state, RX_ARP_ERR)
  begin
    if (RX_ARP_ERR = '0' and RX_state = EOP) then
      ResponseValid <= '1';
    else
      ResponseValid <= '0';
    end if;
  end process;

end Behavioral;
