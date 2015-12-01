library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity tcp_fsm is
  port(
    CLK : in std_logic;
    nRST : in std_logic;

    tcp_passive_open : in std_logic;
    tcp_active_open : in std_logic;
    tcp_active_close : in std_logic;

    tcp_state_handle : in std_logic;

    RX_SRC_IP_ADDR : in IP_ADDR_TYPE;
    RX_SRC_PORT : in std_logic_vector(15 downto 0);
    RX_ACK_NUM : in unsigned(31 downto 0);

    RX_ACK_BIT : in std_logic;
    RX_SYN_BIT : in std_logic;
    RX_FIN_BIT : in std_logic;
    RX_RST_BIT : in std_logic;

    established : out std_logic;
    action  : out CORE_ACTION;
    action_valid : out std_logic;
    TX_DST_IP_ADDR : out IP_ADDR_TYPE;
    TX_DST_PORT : out std_logic_vector(15 downto 0)
  );
end tcp_fsm;

architecture Behavioral of tcp_fsm is
  type tcp_state_type is (S_CLOSED, S_LISTEN, S_SYN_RECEIVED, S_SYN_SENT, S_ESTABLISHED,
          S_FIN_WAIT1, S_FIN_WAIT2, S_CLOSING, S_TIME_WAIT, S_CLOSE_WAIT, S_LAST_ACK);
  signal tcp_state : tcp_state_type;

  signal tcp_peer_IP : IP_ADDR_TYPE;
  signal tcp_peer_PORT : std_logic_vector(15 downto 0);
  signal tcp_peer_valid : std_logic;

  signal tcp_FIN_SEQ : unsigned(31 downto 0);
  signal tcp_ACK_to_FIN : std_logic;
begin
  tcp_peer_valid <= '1' when tcp_peer_IP = RX_SRC_IP_ADDR
                         and tcp_peer_PORT = RX_SRC_PORT
                         and tcp_state /= S_CLOSED
                         and tcp_state /= S_LISTEN
                        else '0';

  tcp_ACK_to_FIN <= '1' when RX_ACK_BIT = '1'
                         and RX_ACK_NUM = tcp_FIN_SEQ + 1
                        else '0';

  TX_DST_IP_ADDR <= tcp_peer_IP;
  TX_DST_PORT <= tcp_peer_PORT;

  established <= '1' when tcp_state = S_ESTABLISHED else '0';

  TCP_SM : process (nRST, CLK)
  begin
    if (nRST = '0') then
      tcp_state <= S_CLOSED;
      tcp_peer_IP <= (X"00",X"00",X"00",X"00");
      tcp_peer_PORT <= X"0000";
      action <= NONE;
      action_valid <= '0';
    elsif (rising_edge(CLK)) then
      action_valid <= '0';
      case tcp_state is
        when S_CLOSED =>
          if (tcp_active_open = '1') then
            tcp_state <= S_SYN_SENT;
            tcp_peer_IP <= VAIO_IP_ADDR;
            tcp_peer_PORT <= VAIO_LISTEN_PORT;

            action <= MAKE_SYN;
            action_valid <= '1';
          elsif (tcp_passive_open = '1') then
            tcp_state <= S_LISTEN;

          end if;

        when S_SYN_SENT =>
          if (tcp_state_handle = '1' and tcp_peer_valid = '1') then
            if (RX_SYN_BIT = '1' and RX_ACK_BIT = '0') then
              tcp_state <= S_SYN_RECEIVED;

              action <= MAKE_ACK;
              action_valid <= '1';
            elsif (RX_SYN_BIT = '1' and RX_ACK_BIT = '1') then
              tcp_state <= S_ESTABLISHED;

              action <= MAKE_ACK;
              action_valid <= '1';
            end if;
          end if;

        when S_LISTEN =>
          if (tcp_state_handle = '1') then
            if (RX_SYN_BIT = '1') then
              tcp_peer_IP <= RX_SRC_IP_ADDR;
              tcp_peer_PORT <= RX_SRC_PORT;
              tcp_state <= S_SYN_RECEIVED;

              action <= MAKE_SYN_ACK;
              action_valid <= '1';
            end if;
          end if;

        when S_SYN_RECEIVED =>
          if (tcp_state_handle = '1' and tcp_peer_valid = '1') then
            if (RX_ACK_BIT = '1') then
              tcp_state <= S_ESTABLISHED;
            end if;
          end if;

        when S_ESTABLISHED =>
          if (tcp_active_close = '1') then
            tcp_state <= S_FIN_WAIT1;

            action <= MAKE_FIN;
            action_valid <= '1';
          end if;

          if (tcp_state_handle = '1' and tcp_peer_valid = '1' and RX_FIN_BIT = '1') then
            tcp_state <= S_CLOSE_WAIT;

            action <= MAKE_ACK;
            action_valid <= '1';
          elsif (tcp_state_handle = '1') then
            -- Normal operation

            action <= MAKE_ACK;
            action_valid <= '1';
          end if;

        when S_CLOSE_WAIT =>
          tcp_state <= S_LAST_ACK;

          action <= MAKE_FIN;
          action_valid <= '1';

        when S_LAST_ACK =>
          if (tcp_state_handle = '1' and tcp_ACK_to_FIN = '1') then
            tcp_state <= S_CLOSED;
          end if;

        when S_FIN_WAIT1 =>
          if (tcp_state_handle = '1' and tcp_ACK_to_FIN = '1') then
            tcp_state <= S_FIN_WAIT2;

            action <= MAKE_ACK;
            action_valid <= '1';
          elsif (tcp_state_handle = '1' and RX_FIN_BIT = '1') then
            -- Simutaneous Close
            tcp_state <= S_CLOSING;
          end if;

        when S_FIN_WAIT2 =>
          if (tcp_state_handle = '1' and RX_FIN_BIT = '1') then
            tcp_state <= S_TIME_WAIT;

            action <= MAKE_ACK;
            action_valid <= '1';
          end if;

        when S_CLOSING =>
          if (tcp_state_handle = '1' and tcp_ACK_to_FIN = '1') then
            tcp_state <= S_TIME_WAIT;
          end if;

        when S_TIME_WAIT =>
          tcp_state <= S_CLOSED;
      end case;

      if (tcp_state_handle = '1' and tcp_peer_valid = '1') then
        if (RX_RST_BIT = '1') then
          tcp_state <= S_CLOSED;
        end if;
      end if;
    end if;
  end process;
end Behavioral;