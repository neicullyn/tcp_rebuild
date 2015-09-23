library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package TCP_CONSTANTS is
  type MAC_ADDR_TYPE is array(0 to 5) of std_logic_vector(7 downto 0);
  constant MAC_ADDR: MAC_ADDR_TYPE := (X"48",X"48",X"48",X"48",X"48",X"48");
  constant DEST_MAC_ADDR: MAC_ADDR_TYPE := (X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
end TCP_CONSTANTS;