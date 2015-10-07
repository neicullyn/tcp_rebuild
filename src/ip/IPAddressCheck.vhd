library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.ALL;

entity IPAddressCheck is
  port (
    CLK : in std_logic;
    EN : in std_logic;
    DIN : in std_logic_vector(7 downto 0);
    AddrValid : out std_logic
  );
end IPAddressCheck;

architecture Behavioral of IPAddressCheck is
  signal addr_buffer : IP_ADDR_TYPE;
begin
  process (CLK)
  begin
    if (rising_edge(CLK)) then
		if (EN = '1') then
			for i in 0 to 2 loop
			  addr_buffer(i) <= addr_buffer(i + 1);
			end loop;
			addr_buffer(3) <= DIN;
		end if;
    end if;
  end process;
  process (addr_buffer)
  begin
    if (addr_buffer = IP_ADDR) then
      AddrValid <= '1';
    elsif (addr_buffer = (X"FF", X"FF", X"FF", X"FF")) then
      AddrValid <= '1';
    else
      AddrValid <= '0';
    end if;
  end process;
end Behavioral;