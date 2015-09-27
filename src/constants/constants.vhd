library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package TCP_CONSTANTS is
  type MAC_ADDR_TYPE is array(0 to 5) of std_logic_vector(7 downto 0);
  constant MAC_ADDR: MAC_ADDR_TYPE := (X"48",X"48",X"48",X"48",X"48",X"48");
  --constant DEST_MAC_ADDR: MAC_ADDR_TYPE := (X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");

  type IP_ADDR_TYPE is array(0 to 3) of std_logic_vector(7 downto 0);
  constant IP_ADDR: IP_ADDR_TYPE := (X"C0",X"A8",X"01",X"07"); -- 192.168.1.7

  type L3_PROTOCOL is (IP, ARP);
  type ETHERTYPE_CODE_TYPE is array(0 to 1) of std_logic_vector(7 downto 0);
  constant IP_ETHERTYPE_CODE: ETHERTYPE_CODE_TYPE := (X"08", X"00");
  constant ARP_ETHERTYPE_CODE: ETHERTYPE_CODE_TYPE := (X"08", X"06");

end TCP_CONSTANTS;