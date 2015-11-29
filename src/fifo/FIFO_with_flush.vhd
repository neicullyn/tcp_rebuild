-- This is an FIFO implementation
-- If the FIFO is empty, pop makes no effect
-- If the FIFO is full, push makes no effect
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity FIFO_with_flush is
  port(
    -- reset signal, active low
    nRST : in std_logic;
    -- clock
    CLK : in std_logic;
    -- data to be pushed into the FIFO
    DIN : in std_logic_vector (7 downto 0);
    -- data to be popped from the FIFO
    DOUT : out std_logic_vector (7 downto 0);
    -- indicates that data_in should be pushed into the FIFO
    PUSH : in std_logic;
    -- indicates that data_out should be popped from the FIFO
    POP : in std_logic;
    -- indicates that current data in fifo should be flushed into output
    FLUSH : in std_logic;
    -- indicates we should emptify the FIFO
    CLEAR : in std_logic;
    -- indicates that the FIFO is empty
    EMPTY : out std_logic;
    -- indicates that the FIFO is full
    FULL : out std_logic
  );
end FIFO_with_flush;

architecture Behavioral of FIFO_with_flush is
  COMPONENT FIFO
  PORT(
    nRST : IN std_logic;
    CLK : IN std_logic;
    DIN : IN std_logic_vector(7 downto 0);
    PUSH : IN std_logic;
    POP : IN std_logic;
    DOUT : OUT std_logic_vector(7 downto 0);
    EMPTY : OUT std_logic;
    FULL : OUT std_logic
    );
  END COMPONENT;

  signal nRST_internal : std_logic;

  signal flush_counter : unsigned(9 downto 0);
  signal queue_length : unsigned(9 downto 0);

  signal poppable : std_logic;
  signal POP_internal : std_logic;
  signal EMPTY_internal : std_logic;
begin

  FIFO_inst : FIFO
  port map(
    nRST => nRST_internal,
    CLK => CLK,
    DIN => DIN,
    PUSH => PUSH,
    POP => POP_internal,
    DOUT => DOUT,
    EMPTY => EMPTY_internal,
    FULL => FULL
  );

  poppable <= '1' when flush_counter /= "0000000000" else '0';
  POP_internal <= poppable and POP;
  EMPTY <= EMPTY_internal or (not poppable);

  nRST_internal <= '0' when nRST = '0' or CLEAR = '1' else '1';

  process(nRST_internal, CLK)
  begin
    if (nRST_internal = '0') then
      flush_counter <= (others => '0');
      queue_length <= (others => '0');
    elsif (rising_edge(CLK)) then
      if (flush = '1') then
      -- flushing
      -- flush_counter should be the same as the new queue_length
        if (PUSH = '1' and POP_internal = '0') then
          queue_length <= queue_length + 1;
          flush_counter <= queue_length + 1;
        end if;

        if (PUSH = '0' and POP_internal = '1') then
          queue_length <= queue_length - 1;
          flush_counter <= queue_length - 1;
        end if;

        if (PUSH = '1' and POP_internal = '1') then
          flush_counter <= queue_length;
        end if;

        if (PUSH = '0' and POP_internal = '0') then
          flush_counter <= queue_length;
        end if;
      else
        -- not flushing
        -- flush_counter should only decrease
        if (PUSH = '1' and POP_internal = '0') then
          queue_length <= queue_length + 1;
        end if;

        if (PUSH = '0' and POP_internal = '1') then
          queue_length <= queue_length - 1;
          flush_counter <= queue_length - 1;
        end if;

        if (PUSH = '1' and POP_internal = '1') then
          flush_counter <= flush_counter - 1;
        end if;
      end if;
    end if;
  end process;
end Behavioral;
