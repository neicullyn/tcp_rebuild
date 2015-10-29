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
      TXIDLE_in : in std_logic;
      RdU : in std_logic;

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
  -- Receiver
  --type packet_rcv_state_type is (S_SRC_PORT, S_DST_PORT, S_SEQ_NUM, S_ACK_NUM, S_DATA_OFFSET, S_FLAGS,
  --                  S_WINDOW_SIZE, S_CHECKSUM, S_URGENT_POINTER, S_OPTIONS, S_DATA, S_HANDLE, S_DUMP);
	type RX_states is (Reset, Header, Data, EOP, ERR);
	signal RX_state : RX_states;
	signal RX_counter : integer range 0 to 65535;
	signal RX_counter_inc : integer range 0 to 65535;

	type RX_HEADER_TYPE is array (0 to 59) of std_logic_vector(7 downto 0);
	signal RX_HEADER : RX_HEADER_TYPE;

	signal RX_DATA_OFFSET : std_logic_vector(3 downto 0);
	signal RX_DATA_OFFSET_BYTES : integer range 0 to 60;
begin
  RX_counter_inc <= (RX_counter + 1) mod 65535;
  RX_SM : process (nRST, CLK)
  begin
  	if (nRST = '0') then
  		RX_state <= Reset;
  	elsif (rising_edge(CLK)) then
  		case RX_state is
  			when Reset =>
  				RX_state <= Header;
  				RX_counter <= 0;

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
  						RX_state <= EOP;
  					end if;
  				end if;

  			when EOP =>
  				RX_state <= Reset;

  			when ERR =>
  				RX_state <= Reset;
  		end case;
  	end if;
  end process;

  RX_HEADER_proc : process (nRST, CLK)
  begin
  	if (RX_state = Header) then
  		if (WrU = '1') then
  			RX_HEADER(RX_counter) <= RXDU;
  		end if;
  	end if;
  end process;
end Behavioral;

