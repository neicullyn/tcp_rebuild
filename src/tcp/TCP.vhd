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

      -- Buttons
      tcp_passive_open : in std_logic;
      tcp_active_open : in std_logic;
      tcp_active_close : in std_logic;

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

  component tcp_trs_task_scheduler is
    port(
      -- For protocol core
      core_dst_addr : in IP_ADDR_TYPE;
      core_dst_port : in std_logic_vector(15 downto 0);
      core_ack_num : in std_logic_vector(31 downto 0);
      core_ack : in std_logic;
      core_rst : in std_logic;
      core_syn : in std_logic;
      core_fin : in std_logic;

      -- Push the core packet info into the scheduler
      -- Note that core_push has higher priority than app_push
      core_push : in std_logic;
      core_pushing : out std_logic;

      -- Packet generate by the protocol doesn't have payload
      -- en_data : in std_logic;
      -- data_addr : in std_logic_vector(22 downto 0);
      -- data_len : in std_logic_vector(10 downto 0);

      -- For upper layer (application)
      app_dst_addr : in IP_ADDR_TYPE;
      app_dst_port : in std_logic_vector(15 downto 0);
      app_ack_num : in std_logic_vector(31 downto 0);

      -- Application layer doesn't set flags (for our simplified implementation)
      -- ack : in std_logic;
      -- rst : in std_logic;
      -- syn : in std_logic;
      -- fin : in std_logic;

      app_en_data : in std_logic;
      app_data_addr : in std_logic_vector(22 downto 0);
      app_data_len : in std_logic_vector(10 downto 0);

      -- Push the app packet info into the scheduler
      app_push : in std_logic;
      app_pushing : out std_logic;

      -- Output
      dst_addr : out IP_ADDR_TYPE;
      dst_port : out std_logic_vector(15 downto 0);
      ack_num : out std_logic_vector(31 downto 0);

      ack_bit : out std_logic;
      rst_bit : out std_logic;
      syn_bit : out std_logic;
      fin_bit : out std_logic;

      en_data : out std_logic;
      data_addr : out std_logic_vector(22 downto 0);
      data_len : out std_logic_vector(10 downto 0);

      -- Control signals for output
      valid : out std_logic;
      update : in std_logic; -- indicates that the output has been used
                             -- and needs updating
      empty : out std_logic; -- indicates the queue is empty

      -- Asynchronous reset and CLK
      nRST : in std_logic;
      CLK : in std_logic
    );
  end component;

 	type RX_states is (Reset, Header, Data, Handle, Err);
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

  type TX_states is (Reset, CalcChecksum, Header, Data, Done);
  signal TX_state : TX_states;
  signal TX_counter : unsigned(15 downto 0);
  signal TX_counter_inc : unsigned(15 downto 0);

  -- Input for TX
  signal TX_start : std_logic;
  signal TX_SRC_IP : IP_ADDR_TYPE;
  signal TX_DST_IP : IP_ADDR_TYPE;
  signal TX_TCP_LENGTH : std_logic_vector(15 downto 0);

  signal TX_SRC_PORT : std_logic_vector(15 downto 0);
  signal TX_DST_PORT : std_logic_vector(15 downto 0);

  signal TX_SEQ_NUM_BITS : std_logic_vector(31 downto 0);
  signal TX_ACK_NUM_BITS : std_logic_vector(31 downto 0);

  signal TX_DATA_OFFSET : std_logic_vector(3 downto 0);

  signal TX_ACK_BIT : std_logic;
  signal TX_RST_BIT : std_logic;
  signal TX_SYN_BIT : std_logic;
  signal TX_FIN_BIT : std_logic;
  signal TX_CTRL_BITS : std_logic_vector(5 downto 0);

  signal TX_WINDOW : std_logic_vector(15 downto 0);
  signal TX_CHECKSUM : std_logic_vector(15 downto 0);
  signal TX_URGENT : std_logic_vector(15 downto 0);

  signal TX_DATA_CHECKSUM : std_logic_vector(15 downto 0);

  type TX_PSEUDO_HEADER_TYPE is array (0 to 11) of std_logic_vector(7 downto 0);
  signal TX_PSEUDO_HEADER : TX_PSEUDO_HEADER_TYPE;

  type TX_HEADER_TYPE is array (0 to 19) of std_logic_vector(7 downto 0);
  signal TX_HEADER : TX_HEADER_TYPE;

  -- TX_TCP_CHECKSUM_CALC
  signal TX_CHKSUM_FEED : std_logic_vector(15 downto 0);
  signal TX_CHKSUM_CALC : std_logic;
  signal TX_CHKSUM_RESET : std_logic;
  signal TX_CHKSUM_CLK : std_logic;
  signal TX_CHKSUM_START : std_logic;
  signal TX_CHKSUM_CHECKSUM : std_logic_vector(15 downto 0);

  type TX_CalcChecksum_states is (Reset, DataChecksum, PseudoHeader, Header, Done);
  signal TX_CalcChecksum_state: TX_CalcChecksum_states;
  signal TX_CalcChecksum_counter: unsigned(3 downto 0);
  signal TX_CalcChecksum_p1: unsigned(4 downto 0);
  signal TX_CalcChecksum_p2: unsigned(4 downto 0);

  -- scheduler
  signal SCH_CORE_DST_ADDR : IP_ADDR_TYPE;
  signal SCH_CORE_DST_PORT : std_logic_vector(15 downto 0);
  signal SCH_CORE_ACK_NUM : std_logic_vector(31 downto 0);
  signal SCH_CORE_ACK : std_logic;
  signal SCH_CORE_RST : std_logic;
  signal SCH_CORE_SYN : std_logic;
  signal SCH_CORE_FIN : std_logic;

  signal SCH_CORE_PUSH : std_logic;
  signal SCH_CORE_PUSHING : std_logic;

  signal SCH_APP_DST_ADDR : IP_ADDR_TYPE;
  signal SCH_APP_DST_PORT : std_logic_vector(15 downto 0);
  signal SCH_APP_ACK_NUM : std_logic_vector(31 downto 0);

  signal SCH_APP_EN_DATA : std_logic;
  signal SCH_APP_DATA_ADDR : std_logic_vector(22 downto 0);
  signal SCH_APP_DATA_LEN : std_logic_vector(10 downto 0);

  signal SCH_APP_PUSH : std_logic;
  signal SCH_APP_PUSHING : std_logic;

  signal SCH_DST_ADDR : IP_ADDR_TYPE;
  signal SCH_DST_PORT : std_logic_vector(15 downto 0);
  signal SCH_ACK_NUM : std_logic_vector(31 downto 0);
  signal SCH_ACK_BIT : std_logic;
  signal SCH_RST_BIT : std_logic;
  signal SCH_SYN_BIT : std_logic;
  signal SCH_FIN_BIT : std_logic;
  signal SCH_EN_DATA : std_logic;
  signal SCH_DATA_ADDR : std_logic_vector(22 downto 0);
  signal SCH_DATA_LEN : std_logic_vector(10 downto 0);

  signal SCH_VALID : std_logic;
  signal SCH_UPDATE : std_logic;

  signal SCH_EMPTY : std_logic;


begin
  RXDU_BUF_proc : process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (WrU = '1') then
        RXDU_BUF <= RXDU;
      end if;
    end if;
  end process;

  RX_counter_inc <= RX_counter + 1;
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
          if (RX_HANDLE_state = Err) then
            RX_state <= Err;
          elsif (RX_HANDLE_state = Done) then
  				  RX_state <= Reset;
          end if;
  			when Err =>
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
  RX_TCP_CHECKSUM_control_proc : process (WrU, RX_state, RX_HANDLE_state, RX_CalcChecksum_state, RXDU_BUF, RXDU)
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
              if (RX_counter(0) = '1') then
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
    elsif (rising_edge(CLK)) then
      if (RX_HANDLE_state = CalcChecksum) then
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
    end if;
  end process;

  RX_HANDLE_ERR_CHKSUM <= '1' when (RX_CalcChecksum_state = Done and RX_CHKSUM_VALID ='0') else '0';

  TX_counter_inc <= TX_counter + 1;

  -- TX_PSEUDO_HEADER
  TX_PSEUDO_HEADER(0) <= TX_SRC_IP(0);
  TX_PSEUDO_HEADER(1) <= TX_SRC_IP(1);
  TX_PSEUDO_HEADER(2) <= TX_SRC_IP(2);
  TX_PSEUDO_HEADER(3) <= TX_SRC_IP(3);
  TX_PSEUDO_HEADER(4) <= TX_DST_IP(0);
  TX_PSEUDO_HEADER(5) <= TX_DST_IP(1);
  TX_PSEUDO_HEADER(6) <= TX_DST_IP(2);
  TX_PSEUDO_HEADER(7) <= TX_DST_IP(3);
  TX_PSEUDO_HEADER(8) <= X"00";
  TX_PSEUDO_HEADER(9) <= X"06"; -- TCP protocol
  TX_PSEUDO_HEADER(10) <= TX_TCP_LENGTH(15 downto 8);
  TX_PSEUDO_HEADER(11) <= TX_TCP_LENGTH(7 downto 0);

  -- TX_HEADER
  TX_HEADER(0) <= TX_SRC_PORT(15 downto 8);
  TX_HEADER(1) <= TX_SRC_PORT(7 downto 0);

  TX_HEADER(2) <= TX_DST_PORT(15 downto 8);
  TX_HEADER(3) <= TX_DST_PORT(7 downto 0);

  TX_HEADER(4) <= TX_SEQ_NUM_BITS(31 downto 24);
  TX_HEADER(5) <= TX_SEQ_NUM_BITS(23 downto 16);
  TX_HEADER(6) <= TX_SEQ_NUM_BITS(15 downto 8);
  TX_HEADER(7) <= TX_SEQ_NUM_BITS(7 downto 0);

  TX_HEADER(8) <= TX_ACK_NUM_BITS(31 downto 24);
  TX_HEADER(9) <= TX_ACK_NUM_BITS(23 downto 16);
  TX_HEADER(10) <= TX_ACK_NUM_BITS(15 downto 8);
  TX_HEADER(11) <= TX_ACK_NUM_BITS(7 downto 0);

  TX_HEADER(12) <= TX_DATA_OFFSET & X"0";
  TX_HEADER(13) <= "00" & TX_CTRL_BITS;
  TX_CTRL_BITS(5) <= '0'; -- URG
  TX_CTRL_BITS(4) <= TX_ACK_BIT;
  TX_CTRL_BITS(3) <= '0'; -- PSH
  TX_CTRL_BITS(2) <= TX_RST_BIT;
  TX_CTRL_BITS(1) <= TX_SYN_BIT;
  TX_CTRL_BITS(0) <= TX_FIN_BIT;

  TX_HEADER(14) <= TX_WINDOW(15 downto 8);
  TX_HEADER(15) <= TX_WINDOW(7 downto 0);

  TX_HEADER(16) <= TX_CHECKSUM(15 downto 8);
  TX_HEADER(17) <= TX_CHECKSUM(7 downto 0);

  TX_HEADER(18) <= TX_URGENT(15 downto 8);
  TX_HEADER(19) <= TX_URGENT(7 downto 0);

  -- constant fields
  TX_SRC_IP <= IP_ADDR;
  TX_SRC_PORT <= LISTEN_PORT;
  TX_DATA_OFFSET <= X"5";
  TX_WINDOW <= X"00FF";
  TX_URGENT <= X"0000";

  TX_SM: process (nRST, CLK)
  begin
    if (nRST = '0') then
      TX_state <= Reset;
    elsif (rising_edge(CLK)) then
      case TX_state is
        when Reset =>
          if (TX_start = '1') then
            TX_state <= CalcChecksum;
          end if;
        when CalcChecksum =>
          if (TX_CalcChecksum_state = Done) then
            TX_state <= Header;
            TX_counter <= X"0000";
          end if;
        when Header =>
        when Data =>
        when Done =>
          TX_state <= Reset;
      end case;
    end if;
  end process;

  TX_TCP_CHECKSUM_CALC : tcp_checksum_calc
  port map(
      feed => TX_CHKSUM_FEED,
      calc => TX_CHKSUM_CALC,
      reset => TX_CHKSUM_RESET,
      CLK => CLK,
      valid => open,
      checksum => TX_CHKSUM_CHECKSUM
  );

  TX_CalcChecksum_state_SM : process (CLK, TX_state)
  begin
    if (TX_state = Reset) then
      TX_CalcChecksum_state <= Reset;
    elsif (rising_edge(CLK)) then
      if (TX_state = CalcChecksum) then
        case TX_CalcChecksum_state is
          when Reset =>
            TX_CalcChecksum_state <= DataChecksum;
          when DataChecksum =>
            TX_CalcChecksum_counter <= "0000";
            TX_CalcChecksum_state <= PseudoHeader;
          when PseudoHeader =>
            if (TX_CalcChecksum_counter = 5) then
              TX_CalcChecksum_counter <= "0000";
              TX_CalcChecksum_state <= Header;
            else
              TX_CalcChecksum_counter <= TX_CalcChecksum_counter + 1;
            end if;
          when Header =>
            if (TX_CalcChecksum_counter = 9) then
              TX_CalcChecksum_counter <= "0000";
              TX_CalcChecksum_state <= Done;
            else
              TX_CalcChecksum_counter <= TX_CalcChecksum_counter + 1;
            end if;
          when Done =>
        end case;
      end if;
    end if;
  end process;
  TX_CalcChecksum_p1 <= TX_CalcChecksum_counter & '0';
  TX_CalcChecksum_p2 <= TX_CalcChecksum_counter & '1';

  process (TX_CalcChecksum_state, TX_DATA_CHECKSUM, TX_PSEUDO_HEADER, TX_HEADER, TX_CalcChecksum_p1, TX_CalcChecksum_p2)
  begin
    case TX_CalcChecksum_state is
      when Reset =>
        TX_CHKSUM_FEED <= X"0000";
        TX_CHKSUM_CALC <= '0';
        TX_CHKSUM_RESET <= '1';
      when DataChecksum =>
        TX_CHKSUM_FEED <= TX_DATA_CHECKSUM;
        TX_CHKSUM_CALC <= '1';
        TX_CHKSUM_RESET <= '0';
      when PseudoHeader =>
        TX_CHKSUM_FEED(15 downto 8) <= TX_PSEUDO_HEADER(to_integer(TX_CalcChecksum_p1));
        TX_CHKSUM_FEED(7 downto 0) <= TX_PSEUDO_HEADER(to_integer(TX_CalcChecksum_p2));
        TX_CHKSUM_CALC <= '1';
        TX_CHKSUM_RESET <= '0';
      when Header =>
        TX_CHKSUM_FEED(15 downto 8) <= TX_HEADER(to_integer(TX_CalcChecksum_p1));
        TX_CHKSUM_FEED(7 downto 0) <= TX_HEADER(to_integer(TX_CalcChecksum_p2));
        TX_CHKSUM_CALC <= '1';
        TX_CHKSUM_RESET <= '0';
      when Done =>
        TX_CHKSUM_FEED <= X"0000";
        TX_CHKSUM_CALC <= '0';
        TX_CHKSUM_RESET <= '0';
    end case;
  end process;
  TX_CHECKSUM <= TX_CHKSUM_CHECKSUM when TX_CalcChecksum_state = Done else X"0000";


  SCH_inst : tcp_trs_task_scheduler
  port map (
    core_dst_addr => SCH_CORE_DST_ADDR,
    core_dst_port => SCH_CORE_DST_PORT,
    core_ack_num => SCH_CORE_ACK_NUM,
    core_ack => SCH_CORE_ACK,
    core_rst => SCH_CORE_RST,
    core_syn => SCH_CORE_SYN,
    core_fin => SCH_CORE_FIN,
    core_push => SCH_CORE_PUSH,
    core_pushing => SCH_CORE_PUSHING,
    app_dst_addr => SCH_APP_DST_ADDR,
    app_dst_port => SCH_APP_DST_PORT,
    app_ack_num => SCH_APP_ACK_NUM,
    app_en_data => SCH_APP_EN_DATA,
    app_data_addr => SCH_APP_DATA_ADDR,
    app_data_len => SCH_APP_DATA_LEN,
    app_push => SCH_APP_PUSH,
    app_pushing => SCH_APP_PUSHING,
    dst_addr => SCH_DST_ADDR,
    dst_port => SCH_DST_PORT,
    ack_num => SCH_ACK_NUM,
    ack_bit => SCH_ACK_BIT,
    rst_bit => SCH_RST_BIT,
    syn_bit => SCH_SYN_BIT,
    fin_bit => SCH_FIN_BIT,
    en_data => SCH_EN_DATA,
    data_addr => SCH_DATA_ADDR,
    data_len => SCH_DATA_LEN,
    valid => SCH_VALID,
    update => SCH_UPDATE,
    empty => SCH_EMPTY,
    nRST => nRST,
    CLK => CLK
  );

  -- For testing
  TX_start <= '1';
  TX_DST_IP <= VAIO_IP_ADDR;
  TX_TCP_LENGTH <= X"03FC";
  TX_DST_PORT <= X"0080";
  TX_SEQ_NUM_BITS <= X"0BCDABCD";
  TX_ACK_NUM_BITS <= X"0CADCCAD";
  TX_ACK_BIT <= '1';
  TX_RST_BIT <= '1';
  TX_SYN_BIT <= '1';
  TX_FIN_BIT <= '1';
  TX_DATA_CHECKSUM <= X"F5F5";
end Behavioral;
