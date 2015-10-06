library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity IP is
  Port (
    CLK : in std_logic;
    nRST : in std_logic;

    TXDV : in std_logic;
    TXEN : out std_logic;
    TXDC : in std_logic_vector (7 downto 0);
    TXDU : out std_logic_vector (7 downto 0);
    TXIDLE : out std_logic;
    RdC : out std_logic;
    RdU : in std_logic;

    DST_IP_ADDR : in IP_ADDR_TYPE;

    TX_DataLength : std_logic_vector (15 downto 0);

    DST_MAC_ADDR : out MAC_ADDR_TYPE;

    MACLookUp_InputIP : out IP_ADDR_TYPE;
    MACLookUp_Start : out std_logic;
    MACLookUp_OutputMAC : out MAC_ADDR_TYPE;
    MACLOokUP_OutputValid : out std_logic;

    ResponseMAC : in IP_ADDR_TYPE;
    ResponseValid : in std_logic;

    RXDC : out std_logic_vector (7 downto 0);
    RXDU : in std_logic_vector (7 downto 0);
    WrC : out std_logic;
    WrU : in std_logic;
    RXER : in std_logic;
    RXEOP : in std_logic;

    TX_PROTOCOL : in L4_PROTOCOL;
    RX_PROTOCOL : out L4_PROTOCOL;
  );
end IP;

architecture Behavioral of IP is
  component CHECKSUM is
    Port (
      CLK : in  STD_LOGIC;
      DATA : in  STD_LOGIC_VECTOR (7 downto 0);
      nRST : in  STD_LOGIC;
      INIT : in STD_LOGIC;
      D_VALID : in  STD_LOGIC;
      CALC: in STD_LOGIC;
      REQ : in  STD_LOGIC;
      SELB : in STD_LOGIC;
      CHKSUM : out  STD_LOGIC_VECTOR (7 downto 0)
    );
  end component;

  type TX_states is (Idle, MACLookUp, Header, GenCheckSum, Checksum, Src, Dst, Data);
  signal TX_state : TX_states;
  signal TX_counter: integer range 0 to 1023;

  type HEADER_TYPE is array (0 to 9) of std_logic_vector (7 downto 0);
  signal TX_Header : HEADER_TYPE;

  signal TX_TotalLength : std_logic_vector (15 downto 0);

  signal DST_IP_ADDR_buf : IP_ADDR_TYPE;

  signal TXCHKSUM_DATA : std_logic_vector (7 downto 0);
  signal TXCHKSUM_INIT : std_logic;
  signal TXCHKSUM_D_VALID : std_logic;
  signal TXCHKSUM_CALC : std_logic;
  signal TXCHKSUM_REQ : std_logic;
  signal TXCHKSUM_SELB : std_logic;
  signal TXCHKSUM_CHKSUM : std_logic_vector (7 downto 0);
begin
  TX_TotalLength <= TX_DataLength + 20;

  TX_Header(0) <= X"45"; -- Version = 4, IHL = 5
  TX_Header(1) <= X"00"; -- Best effort, and no ECN
  TX_Header(2) <= TX_TotalLength (15 downto 8);
  TX_Header(3) <= TX_TotalLength (7 downto 0);

  TX_Header(4) <= X"00"; -- Not using fragmentation
  TX_Header(5) <= X"00";
  TX_Header(6) <= X"00";
  TX_Header(7) <= X"00";

  TX_Header(8) <= X"07"; -- TTL:7
  TX_PROTOCOL_proc: process (TX_PROTOCOL)
  begin
    case TX_PROTOCOL is
      when TCP =>
        TX_Header(9) <= TCP_PROTOCOL_TYPE;
      when UDP =>
        TX_Header(9) <= UDP_PROTOCOL_TYPE;
      when UNKNOWN =>
        TX_Header(9) <= UDP_PROTOCOL_TYPE;
    end case;
  end process;

  TX_SM: process (nRST, CLK)
  begin
    if (nRST = '0') then
      TX_state <= Idle;
    elsif (rising_edge(CLK)) then
      case TX_state is
        when Idle =>
          if (TXDV = '1') then
            TX_state <= WaitForMACLookUp;
          end if;

        when MACLookUp =>
          if (MACLOokUP_OutputValid = '1') then
            TX_state <= Header;
            TX_counter <= 0;
          end if;

        when Header =>
          if (RdU = '1') then
            if (TX_counter = 17) then
              TX_state <= GenChecksum;
              TX_counter <= 0;
            else
              TX_counter <= TX_counter + 1;
            end if;
          end if;

        when GenChecksum =>
          TX_state <= Checksum;

        when Checksum =>
          if (RdU = '1') then
            if (TX_counter = 1) then
              TX_state <= Src;
              TX_counter <= 0;
            else
              TX_counter <= TX_counter + 1;
            end if;
          end if;

        when Src =>
          if (RdU = '1') then
            if (TX_counter = 3) then
              TX_state <= Dst;
              TX_counter <= 0;
            else
              TX_counter <= TX_counter + 1;
            end if;
          end if;

        when Dst =>
          if (RdU = '1') then
            if (TX_counter = 3) then
              TX_state <= Data;
              TX_counter <= 0;
            else
              TX_counter <= TX_counter + 1;
            end if;
          end if;

        when Data =>
          if (TXDV = '0') then
            TX_state <= Idle;
          end if;
      end case;
    end if;
  end process;

  TX_EN: process (TX_state, TXDV, RdU)
  begin
    TXEN <= '1';
    if (TX_state = Idle) then
      TXEN <= '0';
    end if;

    RdC <= '0';
    if (TX_state = Data and TXDV = '1' and RdU = '1') then
      RdC <= '1';
    end if;
  end process;

  TXIDLE <= '1' when TX_state = Idle else '0';

  TX_DATA: process (TX_state, TX_counter, TXCHKSUM_CHKSUM)
  begin
    case TX_state is
      when Idle =>
        TXDU <= X"00";
      when Header =>
        TXDU <= TX_Header(TX_counter);
      when Checksum =>
        TXDU <= TXCHKSUM_CHKSUM;
      when Src =>
        TXDU => IP_ADDR(TX_counter);
      when Dst =>
        TXDU => DST_IP_ADDR_buf(TX_counter);
      when Data =>
        TXDU <= TXDC;
    end case;
  end process;

  DST_IP_ADDR_buf_proc: process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (TX_state = Idle and TXDV = '1') then
        DST_IP_ADDR_buf <= DST_IP_ADDR;
      end if;
    end if;
  end process;

  TXCHKSUM: CHECKSUM
  port map(
    CLK => CLK,
    DATA => TXCHKSUM_DATA,
    nRST => nRST,
    INIT => TXCHKSUM_INIT,
    D_VALID => TXCHKSUM_D_VALID,
    CALC => TXCHKSUM_CALC,
    REQ => TXCHKSUM_REQ,
    SELB => TXCHKSUM_SELB,
    CHKSUM => TXCHKSUM_CHKSUM
  );

  TXCHKSUM_DATA <= TXDC;

  TXCHKSUM_control: process (TXDV, RdU, TX_state)
  begin
    if (TXDV = '1' and TX_state = Idle) then
      TXCHKSUM_INIT <= '1';
    else
      TXCHKSUM_INIT <= '0';
    end if;

    if (TX_state = Header and RdU = '1') then
      TXCRC_D_VALID <= '1';
      TXCHKSUM_CALC = '1';
    else
      TXCRC_D_VALID <= '1';
      TXCHKSUM_CALC = '0';
    end if;

    if (TX_state = GenChecksum or TX_state = Checksum) then
      TXCHKSUM_REQ <= '1';
    else
      TXCHKSUM_REQ <= '0';
    end if;

    if (TX_state = Checksum) then
      TXCHKSUM_SELB <= '1';
    elsif (TX_counter mod 2 = 1) then
      TXCHKSUM_SELB <= '1';
    else
      TXCHKSUM_SELB <= '0';
    end if;
  end process;
end Behavioral;