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
    RequestSent: out STD_LOGIC;

    ResponseIP: out IP_ADDR_TYPE;
    ResponseMAC: out MAC_ADDR_TYPE;
    ResponseValid: out STD_LOGIC
  );
end ARP;

architecture Behavioral of ARP is
  -- ARP states and counters
  type TX_states is (Idle, Busy);
  type RX_states is (Header, OP, SHA, SPA, THA, TPA, WaitForEOP, EOP, ERR);

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
  signal response_data : DATA_ARRAY;

  signal RequestIP_buf: IP_ADDR_TYPE;

  signal SHA_buf: MAC_ADDR_TYPE;
  signal SPA_buf: IP_ADDR_TYPE;
  signal THA_buf: MAC_ADDR_TYPE;
  signal TPA_buf: IP_ADDR_TYPE;

  signal TX_IS_RESPONSE: STD_LOGIC;

  signal RX_ARP_ERR: STD_LOGIC;

  signal RX_NEED_RESPONSE_SET: STD_LOGIC;
  signal RX_NEED_RESPONSE: STD_LOGIC;
  signal RX_OP0_dummy: STD_LOGIC_VECTOR(7 downto 0);
  signal RX_OP1_dummy: STD_LOGIC_VECTOR(7 downto 0);
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

  response_data(0 to 7) <= (X"00", X"01", X"08", X"00", X"06", X"04", X"00", X"02");
  response_data(8 to 13) <= (MAC_ADDR(0), MAC_ADDR(1), MAC_ADDR(2), MAC_ADDR(3), MAC_ADDR(4), MAC_ADDR(5));
  response_data(14 to 17) <= (IP_ADDR(0), IP_ADDR(1), IP_ADDR(2), IP_ADDR(3));
  response_data(18 to 23) <= (MAC_ADDR(0), MAC_ADDR(1), MAC_ADDR(2), MAC_ADDR(3), MAC_ADDR(4), MAC_ADDR(5));
  response_data(24 to 27) <= (IP_ADDR(0), IP_ADDR(1), IP_ADDR(2), IP_ADDR(3));

  TX_SM: process (nRST, CLK)
  begin
    if (nRST = '0') then
      TX_state <= Idle;
      TX_counter <= 0;
      RequestSent <= '0';
      RX_NEED_RESPONSE <= '0';
    elsif (rising_edge(CLK)) then
      if (RX_NEED_RESPONSE_SET = '1') then
        RX_NEED_RESPONSE <= '1';
      end if;
      case TX_state is
        when Idle =>
          if (RX_NEED_RESPONSE = '1') then
            TX_state <= Busy;
            TX_IS_RESPONSE <= '1';
            RX_NEED_RESPONSE <= '0';
          elsif (RequestValid = '1') then
            RequestIP_buf <= RequestIP;
            RequestSent <= '1';
            TX_state <= Busy;
            TX_IS_RESPONSE <= '0';
            TX_counter <= 0;
          end if;

        when Busy =>
          RequestSent <= '0';
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

  TXEN <= '1' when TX_state = Busy else '0';
  TXIDLE <= '1' when (TX_state = Idle and RX_NEED_RESPONSE = '0') else '1';

  TX_DATA: process (TX_state, TX_counter, TX_IS_RESPONSE, request_data, response_data)
  begin
    case TX_state is
      when Idle =>
        TXDU <= X"00";
      when Busy =>
        if (TX_IS_RESPONSE = '0') then
          TXDU <= request_data(TX_counter);
        else
          TXDU <= response_data(TX_counter);
        end if;
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
              if (RX_counter = 5) then
                RX_state <= OP;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when OP =>
            if (WrU = '1') then
              if (RX_counter = 1) then
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

  ResponseMAC <= SHA_buf;
  ResponseIP <= SPA_buf;
  RX_DATA: process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (RX_state = SHA and WrU = '1') then
        for i in 0 to 4 loop
          SHA_buf(i) <= SHA_buf(i + 1);
        end loop;
        SHA_buf(5) <= RXDU;
      end if;

      if (RX_state = SPA and WrU = '1') then
        for i in 0 to 2 loop
          SPA_buf(i) <= SPA_buf(i + 1);
        end loop;
        SPA_buf(3) <= RXDU;
      end if;

      if (RX_state = THA and WrU = '1') then
        for i in 0 to 4 loop
          THA_buf(i) <= THA_buf(i + 1);
        end loop;
        THA_buf(5) <= RXDU;
      end if;

      if (RX_state = TPA and WrU = '1') then
        for i in 0 to 2 loop
          TPA_buf(i) <= TPA_buf(i + 1);
        end loop;
        TPA_buf(3) <= RXDU;
      end if;
    end if;
  end process;

  RX_ERR: process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (RX_state = Header) then
        if (WrU = '1') then
          if (RX_counter = 0) then
            if (RXDU = response_data(0)) then
              RX_ARP_ERR <= '0';
            else
              RX_ARP_ERR <= '1';
            end if;
          else
            if (RXDU /= response_data(RX_counter)) then
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
    end if;
  end process;

  RX_output: process (RX_state, RX_ARP_ERR, RX_OP0_dummy, RX_OP1_dummy)
  begin
    if (RX_ARP_ERR = '0' and RX_state = EOP and
      (RX_OP0_dummy & RX_OP1_dummy) = X"0002"
    ) then
      ResponseValid <= '1';
    else
      ResponseValid <= '0';
    end if;
  end process;

  RX_OP_proc: process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (RX_state = OP and WrU = '1') then
        RX_OP0_dummy <= RX_OP1_dummy;
        RX_OP1_dummy <= RXDU;
      end if;
    end if;
  end process;

  RX_NEED_RESPONSE_SET_proc: process (RX_state, RX_OP0_dummy, RX_OP1_dummy, TPA_buf)
  begin
    if (
      RX_state = EOP and
      (RX_OP0_dummy & RX_OP1_dummy) = X"0001" and
      TPA_buf = IP_ADDR
    ) then
      RX_NEED_RESPONSE_SET <= '1';
    else
      RX_NEED_RESPONSE_SET <= '0';
    end if;
  end process;

end Behavioral;
