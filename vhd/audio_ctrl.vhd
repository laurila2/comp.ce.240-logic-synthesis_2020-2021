-------------------------------------------------------------------------------
-- Title      : audio ctrl
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_ctrl.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop12.tuni.fi>
-- Company    : 
-- Created    : 2021-01-13
-- Last update: 2021-01-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: audio ctrl
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-01-13  1.0      mikkone8        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ctrl is
  generic (
    ref_clk_freq_g    : integer := 12288000;
    sample_rate_g : integer := 48000;
    data_width_g  : integer := 16
    );
  port (
    clk           : in std_logic;
    rst_n         : in std_logic;
    left_data_in  : in std_logic_vector(data_width_g-1 downto 0);
    right_data_in : in std_logic_vector(data_width_g-1 downto 0);

    aud_bclk_out  : out std_logic;
    aud_data_out  : out std_logic;
    aud_lrclk_out : out std_logic
    );
end audio_ctrl;


architecture rtl of audio_ctrl is
  -- clk cycles in 1/2 sample
  constant sample_length : integer := ref_clk_freq_g / (2*sample_rate_g);

  -- Counters for lrclk, bclk, change state at max (counts half periods)
  signal lrclk_counter_r : integer range 0 to sample_length-1;
  signal bclk_counter_r  : integer range 0 to sample_length/(data_width_g*2)-1;

  signal bclk_r, lrclk_r : std_logic;

  signal left_capture_r, right_capture_r : std_logic_vector(data_width_g-1 downto 0);
  -- Index of bit to write to DATIN/DATOUT
  signal write_bit_r                     : integer range 0 to data_width_g-1;
  
begin
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      bclk_counter_r  <= 0;
      lrclk_counter_r <= 0;
      bclk_r          <= '0';
      lrclk_r         <= '0';
      left_capture_r  <= (others => '0');
      right_capture_r <= (others => '0');
      
    elsif rising_edge(clk) then

      if bclk_counter_r = sample_length/(data_width_g*2)-1 then
        bclk_counter_r <= 0;
        bclk_r         <= not bclk_r;
        if bclk_r = '0' then            -- High clock
          if lrclk_r = '0' then
            aud_data_out <= right_capture_r(write_bit_r);
          else
            aud_data_out <= left_capture_r(write_bit_r);
          end if;

          -- Move to next bit
          if write_bit_r /= 0 then
            write_bit_r <= write_bit_r - 1;
          end if;
        end if;
      else
        bclk_counter_r <= bclk_counter_r + 1;
      end if;

      if lrclk_counter_r = sample_length-1 then
        lrclk_counter_r <= 0;
        lrclk_r         <= not lrclk_r;
        write_bit_r     <= data_width_g-1;
        if lrclk_r = '0' then
          right_capture_r <= right_data_in;
          left_capture_r  <= left_data_in;
        end if;
      else
        lrclk_counter_r <= lrclk_counter_r + 1;
      end if;
      
    end if;
    
  end process;

  aud_bclk_out  <= bclk_r;
  aud_lrclk_out <= lrclk_r;
  
end rtl;

