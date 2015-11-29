library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TCP_CONSTANTS.all;

entity DataGenerator is
  Port (
    CLK : in std_logic;
    nRST : in std_logic;

    data_addr : in std_logic_vector(22 downto 0);
    data_len : in std_logic_vector(11 downto 0);

    prepare_data : in std_logic;

    data_checksum : out std_logic_vector(15 downto 0);

    data_ready : out std_logic;
    data_valid : out std_logic;
    rd : in std_logic;
    rewind : in std_logic;
    data_over : out std_logic
  );
end DataGenerator;

architecture Behavioral of DataGenerator is
  component tcp_checksum_calc is
    port (
      feed : in std_logic_vector(15 downto 0);
      calc : in std_logic;
      reset : in std_logic;
      CLK : in std_logic;
      valid : out std_logic;
      checksum : out std_logic_vector(15 downto 0)
    );
  end component;

  signal data_addr_reg : std_logic_vector(22 downto 0);
  signal data_len_reg : std_logic_vector(11 downto 0);

  -- Pseudo random data
  signal data_reg : std_logic_vector(7 downto 0);
  signal data_reg_d : std_logic_vector(7 downto 0);
  signal data_reg_new : std_logic_vector(7 downto 0);
  signal counter : unsigned(11 downto 0);
  signal counter_inc : unsigned(11 downto 0);

  type states is (rst, lock, calc_checksum, calc_checksum_padding, data);
  signal state : states;

  signal chksum_feed : std_logic_vector(15 downto 0);
  signal chksum_calc : std_logic;
  signal chksum_reset : std_logic;

begin
  counter_inc <= counter + 1;
  data_reg_new <= (data_reg(0) & data_reg(7 downto 1)) xor std_logic_vector(counter_inc(7 downto 0));

  state_machine: process(CLK, nRST)
  begin
    if (nRST = '0') then
      state <= rst;
    elsif (rising_edge(CLK)) then
      case state is
        when rst =>
          if (prepare_data = '1') then
            state <= lock;
            data_addr_reg <= data_addr;
            data_len_reg <= data_len;
          end if;

        when lock =>
          data_reg <= data_addr_reg(7 downto 0) xor data_addr_reg(15 downto 8);
          data_reg_d <= data_reg;
          counter <= (others => '0');
          state <= calc_checksum;

        when calc_checksum =>
          if (counter_inc = unsigned(data_len_reg)) then
            data_reg <= data_addr_reg(7 downto 0) xor data_addr_reg(15 downto 8);
            data_reg_d <= data_reg;
            counter <= (others => '0');
            state <= calc_checksum_padding;
          else
            data_reg <= data_reg_new;
            data_reg_d <= data_reg;
            counter <= counter_inc;
          end if;

        when calc_checksum_padding =>
          state <= data;

        when data =>
          if (counter = unsigned(data_len_reg)) then
            if (rewind = '1') then
              data_reg <= data_addr_reg(7 downto 0) xor data_addr_reg(15 downto 8);
              data_reg_d <= data_reg;
              counter <= (others => '0');
            end if;
            if (prepare_data = '1') then
              state <= lock;
              data_addr_reg <= data_addr;
              data_len_reg <= data_len;
            end if;
          elsif (rd = '1') then
            data_reg <= data_reg_new;
            data_reg_d <= data_reg;
            counter <= counter_inc;
          end if;
      end case;
    end if;
  end process;

  data_ready <= '1' when state = data else '0';
  data_valid <= '1' when state = data and counter /= unsigned(data_len_reg) else '0';
  data_over <= '1' when state = data and counter = unsigned(data_len_reg) else '0';

  checksum_inst: tcp_checksum_calc
  port map(
      feed => chksum_feed,
      calc => chksum_calc,
      reset => chksum_reset,
      CLK => CLK,
      valid => open,
      checksum => data_checksum
  );

  chksum_feed <= data_reg_d & X"00" when state = calc_checksum_padding else data_reg_d & data_reg;
  chksum_calc <= '1' when state = calc_checksum and counter(0) = '1' else
                 '1' when state = calc_checksum_padding and data_len_reg(0) = '1' else
                 '0';
  chksum_reset <= '1' when state = lock else '0';
end Behavioral;
