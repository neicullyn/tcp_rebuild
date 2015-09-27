----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    08:30:46 05/26/2015
-- Design Name:
-- Module Name:    MAC - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 1. No segametion or assembly function implemented. During demonstration, use proper
-- size of packets, or handle that at the application layer.
-- 2. For interpacket idle bytes, use '0' temporily. Modify appropriately if not correct.
-- More specifically, now send 12 octets consists of zeros, and then TXDV becomes '0'.
-- 3. Using Ethernet II standard, modify properly when necessary
-- 4. In Ethernet II standard, the end of MAC frame is determined by the interpacket gap,
-- which in our case would require 16 octets in advance and thus needs access to RAM.
-- Ignore this functionality here, and assume the length is predefined for the demonstration
-- by the constant RX_LENGTH
----------------------------------------------------------------------------------
library IEEE;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;
entity MAC is
  Port (
    CLK : in STD_LOGIC;  -- global clock
    nRST : in STD_LOGIC;  -- global reset, active low
    TXDV : in STD_LOGIC; -- transmiision data ready from client layer
    TXEN : out STD_LOGIC; -- transmission data ready for underlying layer (MII)
    TXDC : in STD_LOGIC_VECTOR (7 downto 0); -- transmission data bus from client layer via collector
    TXDU : out STD_LOGIC_VECTOR (7 downto 0); -- transmission data bus to underlying layer
    TXIDLE : out STD_LOGIC; -- TX is idle
    DST_MAC_ADDR : in MAC_ADDR_TYPE;
    RXDC : out STD_LOGIC_VECTOR (7 downto 0); -- receive data bus to client layer via dispatcher
    RXDU : in STD_LOGIC_VECTOR (7 downto 0); -- receive data bus from the underlying layer
    RXER : out STD_LOGIC; -- receive data error
    RXEOP: out STD_LOGIC; -- End of a packet
    MDIO_Busy : in STD_LOGIC; -- MDIO busy signal
    MDIO_nWR : out STD_LOGIC; -- MDIO writing control, active low
    MDIO_nRD : out STD_LOGIC; -- MDIO reading control, active low
    RdC: out STD_LOGIC; -- Read pulse for client layer
    WrC: out STD_LOGIC; -- Write pulse for client layer
    RdU: in STD_LOGIC; -- Read pulse from MII
    WrU: in STD_LOGIC; -- Write pulse from MII
    TX_PROTOCOL : in L3_PROTOCOL; -- Protocol selection via collector during transmission, 0 for IP, 1 for ARP
    RX_PROTOCOL : out L3_PROTOCOL; -- Protocol selection via dispatcher during receiving, 0 for IP, 1 for ARP
    TXCLK_f : in std_logic; -- falling edge of TXCLK
    RXCLK_f : in std_logic
  );
end MAC;

architecture Behavioral of MAC is
  -- MAC states and counters
  type TX_states is (Idle, Preamble, SFD, Dst, Src, EtherType, Payload, FCS, Interpacket);
    -- Preamble, SFD, Interpacket may not be transmitted
  type RX_states is (Idle, Dst, Src, EtherType, Payload, EOP);

  signal TX_state: TX_states;
  signal RX_state: RX_states;
  signal TX_counter: integer range 0 to 256;
  signal RX_counter: integer range 0 to 256;
  signal RX_interpacket_counter: integer range 0 to 15;
  signal counter: integer := 0; -- general use counter
  -- Dispatcher and Collecotr selection signal

  signal TXDU_dummy: std_logic_vector(7 downto 0);

  -- Make sure MDIO is configured already
  type status is (PowerOn, Configuring, Waiting, Ready);
  signal Sys_status: status := PowerOn;

  -- FCS calculator
  component CRC is
    Port (
      CLOCK               :   in  std_logic;
      RESET               :   in  std_logic;
      DATA                :   in  std_logic_vector(7 downto 0);
      LOAD_INIT           :   in  std_logic;
      CALC                :   in  std_logic;
      D_VALID             :   in  std_logic;
      CRC                 :   out std_logic_vector(7 downto 0);
      CRC_REG             :   out std_logic_vector(31 downto 0);
      CRC_VALID           :   out std_logic
    );
  end component;

  -- CRC signals
  signal RST: STD_LOGIC;

  signal TXCRC_LOAD_INIT : std_logic;
  signal TXCRC_CALC : std_logic;
  signal TXCRC_D_VALID : std_logic;
  signal TXCRC_CRC: STD_LOGIC_VECTOR(7 downto 0);

  signal RXCRC_LOAD_INIT : std_logic;
  signal RXCRC_CALC : std_logic;
  signal RXCRC_D_VALID : std_logic;
  signal RXCRC_CRC_VALID : std_logic;

  -- Mac address checker
  component MACAddressCheck is
    port (
      CLK : in std_logic;
      EN : in std_logic;
      DIN : in std_logic_vector(7 downto 0);
      AddrValid : out std_logic
    );
  end component;

  signal MACAddressCheck_EN: std_logic;
  signal MACAddressCheck_AddrValid : std_logic;

  -- Client selecter
  signal EtherTypeByte0: std_logic_vector(7 downto 0);
  signal EtherTypeByte1: std_logic_vector(7 downto 0);

begin
  RST <= not nRST;

  --TXDU <= TX_register;
  MDIO_conf: process(nRST, CLK)
  begin
    if (nRST = '0') then
      Sys_status <= PowerOn;
    elsif (rising_edge(CLK)) then
      case Sys_status is
        when PowerOn =>
          if (MDIO_busy = '0') then
            Sys_status <= Configuring;
            counter <= 0;
          end if;

        when Configuring =>
          MDIO_nWR <= '1';
          counter <= counter + 1;
          if (counter = 40) then
            MDIO_nWR <= '0';
            Sys_status <= Waiting;
          end if;

        when Waiting =>
          if (MDIO_busy = '0') then
            Sys_status <= Ready;
          end if;

        when Ready =>
          null;
      end case;
    end if;
  end process;

  TX_SM: process (CLK, nRST)
  begin
    if (nRST = '0') then
      TX_state <= Idle;
      TX_counter <= 0;
    elsif (rising_edge(CLK)) then
      if (Sys_status = Ready) then
        case TX_state is
          when Idle =>
            if (TXDV = '1') then
              TX_state <= Preamble;
              TX_counter <= 0;
            end if;

          when Preamble =>
            if (RdU = '1') then
              if (TX_counter = 6) then
                TX_state <= SFD;
                TX_counter <= 0;
              else
                TX_counter <= TX_counter + 1;
              end if;
            end if;

          when SFD =>
            if (RdU = '1') then
              TX_state <= Dst;
              TX_counter <= 0;
            end if;

          when Dst =>
            if (RdU = '1') then
              if (TX_counter = 5) then
                TX_state <= Src;
                TX_counter <= 0;
              else
                TX_counter <= TX_counter + 1;
              end if;
            end if;

          when Src =>
            if (RdU = '1') then
              if (TX_counter = 5) then
                TX_state <= EtherType;
                TX_counter <= 0;
              else
                TX_counter <= TX_counter + 1;
              end if;
            end if;

          when EtherType =>
            if (RdU = '1') then
              if (TX_counter = 1) then
                TX_state <= Payload;
                TX_counter <= 0;
              else
                TX_counter <= TX_counter + 1;
              end if;
            end if;

          when Payload =>
            if (TXDV = '1' or TX_counter < 45) then
              if (RdU = '1') then
                TX_counter <= TX_counter + 1;
              end if;
            else
              if (RdU = '1') then
                TX_state <= FCS;
                TX_counter <= 0;
              end if;
            end if;

          when FCS =>
            if (RdU = '1') then
              if (TX_counter = 3) then
                TX_state <= Interpacket;
                TX_counter <= 0;
              else
                TX_counter <= TX_counter + 1;
              end if;
            end if;

          when Interpacket =>
            if (TXCLK_f = '1') then
              if (TX_counter = 11) then
                TX_state <= Idle;
                TX_counter <= 0;
              else
                TX_counter <= TX_counter + 1;
              end if;
            end if;

        end case;
      end if;
    end if;
  end process;

  TX_EN: process (TX_state, TXDV, RdU)
  begin
    TXEN <= '1';
    if (TX_state = Idle or TX_state = Interpacket) then
      TXEN <= '0';
    end if;

    RdC <= '0';
    if (TX_state = Payload and TXDV = '1' and RdU = '1') then
      RdC <= '1';
    end if;
  end process;

  TXIDLE <= '1' when TX_state = Idle else '0';

  TXDU <= TXDU_dummy;
  TX_DATA: process (TX_state, TX_counter, TXCRC_CRC)
  begin
    case TX_state is
      when Idle =>
        TXDU_dummy <= X"00";

      when Preamble =>
        TXDU_dummy <= X"55";

      when SFD =>
        TXDU_dummy <= X"D5";

      when Dst =>
        TXDU_dummy <= DST_MAC_ADDR(TX_counter);

      when Src =>
        TXDU_dummy <= MAC_ADDR(TX_counter);

      when EtherType =>
        case TX_PROTOCOL is
          when IP =>
            TXDU_dummy <= IP_ETHERTYPE_CODE(TX_counter);
          when ARP =>
            TXDU_dummy <= ARP_ETHERTYPE_CODE(TX_counter);
        end case;

      when Payload =>
        if (TXDV = '1') then
          TXDU_dummy <= TXDC;
        else
          TXDU_dummy <= X"00";
        end if;

      when FCS =>
        TXDU_dummy <= TXCRC_CRC;

      when Interpacket =>
        TXDU_dummy <= X"00";
    end case;
  end process;

  TXCRC: CRC
  port map(
    CLOCK  => CLK,
    RESET => RST,
    DATA => TXDU_dummy,
    LOAD_INIT => TXCRC_LOAD_INIT,
    CALC => TXCRC_CALC,
    D_VALID => TXCRC_D_VALID,
    CRC => TXCRC_CRC,
    CRC_REG => open,
    CRC_VALID => open
  );

  TXCRC_control: process (TXDV, RdU, TX_state)
  begin
    if (TXDV = '1' and TX_state = Idle) then
      TXCRC_LOAD_INIT <= '1';
    else
      TXCRC_LOAD_INIT <= '0';
    end if;

    if (RdU = '1' and
      (
        TX_state = Dst or TX_state = Src or
        TX_state = EtherType or TX_state = Payload or
        TX_state = FCS
      )
    ) then
      TXCRC_D_VALID <= '1';
    else
      TXCRC_D_VALID <= '0';
    end if;

    if (RdU = '1' and
      (
        TX_state = Dst or TX_state = Src or
        TX_state = EtherType or TX_state = Payload
      )
    ) then
      TXCRC_CALC <= '1';
    else
      TXCRC_CALC <= '0';
    end if;
  end process;

  RX_SM: process (CLK, nRST)
  begin
    if (nRST = '0') then
      RX_state <= Idle;
      RX_counter <= 0;
      RX_interpacket_counter <= 0;
    elsif (rising_edge(CLK)) then
      if (Sys_status = Ready) then
        case RX_state is
          when Idle =>
            if (WrU = '1') then
              if (RXDU = X"D5") then
                RX_state <= Dst;
              end if;
            end if;

          when Dst =>
            if (WrU = '1') then
              if (RX_counter = 5) then
                RX_state <= Src;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when Src =>
            if (WrU = '1') then
              if (RX_counter = 5) then
                RX_state <= EtherType;
                RX_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when EtherType =>
            if (WrU = '1') then
              if (RX_counter = 1) then
                RX_state <= Payload;
                RX_counter <= 0;
                RX_interpacket_counter <= 0;
              else
                RX_counter <= RX_counter + 1;
              end if;
            end if;

          when Payload =>
            if (WrU = '1') then
              RX_interpacket_counter <= 0;
            elsif (RX_interpacket_counter = 10) then
              RX_state <= EOP;
            elsif (RXCLK_f = '1') then
              RX_interpacket_counter <= RX_interpacket_counter + 1;
            end if;

          when EOP =>
            RX_state <= Idle;
        end case;
      end if;
    end if;
  end process;

  MACAddressCheck_inst : MACAddressCheck
  port map (
    CLK => CLK,
    EN => MACAddressCheck_EN,
    DIN => RXDU,
    AddrValid => MACAddressCheck_AddrValid
  );

  MACAddressCheck_control : process (WrU, RX_state)
  begin
    if (WrU = '1' and RX_state = Dst) then
      MACAddressCheck_EN <= '1';
    else
      MACAddressCheck_EN <= '0';
    end if;
  end process;

  RXCRC: CRC
  port map(
    CLOCK  => CLK,
    RESET => RST,
    DATA => RXDU,
    LOAD_INIT => RXCRC_LOAD_INIT,
    CALC => RXCRC_CALC,
    D_VALID => RXCRC_D_VALID,
    CRC => open,
    CRC_REG => open,
    CRC_VALID => RXCRC_CRC_VALID
  );

  RXCRC_control: process (WrU, RX_state)
  begin
    if (WrU = '1' and RX_state = Idle) then
      RXCRC_LOAD_INIT <= '1';
    else
      RXCRC_LOAD_INIT <= '0';
    end if;

    if (WrU = '1' and
      (
        RX_state = Dst or RX_state = Src or
        RX_state = EtherType or RX_state = Payload
      )
    ) then
      RXCRC_CALC <= '1';
      RXCRC_D_VALID <= '1';
    else
      RXCRC_CALC <= '0';
      RXCRC_D_VALID <= '0';
    end if;
  end process;

  RXER_process: process (RXCRC_CRC_VALID, MACAddressCheck_AddrValid, RX_state)
  begin
    if (RX_state = EOP) then
      RXER <= not (RXCRC_CRC_VALID and MACAddressCheck_AddrValid);
    else
      RXER <= '0';
    end if;
  end process;

  RXDC <= RXDU;

  WrC_process: process (WrU, RX_state)
  begin
    if (RX_state = Payload) then
      WrC <= WrU;
    else
      WrC <= '0';
    end if;
  end process;

  RXEOP <= '1' when RX_state = EOP else '0';

  Client_process: process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (RX_state = EtherType and WrU = '1') then
        EtherTypeByte0 <= EtherTypeByte1;
        EtherTypeByte1 <= RXDU;
      end if;
    end if;
  end process;

  RX_PROTOCOL <= ARP when (EtherTypeByte0 & EtherTypeByte1) = X"0806" else IP;

end Behavioral;
