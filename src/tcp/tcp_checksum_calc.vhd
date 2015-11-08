library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity tcp_checksum_calc is
	port (
		feed : in std_logic_vector(15 downto 0);
		calc : in std_logic;
		reset : in std_logic;
		CLK : in std_logic;
		valid : out std_logic;
		checksum : out std_logic_vector(15 downto 0)
	);
end tcp_checksum_calc;

architecture Behavioral of tcp_checksum_calc is
	signal result : unsigned(31 downto 0);
begin
	process (CLK, reset)
	begin
		if (rising_edge(CLK)) then
			if (reset = '1') then
				result <= X"00000000";
			else
				if (calc = '1') then
					result <= result + unsigned(feed);
				end if;
			end if;
		end if;
	end process;
	valid <= '1' when result = X"FFFF" else '0';
	checksum <= not std_logic_vector(result(15 downto 0) + result(31 downto 16));
end Behavioral;
