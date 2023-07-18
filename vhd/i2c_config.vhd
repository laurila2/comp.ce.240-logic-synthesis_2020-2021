-------------------------------------------------------------------------------
-- Title      : i2c config
-- Project    : 
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop5.tuni.fi>
-- Company    : 
-- Created    : 2021-02-11
-- Last update: 2021-02-12
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: i2c config
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-02-11  1.0      mikkone8        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_config is
  generic (
    ref_clk_freq_g : integer := 50000000;
    i2c_freq_g     : integer := 20000;
    n_params_g     : integer := 15;
    n_leds_g       : integer := 4
    );
  port (
    clk              : in    std_logic;
    rst_n            : in    std_logic;
    sdat_inout       : inout std_logic;
    sclk_out         : out   std_logic;
    param_status_out : out   std_logic_vector(n_leds_g-1 downto 0);
    finished_out     : out   std_logic
    );
end i2c_config;

architecture rtl of i2c_config is
  constant hold_time_c   : integer := 500000;  -- 2.5 us
  constant hold_cycles_c : integer := ref_clk_freq_g / hold_time_c;
  constant hold_start_c  : integer := hold_cycles_c;

  constant bit_period_c : integer := 100000;  -- 100 kHz i2c
  constant bit_cycles_c : integer := ref_clk_freq_g / bit_period_c;

  constant high_cycles_c : integer := bit_cycles_c / 2;
  constant low_cycles_c  : integer := bit_cycles_c / 2 - hold_cycles_c;

  type table_2d is array (0 to n_params_g-1, 0 to 1) of std_logic_vector(7 downto 0);
  constant parameter_table_c : table_2d := (
    ("00011101", "10000000"),
    ("00100111", "00000100"),
    ("00100010", "00001011"),
    ("00101000", "00000000"),
    ("00101001", "10000001"),
    ("01101001", "00001000"),
    ("01101010", "00000000"),
    ("01000111", "11100001"),
    ("01101011", "00001001"),
    ("01101100", "00001000"),
    ("01001011", "00001000"),
    ("01001100", "00001000"),
    ("01101110", "10001000"),
    ("01101111", "10001000"),
    ("01010001", "11110001"));
  -- Also includes write bit
  constant codec_address_c : std_logic_vector(7 downto 0) := "00110100";

  signal scl_r : std_logic;

  -- Send bits signal
  type send_state is (idle, wait_hold, wait_low, wait_high, ack_check);
  signal send_state_r : send_state;
  signal bit_count_r  : integer;
  signal counter_r    : integer;

  -- Send word signals
  type reg_send is (addr, reg, data, done);
  signal reg_send_r     : reg_send;
  signal words_sent_r   : unsigned(n_leds_g-1 downto 0);
  signal register_num_r : integer;

  -- Common
  signal nack_received_r      : std_logic;
  signal ack_received_r       : std_logic;
  signal data_to_send_r       : std_logic_vector(7 downto 0);
  signal start_transmission_r : std_logic;  -- 
  signal new_transmission_r   : std_logic;  -- Parameter changed, send start

  
begin

  send_bits : process(clk, rst_n)
  begin
    if rst_n = '0' then
      send_state_r <= idle;
      scl_r        <= '1';
      sdat_inout        <= '1';
      bit_count_r  <= 0;
      counter_r    <= 0;
    elsif rising_edge(clk) then
      
      counter_r <= counter_r + 1;

      case send_state_r is
        when idle =>
          scl_r <= '1';
          if counter_r = hold_start_c then
            
            --if start_transmission_r = '1' then
              counter_r       <= 0;
              sdat_inout           <= '0';
              ack_received_r  <= '0';
              nack_received_r <= '0';
              send_state_r    <= wait_high;
            --end if;
          end if;
          
        when wait_high =>
          if counter_r = high_cycles_c then
            counter_r    <= 0;
            send_state_r <= wait_hold;
            scl_r        <= '0';
          end if;
          
        when wait_hold =>
          ack_received_r <= '0'; -- Moves here after ack is generated, reset
          if counter_r = hold_cycles_c then
            counter_r <= 0;
            if bit_count_r = 7 then
              sdat_inout  <= 'Z';
            else
              sdat_inout  <= data_to_send_r(bit_count_r);
            end if;
            send_state_r <= wait_low;
          end if;

        when wait_low =>
          if counter_r = low_cycles_c then
            counter_r <= 0;
            scl_r     <= '1';
            if bit_count_r = 7 then
              send_state_r <= ack_check;
              bit_count_r <= 0;
            else
              send_state_r <= wait_high;
              bit_count_r <= bit_count_r + 1;
            end if;
          end if;

        when ack_check =>
          if counter_r = high_cycles_c then
            counter_r <= 0;
            if new_transmission_r = '1' or nack_received_r = '1' then
              send_state_r <= idle;
              scl_r        <= '1';
            else
              ack_received_r <= '1';
              send_state_r   <= wait_hold;
              scl_r          <= '0';
            end if;
          elsif sdat_inout = '1' then        -- ???
            nack_received_r <= '1';
          end if;

      end case;
    end if;
  end process;

  send_words : process(clk, rst_n)
  begin
    if rst_n = '0' then
      words_sent_r         <= (others => '0');
      --start_transmission_r <= '1';      -- ??
      finished_out         <= '0';
      reg_send_r           <= addr;     -- ??
      register_num_r       <= 0;
    elsif rising_edge(clk) then
      case reg_send_r is
        
        when addr =>
          data_to_send_r       <= codec_address_c;
          --start_transmission_r <= '0';
          new_transmission_r   <= '0';
          if ack_received_r = '1' then
            reg_send_r <= reg;
          elsif nack_received_r = '1' then
            reg_send_r <= addr;
          end if;

        when reg =>
          data_to_send_r <= parameter_table_c(register_num_r, 0);
          if ack_received_r = '1' then
            reg_send_r <= data;
          elsif nack_received_r = '1' then
            reg_send_r <= addr;
          end if;
          
        when data =>
          data_to_send_r     <= parameter_table_c(register_num_r, 1);
          new_transmission_r <= '1';
          if ack_received_r = '1' then
            words_sent_r <= words_sent_r + 1;
            if words_sent_r = n_params_g - 1 then  -- All sent
              reg_send_r <= done;
            else
              reg_send_r <= addr;
            end if;
          elsif nack_received_r = '1' then
            reg_send_r <= addr;
          end if;

        when done =>
          finished_out <= '1';
          
      end case;
    end if;
  end process;
  sclk_out         <= scl_r;
  param_status_out <= std_logic_vector(words_sent_r);
end rtl;
