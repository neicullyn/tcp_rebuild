library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EdgeDetect is
  port (
      sin : in std_logic;
      srising : out std_logic;
      sfalling : out std_logic;
      CLK : in std_logic
    );
end EdgeDetect;

architecture Behavioral of EdgeDetect is
  signal sin_lastval : std_logic;
begin
  process (CLK)
  begin
    if (rising_edge(CLK)) then
      sin_lastval <= sin;
    end if;
  end process;

  srising <= '1' when (sin = '1' and sin_lastval = '0') else '0';
  sfalling <= '1' when (sin = '0' and sin_lastval = '1') else '0';
end Behavioral;
