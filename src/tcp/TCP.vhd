----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    20:00:56 05/27/2015
-- Design Name:
-- Module Name:    TCP - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity TCP is
  port (
      CLK : in std_logic;
      nRST : in std_logic;

      -- TXD to the underlying module
      TXDU : out std_logic_vector(7 downto 0);
      TXEN : out std_logic;
      RdU : in std_logic;
      TX_DataLength: out std_logic_vector(15 downto 0);

      -- RXD from the underlying module
      RXDU : in std_logic_vector(7 downto 0);
      WrU : in std_logic;
      RXER : in std_logic;
      RXEOP : in std_logic;

      RX_SRC_IP_ADDR : in IP_ADDR_TYPE;
      TX_DST_IP_ADDR : out IP_ADDR_TYPE
  );
end TCP;

architecture Behavioral of TCP is
  component tcp_checksum_calc is
    port (
      feed : in std_logic_vector(15 downto 0);
      calc : in std_logic;
      reset : in std_logic;
      CLK : in std_logic;
      valid : out std_logic;
      checksum : out std_logic_vector(15 downto 0)
    );
  end component;

 	type RX_states is (Reset, Header, Data, Handle, ERR);
	signal RX_state : RX_states;
	signal RX_counter : unsigned(15 downto 0);
	signal RX_counter_inc : unsigned(15 downto 0);

	type RX_HEADER_TYPE is array (0 to 59) of std_logic_vector(7 downto 0);
	signal RX_HEADER : RX_HEADER_TYPE;

	signal RX_DATA_OFFSET : std_logic_vector(3 downto 0);
	signal RX_DATA_OFFSET_BYTES : integer range 0 to 60;

  signal RX_SRC_PORT: std_logic_vector(15 downto 0);
  signal RX_DST_PORT: std_logic_vector(15 downto 0);

  signal RX_SEQ_NUM_BITS : std_logic_vector(31 downto 0);
  signal RX_ACK_NUM_BITS : std_logic_vector(31 downto 0);
  signal RX_SEQ_NUM : unsigned(31 downto 0);
  signal RX_ACK_NUM : unsigned (31 downto 0);

  signal RX_CTRL_BITS : std_logic_vector(5 downto 0);
  signal RX_ACK_BIT : std_logic;
  signal RX_RST_BIT : std_logic;
  signal RX_SYN_BIT : std_logic;
  signal RX_FIN_BIT : std_logic;

  signal RX_WINDOW : std_logic_vector(15 downto 0);

  signal RX_CHECKSUM : std_logic_vector(15 downto 0);
  signal RX_URGENT : std_logic_vector(15 downto 0);

  signal RXDU_BUF : std_logic_vector(7 downto 0);

  -- Signals for RX_TCP_CHECKSUM_CALC
  signal RX_CHKSUM_FEED : std_logic_vector(15 downto 0);
  signal RX_CHKSUM_CALC : std_logic;
  signal RX_CHKSUM_RESET : std_logic;
  signal RX_CHKSUM_CLK : std_logic;
  signal RX_CHKSUM_START : std_logic;
  signal RX_CHKSUM_VALID : std_logic;

  signal RX_HANDLE_ERR : std_logic;
  signal RX_HANDLE_ERR_SET : std_logic;
  signal RX_HANDLE_ERR_CHKSUM : std_logic;

  type RX_HANDLE_states is (Reset, CalcChecksum, Execute, Done, Err);
  signal RX_HANDLE_state : RX_HANDLE_states;

  type RX_CalcChecksum_states is (Reset, HandleOddData, SrcAddr0, SrcAddr1, DstAddr0, DstAddr1, Protocol, TCPLength, Done);
  signal RX_CalcChecksum_state: RX_CalcChecksum_states;

begin
  RXDU_BUF_proc : process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (WrU = '1') then
        RXDU_BUF <= RXDU;
      end if;
    end if;
  end process;

  RX_counter_inc <= (RX_counter + 1) mod 65535;
  RX_SM : process (nRST, CLK)
  begin
  	if (nRST = '0') then
  		RX_state <= Reset;
  	elsif (rising_edge(CLK)) then
  		case RX_state is
  			when Reset =>
  				RX_state <= Header;
  				RX_counter <= X"0000";

  			when Header =>
  				if (WrU = '1') then
  					RX_counter <= RX_counter_inc;
  					if (RX_counter_inc = RX_DATA_OFFSET_BYTES) then
  						RX_state <= Data;
  					end if;
  				end if;

  			when Data =>
  				if (WrU = '1') then
  					RX_counter <= RX_counter_inc;
  				end if;

  				if (RXEOP = '1') then
  					if (RXER = '1') then
  						RX_state <= ERR;
  					else
  						RX_state <= Handle;
  					end if;
  				end if;

  			when Handle =>
  				RX_state <= Reset;

  			when ERR =>
  				RX_state <= Reset;
  		end case;
  	end if;
  end process;

  RX_HEADER_proc : process (nRST, CLK)
  begin
  	if (nRST = '0') then
  	elsif (rising_edge(CLK)) then
	  	if (RX_state = Header) then
	  		if (WrU = '1') then
	  			RX_HEADER(to_integer(RX_counter)) <= RXDU;
	  		end if;
	  	end if;
  	end if;
  end process;

  RX_DATA_OFFSET <= RX_HEADER(12)(7 downto 4);
  process (CLK, RX_state)
  begin
    if (RX_state = Reset) then
      RX_DATA_OFFSET_BYTES <= 20;
    elsif (rising_edge(CLK)) then
      if (RX_counter = 13) then
        RX_DATA_OFFSET_BYTES <= to_integer(unsigned(RX_DATA_OFFSET)) * 4;
      end if;
    end if;
  end process;

  RX_SRC_PORT <= RX_HEADER(0) & RX_HEADER(1);
  RX_DST_PORT <= RX_HEADER(2) & RX_HEADER(3);

  RX_SEQ_NUM_BITS <= RX_HEADER(4) & RX_HEADER(5) & RX_HEADER(6) & RX_HEADER(7);
  RX_ACK_NUM_BITS <= RX_HEADER(8) & RX_HEADER(9) & RX_HEADER(10) & RX_HEADER(11);
  RX_SEQ_NUM <= unsigned(RX_SEQ_NUM_BITS);
  RX_ACK_NUM <= unsigned(RX_ACK_NUM_BITS);

  RX_CTRL_BITS <= RX_HEADER(13)(5 downto 0);
  RX_ACK_BIT <= RX_CTRL_BITS(4);
  RX_RST_BIT <= RX_CTRL_BITS(2);
  RX_SYN_BIT <= RX_CTRL_BITS(1);
  RX_FIN_BIT <= RX_CTRL_BITS(0);

  RX_WINDOW <= RX_HEADER(14) & RX_HEADER(15);
  RX_CHECKSUM <= RX_HEADER(16) & RX_HEADER(17);

  RX_URGENT <= RX_HEADER(18) & RX_HEADER(19);

  RX_TCP_CHECKSUM_CALC : tcp_checksum_calc
  port map(
      feed => RX_CHKSUM_FEED,
      calc => RX_CHKSUM_CALC,
      reset => RX_CHKSUM_RESET,
      CLK => CLK,
      valid => RX_CHKSUM_VALID,
      checksum => OPEN
  );

  -- RX_Handle
  RX_HANDLE_SM: process (CLK, RX_state)
  begin
    if (RX_state = Reset) then
      RX_HANDLE_state <= Reset;
      RX_HANDLE_ERR <= '0';
    elsif (rising_edge(CLK)) then
      if (RX_HANDLE_ERR_SET = '1') then
        RX_HANDLE_ERR <= '1';
      end if;

      if (RX_HANDLE_ERR = '1') then
        RX_HANDLE_state <= Err;
      elsif (RX_state = Handle) then
        case RX_HANDLE_state is
          when Reset =>
            RX_HANDLE_state <= CalcChecksum;
          when CalcChecksum =>
            if (RX_CalcChecksum_state = Done) then
              RX_HANDLE_state <= Execute;
            end if;
          when Execute =>
            RX_HANDLE_state <= Done;
          when others =>
        end case;
      end if;
    end if;
  end process;

  -- RX_TCP_CHECKSUM
  RX_CHKSUM_RESET <= '1' when RX_state = Reset else '0';
  RX_TCP_CHECKSUM_control_proc : process (RX_state, RX_HANDLE_state, RX_CalcChecksum_state, RXDU_BUF, RXDU)
  begin
    RX_CHKSUM_FEED <= X"0000";
    RX_CHKSUM_CALC <= '0';
    case RX_state is
      when Header =>
        RX_CHKSUM_FEED <= RXDU_BUF & RXDU;
        if (WrU = '1' and RX_counter(0) = '1') then
          RX_CHKSUM_CALC <= '1';
        end if;
      when Data =>
        RX_CHKSUM_FEED <= RXDU_BUF & RXDU;
        if (WrU = '1' and RX_counter(0) = '1') then
          RX_CHKSUM_CALC <= '1';
        end if;
      when Handle =>
        if (RX_HANDLE_state = CalcChecksum) then
          case RX_CalcChecksum_state is
            when Reset =>
            when HandleOddData =>
              if (RX_counter(0) = '0') then
                RX_CHKSUM_FEED <= RXDU_BUF & X"00";
                RX_CHKSUM_CALC <= '1';
              end if;
            when SrcAddr0 =>
              RX_CHKSUM_FEED <= RX_SRC_IP_ADDR(0) & RX_SRC_IP_ADDR(1);
              RX_CHKSUM_CALC <= '1';
            when SrcAddr1 =>
              RX_CHKSUM_FEED <= RX_SRC_IP_ADDR(2) & RX_SRC_IP_ADDR(3);
              RX_CHKSUM_CALC <= '1';
            when DstAddr0 =>
              RX_CHKSUM_FEED <= IP_ADDR(0) & IP_ADDR(1); -- This will not accept broadcast, remains to be solved
              RX_CHKSUM_CALC <= '1';
            when DstAddr1 =>
              RX_CHKSUM_FEED <= IP_ADDR(2) & IP_ADDR(3); -- This will not accept broadcast, remains to be solved
              RX_CHKSUM_CALC <= '1';
            when Protocol =>
              RX_CHKSUM_FEED <= X"0006";
              RX_CHKSUM_CALC <= '1';
            when TCPLength =>
              RX_CHKSUM_FEED <= std_logic_vector(RX_counter);
              RX_CHKSUM_CALC <= '1';
            when Done =>
          end case;
        end if;
      when others =>
    end case;
  end process;

  RX_CalcChecksum_state_SM : process (CLK, RX_state)
  begin
    if (RX_state = Reset) then
      RX_CalcChecksum_state <= Reset;
    elsif (RX_HANDLE_state = CalcChecksum) then
      case RX_CalcChecksum_state is
        when Reset =>
          RX_CalcChecksum_state <= HandleOddData;
        when HandleOddData =>
          RX_CalcChecksum_state <= SrcAddr0;
        when SrcAddr0 =>
          RX_CalcChecksum_state <= SrcAddr1;
        when SrcAddr1 =>
          RX_CalcChecksum_state <= DstAddr0;
        when DstAddr0 =>
          RX_CalcChecksum_state <= DstAddr1;
        when DstAddr1 =>
          RX_CalcChecksum_state <= Protocol;
        when Protocol =>
          RX_CalcChecksum_state <= TCPLength;
        when TCPLength =>
          RX_CalcChecksum_state <= Done;
        when Done =>
      end case;
    end if;
  end process;

  RX_HANDLE_ERR_CHKSUM <= '1' when (RX_CalcChecksum_state = Done and RX_CHKSUM_VALID ='0') else '0';

end Behavioral;
