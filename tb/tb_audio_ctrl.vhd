library ieee;
use ieee.std_logic_1164.all;

entity tb_audio_ctrl is
end tb_audio_ctrl;

architecture tb of tb_audio_ctrl is
  constant data_width_c : integer := 16;
  constant sample_freq_c : integer := 48000;
  constant ref_freq_c : integer := 20000000;
    
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';

  signal bclk  : std_logic;
  signal lrclk : std_logic;
  signal data : std_logic;

  signal sync_clear_n : std_logic;

  signal wave_1, wave_2 : std_logic_vector(data_width_c-1 downto 0);
  
begin
  clk   <= not clk after 25 ns;
  rst_n <= '1'     after 40 ns;
  sync_clear_n <= '1' after 40 ns, '0' after 7 ms, '1' after 8 ms;
  
  i_wave_gen_1: entity work.wave_gen
    generic map (
      width_g => data_width_c,
      step_g  => 10)
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => sync_clear_n,
      value_out       => wave_1);
  
  i_wave_gen_2: entity work.wave_gen
    generic map (
      width_g => data_width_c,
      step_g  => 2)
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => sync_clear_n,
      value_out       => wave_2);
  
  i_audio_codec : entity work.audio_codec_model
    generic map (
      data_width_g => data_width_c )
    port map(
      rst_n => rst_n,
      aud_data_in => data,
      aud_lrclk_in => lrclk,
      aud_bclk_in => bclk,
      value_right_out => open,
      value_left_out => open
      );

  i_audio_ctrl : entity work.audio_ctrl
    generic map (
      ref_freq_g => ref_freq_c,
      sample_rate_g => sample_freq_c,
      data_width_g => data_width_c
      )
    port map (
      clk           => clk,
      rst_n         => rst_n,
      left_data_in  => wave_1,
      right_data_in => wave_2,
      aud_bclk_out  => bclk,
      aud_lrclk_out => lrclk,
      aud_data_out  => data
      );

end tb;

