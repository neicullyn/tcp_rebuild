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
	signal result : unsigned(15 downto 0);
	signal sum : unsigned(16 downto 0);
	signal shadow : unsigned(15 downto 0);
begin
	shadow(0) <= sum(16);
	shadow(15 downto 1) <= "000000000000000";
	sum <= '0' & result + unsigned('0' & feed);
	process (CLK, reset)
	begin
		if (rising_edge(CLK)) then
			if (reset = '1') then
				result <= X"0000";
			else
				if (calc = '1') then
					if (sum = '1' & X"FFFF") then
						result <= X"0001";
					else
						result <= sum(15 downto 0) + shadow;
					end if;
				end if;
			end if;
		end if;
	end process;
	valid <= '1' when result = X"FFFF" else '0';
	checksum <= not std_logic_vector(result(15 downto 0));
end Behavioral;
