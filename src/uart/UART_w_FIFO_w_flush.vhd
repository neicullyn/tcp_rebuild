library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_w_FIFO_w_flush is
  port(
    -- Asynchronous reset
    nRST : in std_logic;
    -- CLK
    CLK : in std_logic;
    -- UART interface
    RX_serial : in std_logic;
    TX_serial : out std_logic;
    -- Input Buffer
    DIN : in std_logic_vector(7 downto 0);
    WR : in std_logic;
    FULL : out std_logic;
    FLUSH : in std_logic;
    CLEAR : in std_logic;
    -- Output Buffer
    DOUT : out std_logic_vector(7 downto 0);
    RD : in std_logic;
    DOUTV : out std_logic
  );
end UART_w_FIFO_w_flush;

architecture Structural of UART_w_FIFO_w_flush is
  COMPONENT UART
    PORT(
      CLK : IN  std_logic;
      nRST : IN  std_logic;
      RX_serial : IN  std_logic;
      TX_serial : OUT  std_logic;
      RXD : OUT  std_logic_vector(7 downto 0);
      TXD : IN  std_logic_vector(7 downto 0);
      RXDV : OUT  std_logic;
      TXDV : IN  std_logic;
      wr : out std_logic;
      rd : out  std_logic
    );
  END COMPONENT;

  COMPONENT FIFO
  PORT(
    nRST : IN std_logic;
    CLK : IN std_logic;
    DIN : IN std_logic_vector(7 downto 0);
    PUSH : IN std_logic;
    POP : IN std_logic;
    DOUT : OUT std_logic_vector(7 downto 0);
    EMPTY : OUT std_logic;
    FULL : OUT std_logic
    );
  END COMPONENT;

  COMPONENT FIFO_with_flush
  PORT(
       nRST : IN  std_logic;
       CLK : IN  std_logic;
       DIN : IN  std_logic_vector(7 downto 0);
       DOUT : OUT  std_logic_vector(7 downto 0);
       PUSH : IN  std_logic;
       POP : IN  std_logic;
       EMPTY : OUT  std_logic;
       FULL : OUT  std_logic;
       FLUSH : in std_logic;
       CLEAR : in std_logic
      );
  END COMPONENT;

  signal RD_UART : std_logic;
  signal WR_UART : std_logic;

  signal TXD : std_logic_vector(7 downto 0);
  signal RXD : std_logic_vector(7 downto 0);

  signal TXDV : std_logic;
  signal RXDV : std_logic;

  signal TX_PUSH : std_logic;
  signal TX_POP : std_logic;
  signal TX_EMPTY : std_logic;
  signal TX_FULL :std_logic;

  signal RX_PUSH : std_logic;
  signal RX_POP : std_logic;
  signal RX_EMPTY : std_logic;
  signal RX_FULL :std_logic;
begin
  UART_inst: UART PORT MAP (
    CLK => CLK,
    nRST => nRST,
    RX_serial => RX_serial,
    TX_serial => TX_serial,
    RXD => RXD,
    TXD => TXD,
    RXDV => RXDV,
    TXDV => TXDV,
    WR => WR_UART,
    RD => RD_UART
  );

  TX_FIFO: FIFO_with_flush PORT MAP(
    nRST => nRST,
    CLK => CLK,
    DIN => DIN,
    DOUT => TXD,
    PUSH => TX_PUSH,
    POP => TX_POP,
    EMPTY => TX_EMPTY,
    FULL => TX_FULL,
    FLUSH => FLUSH,
    CLEAR => CLEAR
  );

  RX_FIFO: FIFO PORT MAP(
    nRST => nRST,
    CLK => CLK,
    DIN => RXD,
    DOUT => DOUT,
    PUSH => RX_PUSH,
    POP => RX_POP,
    EMPTY => RX_EMPTY,
    FULL => RX_FULL
  );

  TX_PUSH <= WR;
  TX_POP <= RD_UART;
  FULL <= TX_FULL;

  TXDV <= not TX_EMPTY;

  RX_PUSH <= WR_UART;
  RX_POP <= RD;
  DOUTV <= not RX_EMPTY;
end Structural;

