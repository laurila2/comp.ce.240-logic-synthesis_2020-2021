library ieee;
use ieee.std_logic_1164.all;

entity tb_i2c_config is
end entity;

architecture tb of tb_i2c_config is
  signal rst_n, clk   : std_logic := '0';
  signal scl, sda     : std_logic;
  signal param_status : std_logic_vector(3 downto 0);
  signal finished_out : std_logic;
begin
  clk   <= not clk after 10 ns;
  rst_n <= '1'     after 25 ns;

  i_dut : entity work.i2c_config
    port map (
      clk              => clk,
      rst_n            => rst_n,
      sdat_inout       => sda,
      sclk_out         => scl,
      param_status_out => param_status,
      finished_out     => finished_out);
end tb;

