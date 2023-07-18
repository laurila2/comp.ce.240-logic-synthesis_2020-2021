-------------------------------------------------------------------------------
-- Title      : Synthesizer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : synthesizer.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop7.tuni.fi>
-- Company    : 
-- Created    : 2021-01-28
-- Last update: 2021-01-28
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Synthesizer top level including wave gens, adder and audio_ctrl
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-01-28  1.0      mikkone8        Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity synthesizer is
  generic (
    clk_freq_g    : integer := 12288000;
    sample_rate_g : integer := 48000;
    data_width_g  : integer := 16;
    n_keys_g      : integer := 4
    );
  port (
    clk     : in std_logic;
    rst_n   : in std_logic;
    keys_in : in std_logic_vector(n_keys_g-1 downto 0);

    aud_bclk_out  : out std_logic;
    aud_data_out  : out std_logic;
    aud_lrclk_out : out std_logic
    );
end synthesizer;

architecture structural of synthesizer is
  -- Signal from adder to audio ctrl left and right channel
  signal data_multi_adder_audio_ctrl : std_logic_vector(data_width_g-1 downto 0);

  -- All wave gen outputs in 1 vector
  signal value_wave_gen_multi_adder : std_logic_vector(n_keys_g*data_width_g-1 downto 0);

  
begin

  i_audio_ctrl : entity work.audio_ctrl
    generic map (
      ref_clk_freq_g => clk_freq_g,
      sample_rate_g  => sample_rate_g,
      data_width_g   => data_width_g)
    port map (
      clk           => clk,
      rst_n         => rst_n,
      left_data_in  => data_multi_adder_audio_ctrl,
      right_data_in => data_multi_adder_audio_ctrl,
      aud_bclk_out  => aud_bclk_out,
      aud_data_out  => aud_data_out,
      aud_lrclk_out => aud_lrclk_out);

  i_multi_port_adder : entity work.multi_port_adder
    generic map (
      operand_width_g   => data_width_g,
      num_of_operands_g => n_keys_g)
    port map (
      clk         => clk,
      rst_n       => rst_n,
      operands_in => value_wave_gen_multi_adder,
      sum_out     => data_multi_adder_audio_ctrl);

  -- Number of keys is used as amount of wave_gens
  gen_wave_gen : for i in 0 to n_keys_g-1 generate
    i_wave_gen : entity work.wave_gen
      generic map (
        width_g => data_width_g,
        step_g  => 2**i)
      port map (
        clk             => clk,
        rst_n           => rst_n,
        sync_clear_n_in => keys_in(i),
        value_out       => value_wave_gen_multi_adder((i+1)*data_width_g-1 downto i*data_width_g));
  end generate gen_wave_gen;

end structural;
