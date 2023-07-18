-------------------------------------------------------------------------------
-- Title      : COMP.CE.240
-- Project    : Group 17
-------------------------------------------------------------------------------
-- File       : wave_gen.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop1.tuni.fi>
-- Company    : 
-- Created    : 2020-12-03
-- Last update: 2021-01-13
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Triangle wave generator with generic period and amplitude
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-12-03  1.0      mikkone8        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wave_gen is
  generic (
    width_g : integer;
    step_g  : integer
    );
  port (
    clk             : in  std_logic;
    rst_n           : in  std_logic;
    sync_clear_n_in : in  std_logic;
    value_out       : out std_logic_vector(width_g-1 downto 0)
    );
end wave_gen;

architecture rtl of wave_gen is
  constant max_c : integer := ((2**(width_g-1)-1)/step_g)*step_g;
  constant min_c : integer := -max_c;

  signal dir_r   : std_logic;
  signal value_r : signed(width_g-1 downto 0);
  
begin
  value_out <= std_logic_vector(value_r);

  process(rst_n, clk)
  begin
    if (rst_n = '0') then
      dir_r   <= '0';
      value_r <= (others => '0');
    elsif rising_edge(clk) then
      if (dir_r = '0') then
        value_r <= value_r + step_g;
      else
        value_r <= value_r - step_g;
      end if;

      -- Registered signal, change one step before max/min
      if (value_r = max_c - step_g) then
        dir_r <= '1';
      elsif (value_r = min_c + step_g) then
        dir_r <= '0';
      end if;
      
      if (sync_clear_n_in = '0') then
        dir_r   <= '0';
        value_r <= (others => '0');
      end if;

    end if;
  end process;
end rtl;

