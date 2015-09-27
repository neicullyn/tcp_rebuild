----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:29:59 06/04/2015
-- Design Name:
-- Module Name:    shell - Behavioral
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
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.TCP_CONSTANTS.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shell is
	port(
			-- Clock
			CLK : in  STD_LOGIC;

			-- Switches and buttons
			SW : in  STD_LOGIC_VECTOR (7 downto 0);
			BTN : in  STD_LOGIC_VECTOR (4 downto 0);

			-- Digits
			SSEG_CA : out  STD_LOGIC_VECTOR (7 downto 0);
			SSEG_AN : out  STD_LOGIC_VECTOR (3 downto 0);

			-- LED
			LED : out  STD_LOGIC_VECTOR (7 downto 0);

			-- UART
			UART_RXD : in std_logic;
			UART_TXD : out std_logic;

			-- RAM
			RAM_ADDR : out std_logic_vector(25 downto 0);
			RAM_DATA : inout std_logic_vector(15 downto 0);
			RAM_CLK_out : out std_logic;
			RAM_nCE : out std_logic;
			RAM_nWE : out std_logic;
			RAM_nOE : out std_logic;
			RAM_nADV : out std_logic;
			RAM_CRE : out std_logic;
			RAM_nLB : out std_logic;
			RAM_nUB : out std_logic;
			RAM_WAIT_in : in std_logic;

			-- PHY
			PHY_MDIO : inout std_logic;
			PHY_MDC : out std_logic;
			PHY_nRESET : out std_logic;
			PHY_COL : in std_logic;
			PHY_CRS : in std_logic;

			PHY_TXD : out std_logic_vector(3 downto 0);
			PHY_nINT : out std_logic;
			PHY_TXEN : out std_logic;
			PHY_TXCLK : in std_logic;

			PHY_RXD : in std_logic_vector(3 downto 0);
			PHY_RXER : in std_logic;
			PHY_RXDV : in std_logic;
			PHY_RXCLK : in std_logic

		);
end shell;

architecture Behavioral of shell is
    COMPONENT MDIO
    PORT(
         CLK : IN  std_logic;
         nRST : IN  std_logic;
         CLK_MDC : OUT  std_logic;
         data_MDIO : INOUT  std_logic;
         busy : OUT  std_logic;
         nWR : IN  std_logic;
         nRD : IN  std_logic
        );
    END COMPONENT;

	COMPONENT EdgeDetect
	PORT(
		sin : IN std_logic;
		CLK : IN std_logic;
		srising : OUT std_logic;
		sfalling : OUT std_logic
		);
	END COMPONENT;

	COMPONENT btn_debounce
	PORT(
		BTN_I : IN std_logic_vector(4 downto 0);
		CLK : IN std_logic;
		BTN_O : OUT std_logic_vector(4 downto 0)
		);
	END COMPONENT;

	COMPONENT UART_w_FIFO
	PORT(
		nRST : IN std_logic;
		CLK : IN std_logic;
		RX_serial : IN std_logic;
		DIN : IN std_logic_vector(7 downto 0);
		WR : IN std_logic;
		RD : IN std_logic;
		TX_serial : OUT std_logic;
		FULL : OUT std_logic;
		DOUT : OUT std_logic_vector(7 downto 0);
		DOUTV : OUT std_logic
		);
	END COMPONENT;

	COMPONENT MAC
	PORT(
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
	END COMPONENT;

	COMPONENT MII
	PORT(
		CLK : IN std_logic;
		TXCLK : IN std_logic;
		RXCLK : IN std_logic;
		nRST : IN std_logic;
		TXDV : IN std_logic;
		RXDV : IN std_logic;
		TX_in : IN std_logic_vector(7 downto 0);
		RXD : IN std_logic_vector(3 downto 0);
		TXEN : OUT std_logic;
		TXD : OUT std_logic_vector(3 downto 0);
		RX_out : OUT std_logic_vector(7 downto 0);
		WR : OUT std_logic;
		RD : OUT std_logic;
		TXCLK_f : OUT std_logic;
		RXCLK_f : OUT std_logic
		);
	END COMPONENT;

	COMPONENT ARP
	Port (
    CLK : in  STD_LOGIC;
    nRST: in  STD_LOGIC;

    TXEN: out STD_LOGIC;
    TXDU: out  STD_LOGIC_VECTOR (7 downto 0);
    TXIDLE: out STD_LOGIC;

    RXDU: in  STD_LOGIC_VECTOR (7 downto 0);
    RXER: in STD_LOGIC;
    RXEOP: in STD_LOGIC;

    RdU: in STD_LOGIC;
    WrU: in STD_LOGIC;

    DST_MAC_ADDR :  out MAC_ADDR_TYPE;
    RequestIP: in IP_ADDR_TYPE;
    RequestValid: in STD_LOGIC;

    ResponseIP: out IP_ADDR_TYPE;
    ResponseMAC: out MAC_ADDR_TYPE;
    ResponseValid: out STD_LOGIC
  );
	END COMPONENT;

	COMPONENT Collector_L23
	PORT(
		CLK : IN std_logic;
		nRST : IN std_logic;
		RdU : IN std_logic;
		TXDC_ARP : IN std_logic_vector(7 downto 0);
		TXDV_ARP : IN std_logic;
		DST_MAC_ADDR_ARP : IN MAC_ADDR_TYPE;
		TXDC_IP : IN std_logic_vector(7 downto 0);
		TXDV_IP : IN std_logic;
		DST_MAC_ADDR_IP : IN MAC_ADDR_TYPE;
		TXDU : OUT std_logic_vector(7 downto 0);
		TXEN : OUT std_logic;
		DST_MAC_ADDR : OUT MAC_ADDR_TYPE;
		TX_PROTOCOL : OUT L3_PROTOCOL;
		RdC_ARP : OUT std_logic;
		RdC_IP : OUT std_logic
		);
	END COMPONENT;

	COMPONENT Dispatcher_L23
	PORT(
		CLK : IN std_logic;
		nRST : IN std_logic;
		RXDU : IN std_logic_vector(7 downto 0);
		WrU : IN std_logic;
		RXER : in STD_LOGIC;
    RXEOP : in STD_LOGIC;
		RX_PROTOCOL : IN L3_PROTOCOL;
		RXDC_ARP : OUT std_logic_vector(7 downto 0);
		WrC_ARP : OUT std_logic;
		RXER_ARP : OUT std_logic;
    RXEOP_ARP : OUT std_logic;
		RXDC_IP : OUT std_logic_vector(7 downto 0);
		WrC_IP : OUT std_logic;
		RXER_IP : OUT std_logic;
    RXEOP_IP : OUT std_logic
	);
	END COMPONENT;

	signal nRST : std_logic;

	-- Signal for UART
	signal UART_DIN : std_logic_vector(7 downto 0);
	signal UART_WR : std_logic;
	signal UART_FULL : std_logic;

	signal UART_DOUT : std_logic_vector(7 downto 0);
	signal UART_RD : std_logic;
	signal UART_DOUTV : std_logic;


	-- Signal for buttons
	signal BTN_db : std_logic_vector(4 downto 0); -- Debounced button signal
	signal BTN_dly : std_logic_vector(4 downto 0); -- Delayed button signal
	signal BTN_r : std_logic_vector(4 downto 0); -- Rising edge of buttons
	signal BTN_f : std_logic_vector(4 downto 0); -- Falling edge of buttons

	-- Signals for MDIO
	signal MDIO_busy : std_logic;
	signal MDIO_nWR : std_logic;
	signal MDIO_nRD : std_logic;

	-- Signals for MAC
	signal MAC_TXDV : std_logic;
	signal MAC_TXEN : std_logic;
	signal MAC_TXDC : std_logic_vector(7 downto 0);
	signal MAC_TXDU : std_logic_vector(7 downto 0);
	signal MAC_TXIDLE : std_logic;
	signal MAC_DST_MAC_ADDR : MAC_ADDR_TYPE;
	signal MAC_RXDC : std_logic_vector(7 downto 0);
	signal MAC_RXDU : std_logic_vector(7 downto 0);
	signal MAC_RXER : std_logic;
	signal MAC_RXEOP : std_logic;
	signal MAC_RdC : std_logic;
	signal MAC_WrC : std_logic;
	signal MAC_RdU : std_logic;
	signal MAC_WrU : std_logic;
	signal TX_L3_PROTOCOL : L3_PROTOCOL;
	signal RX_L3_PROTOCOL : L3_PROTOCOL;
	signal MAC_TXCLK_f : std_logic;
	signal MAC_RXCLK_f : std_logic;

	-- Signals for ARP
	signal ARP_TXEN : std_logic;
	signal ARP_TXDU : std_logic_vector(7 downto 0);
	signal ARP_TXIDLE : std_logic;
	signal ARP_RXDU: std_logic_vector(7 downto 0);
	signal ARP_RXER: std_logic;
	signal ARP_RXEOP: std_logic;
	signal ARP_RdU: std_logic;
	signal ARP_WrU: std_logic;
	signal ARP_DST_MAC_ADDR : MAC_ADDR_TYPE;
	signal ARP_RequestIP: IP_ADDR_TYPE;
	signal ARP_RequestValid: std_logic;
	signal ARP_ResponseIP: IP_ADDR_TYPE;
	signal ARP_ResponseMAC: MAC_ADDR_TYPE;
	signal ARP_ResponseValid: std_logic;


	--- DEBUG
	signal flip : std_logic;
	signal busy_test : std_logic;
	signal MDIO_MDIO : std_logic;

	signal PHY_TXEN_dummy : std_logic;
	signal MAC_TXEN_r : std_logic;
	signal MAC_TXEN_f : std_logic;

	signal PHY_RXER_INDICATE : std_logic;
	signal RXER_INDICATE : std_logic;
	signal RXEOP_INDICATE : std_logic;
	signal RX_PROTOCOL_INDICATE: std_logic;
begin

	PHY_TXEN <= PHY_TXEN_dummy;
	SSEG_CA <= (others => '0');
	SSEG_AN <= (others => '1');

	PHY_MDIO <= MDIO_MDIO;
	RX_PROTOCOL_INDICATE <= '1' when (RX_L3_PROTOCOL = IP) else '0';
	LED <= (0 => UART_DOUTV, 1 => RX_PROTOCOL_INDICATE, 2 => PHY_TXEN_dummy,
			3 => MAC_RdU, 4 => MAC_RdC, 5 => PHY_RXER_INDICATE, 6 => RXER_INDICATE, 7 => RXEOP_INDICATE, others => '0');

	RAM_ADDR <= (others => '0');
	RAM_CLK_out <= '0';
	RAM_nCE <= '1';
	RAM_nWE <= '1';
	RAM_nOE <= '1';
	RAM_nADV <= '1';
	RAM_CRE <= '0';
	RAM_nLB <= '1';
	RAM_nUB <= '1';

	PHY_nRESET <= nRST;
	PHY_nINT <= '1';


	UART_w_FIFO_inst: UART_w_FIFO PORT MAP(
		nRST => nRST,
		CLK => CLK,
		RX_serial => UART_RXD,
		TX_serial => UART_TXD,
		DIN => UART_DIN,
		WR => UART_WR,
		FULL => UART_FULL,
		DOUT => UART_DOUT,
		RD => UART_RD,
		DOUTV => UART_DOUTV
	);

	nRST <= not BTN(4);

	process (CLK)
	begin
		if(BTN_r(0) = '1') then
			flip <= not flip;
		end if;
	end process;

	process (nRST, CLK)
	begin
		if (nRST = '0') then
			busy_test <= '1';
		elsif (rising_edge(CLK)) then
			if (MDIO_busy = '1') then
				busy_test <= '0';
			end if;
		end if;
	end process;

	btn_debounce_inst: btn_debounce PORT MAP(
		BTN_I => BTN,
		CLK => CLK,
		BTN_O => BTN_db
	);

	process(CLK)
	begin
		if(rising_edge(CLK)) then
			BTN_dly <= BTN_db;
		end if;
	end process;

	process(BTN_dly, BTN_db)
	begin
		for i in 0 to 4 loop
			if (BTN_db(i) = '1' and BTN_dly(i) = '0') then
				-- 0 -> 1 : Rising edge
				BTN_r(i) <= '1';
			else
				BTN_r(i) <= '0';
			end if;

			if (BTN_db(i) = '0' and BTN_dly(i) = '1') then
				-- 0 -> 1 : Falling edge
				BTN_f(i) <= '1';
			else
				BTN_f(i) <= '0';
			end if;
		end loop;
	end process;

	--MAC
	MAC_inst: MAC PORT MAP(
		CLK => CLK,
		nRST => nRST,
		TXDV => MAC_TXDV,
		TXEN => MAC_TXEN,
		TXDC => MAC_TXDC,
		TXDU => MAC_TXDU,
		TXIDLE => MAC_TXIDLE,
		DST_MAC_ADDR => MAC_DST_MAC_ADDR,
		RXDC => MAC_RXDC,
		RXDU => MAC_RXDU,
		RXER => MAC_RXER,
		RXEOP => MAC_RXEOP,
		MDIO_Busy => MDIO_Busy,
		MDIO_nWR => MDIO_nWR,
		MDIO_nRD => MDIO_nRD,
		RdC => MAC_RdC,
		WrC => MAC_WrC,
		RdU => MAC_RdU,
		WrU => MAC_WrU,
		TX_PROTOCOL => TX_L3_PROTOCOL,
		RX_PROTOCOL => RX_L3_PROTOCOL,
		TXCLK_f => MAC_TXCLK_f,
		RXCLK_f => MAC_RXCLK_f
	);

	-- MDIO
  MDIO_inst: MDIO PORT MAP (
        CLK => CLK,
        nRST => nRST,
        CLK_MDC => PHY_MDC,
        data_MDIO => MDIO_MDIO,
        busy => MDIO_busy,
        nWR => MDIO_nWR,
        nRD => MDIO_nRD
      );

	-- MII
	MII_inst: MII PORT MAP(
		CLK => CLK,
		TXCLK => PHY_TXCLK,
		RXCLK => PHY_RXCLK,
		nRST => nRST,
		TXDV => MAC_TXEN,
		TXEN => PHY_TXEN_dummy,
		RXDV => PHY_RXDV,
		TX_in => MAC_TXDU,
		TXD => PHY_TXD,
		RXD => PHY_RXD,
		RX_out => MAC_RXDU,
		WR => MAC_WrU,
		RD => MAC_RdU,
		TXCLK_f => MAC_TXCLK_f,
		RXCLK_f => MAC_RXCLK_f
	);

	ARP_inst: ARP PORT MAP(
		CLK => CLK,
		nRST => nRST,
		TXEN => ARP_TXEN,
		TXDU => ARP_TXDU,
		RXDU => ARP_RXDU,
		RXER => ARP_RXER,
		RXEOP => ARP_RXEOP,
		RdU => ARP_RdU,
		WrU => ARP_WrU,
		DST_MAC_ADDR => ARP_DST_MAC_ADDR,
		RequestIP => ARP_RequestIP,
		RequestValid => ARP_RequestValid,
		ResponseIP => ARP_ResponseIP,
		ResponseMAC => ARP_ResponseMAC,
		ResponseValid => ARP_ResponseValid
	);

	Collector_L23_inst: Collector_L23 PORT MAP(
		CLK => CLK,
		nRST => nRST,
		TXDU => MAC_TXDC,
		TXEN => MAC_TXDV,
		DST_MAC_ADDR => MAC_DST_MAC_ADDR,
		RdU => MAC_RdC,
		TX_PROTOCOL => TX_L3_PROTOCOL,
		TXDC_ARP => ARP_TXDU,
		TXDV_ARP => ARP_TXEN,
		DST_MAC_ADDR_ARP => ARP_DST_MAC_ADDR,
		RdC_ARP => ARP_RdU,
		TXDC_IP => X"00",
		TXDV_IP => '0',
		DST_MAC_ADDR_IP => MAC_ADDR,
		RdC_IP => open
	);

	Dispatcher_L23_inst: Dispatcher_L23 PORT MAP(
		CLK => CLK,
		nRST => nRST,
		RXDU => MAC_RXDC,
		WrU => MAC_WrC,
		RXER => MAC_RXER,
		RXEOP => MAC_RXEOP,
		RX_PROTOCOL => RX_L3_PROTOCOL,
		RXDC_ARP => ARP_RXDU,
		WrC_ARP => ARP_WrU,
		RXER_ARP => ARP_RXER,
		RXEOP_ARP => ARP_RXEOP,
		RXDC_IP => open,
		WrC_IP => open,
		RXER_IP => open,
		RXEOP_IP => open
	);

	ARP_RequestIP <= (X"C0",X"A8",X"01",X"03");
	ARP_RequestValid <= UART_DOUTV;
	UART_RD <= MAC_RdC and ARP_TXIDLE;

-- DEBUG: forward data to PHY to UART
--	UART_DIN <= MAC_TXDU;
--	UART_WR <= MAC_RdU;
	UART_DIN <= MAC_RXDC;
	UART_WR <= MAC_WrC;
  --UART_DIN <= MAC_RXDU;
  --UART_WR <= MAC_WrU;
--  UART_DIN <= ARP_RXDU;
--  UART_WR <= ARP_WrU;

	--UART_DIN(7 downto 4) <= X"0";
	--UART_DIN(3 downto 0) <= PHY_RXD;
	--UART_WR <= PHY_RXDV and MAC_RXCLK_f;

	EdgeDetect_inst : EdgeDetect
	port map(
					CLK => CLK,
					sin => MAC_TXEN,
					srising => MAC_TXEN_r,
					sfalling => MAC_TXEN_f
	);

	process (CLK, BTN(3))
	begin
		if (BTN(3) = '1') then
			RXEOP_INDICATE <= '0';
			RXER_INDICATE <= '0';
			PHY_RXER_INDICATE <= '0';
		elsif (rising_edge(CLK)) then
			if (MAC_RXEOP = '1') then
				RXEOP_INDICATE <= not RXEOP_INDICATE;
			end if;
			if (MAC_RXER = '1') then
				RXER_INDICATE <= '1';
			end if;
			if (PHY_RXER = '1') then
				PHY_RXER_INDICATE <= '1';
			end if;
		end if;
	end process;

end Behavioral;

