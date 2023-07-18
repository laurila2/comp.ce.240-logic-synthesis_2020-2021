-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 E02
-- Project    : Group 17
-------------------------------------------------------------------------------
-- File       : ripple_carry_adder.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop8.tuni.fi>
-- Company    : 
-- Created    : 2020-11-03
-- Last update: 2020-11-03
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 3 bit adder with carry out
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-11-03  1.0      mikkone8        Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity ripple_carry_adder is
  port (
    a_in  : in  std_logic_vector(2 downto 0);
    b_in  : in  std_logic_vector(2 downto 0);
    s_out : out std_logic_vector(3 downto 0)
    );
end ripple_carry_adder;


-------------------------------------------------------------------------------

architecture gate of ripple_carry_adder is

  signal carry_ha : std_logic;
  signal c, d, e  : std_logic;
  signal carry_fa : std_logic;
  signal f, g, h  : std_logic;

begin  -- gate

  s_out(0) <= a_in(0) xor b_in(0);
  carry_ha <= a_in(0) and b_in(0);

  c        <= a_in(1) xor b_in(1);
  s_out(1) <= c xor carry_ha;
  d        <= c and carry_ha;
  e        <= a_in(1) and b_in(1);
  carry_fa <= d or e;

  f        <= a_in(2) xor b_in(2);
  s_out(2) <= f xor carry_fa;
  g        <= f and carry_fa;
  h        <= a_in(2) and b_in(2);
  s_out(3) <= g or h;

end gate;
