library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity ClkGen is
  Port (
    CLK : in std_logic;
    CLK_1K : out std_logic
  );
end ClkGen;

architecture Behavioral of ClkGen is
  constant CLK_1K_DIV : integer := 100000;
  signal counter : integer range 0 to (CLK_1K_DIV - 1);
begin
  process (CLK)
  begin
    if (rising_edge(CLK)) then
      counter <= (counter + 1) mod CLK_1K_DIV;
    end if;
  end process;
  CLK_1K <= '1' when counter = (CLK_1K_DIV - 1) else '0';
end Behavioral;