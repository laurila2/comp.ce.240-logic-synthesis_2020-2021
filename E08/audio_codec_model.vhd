-------------------------------------------------------------------------------
-- Title      : Audio codec model
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop4.tuni.fi>
-- Company    : 
-- Created    : 2021-01-20
-- Last update: 2021-01-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Audio codec model
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-01-20  1.0      mikkone8        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity audio_codec_model is
  generic (
    data_width_g : integer := 16
    );
  port (
    rst_n        : in std_logic;
    aud_data_in  : in std_logic;
    aud_bclk_in  : in std_logic;
    aud_lrclk_in : in std_logic;

    value_left_out  : out std_logic_vector(data_width_g-1 downto 0);
    value_right_out : out std_logic_vector(data_width_g-1 downto 0)
    );
end entity;

architecture tb of audio_codec_model is
  type codec_state is (wait_for_input, read_left, read_right);
  signal state_r      : codec_state := wait_for_input;
  signal prev_state_r : codec_state;

  signal count_r : integer := 0;

  signal left_r, right_r : std_logic_vector(data_width_g-1 downto 0);
  
begin
  receive_bits : process(rst_n, aud_bclk_in)
    -- done_v is set when full word is received. It is cleared when state changes.
    variable done_v : std_logic := '0';
  begin
    if rst_n = '0' then
      count_r <= data_width_g-1;
    elsif rising_edge(aud_bclk_in) then
      if done_v = '0' then
        count_r <= count_r - 1;
      end if;
      if count_r = 0 then
        count_r      <= data_width_g-1;
        -- Save state so that done_v can be toggled on state transition
        prev_state_r <= state_r;
      else
        if prev_state_r /= state_r then
          done_v  := '0';
          -- Counter is decreased also here because first if will evaluate to
          -- false for first bit
          count_r <= count_r - 1;
        end if;
      end if;
      if state_r = wait_for_input then
        count_r <= data_width_g-1;
      end if;

      if done_v = '0' then
        if state_r = read_left then
          left_r(count_r) <= aud_data_in;
        elsif state_r = read_right then
          right_r(count_r) <= aud_data_in;
        end if;
      end if;

      -- After reading data in so that last bit is read even if audio_ctrl
      -- doesn't send extra bclk cycles
      if count_r = 0 then
        done_v := '1';
      end if;
      
    end if;
  end process;

  -- Sets state and outputs audio data at transition
  state_machine : process(state_r, aud_lrclk_in, left_r, right_r)
  begin
    if state_r = wait_for_input and aud_lrclk_in = '1' then
      state_r <= read_left;
    elsif state_r = read_left and aud_lrclk_in = '0' then
      state_r        <= read_right;
      value_left_out <= left_r;
    elsif state_r = read_right and aud_lrclk_in = '1' then
      state_r         <= read_left;
      value_right_out <= right_r;
    end if;
  end process;
end tb;
