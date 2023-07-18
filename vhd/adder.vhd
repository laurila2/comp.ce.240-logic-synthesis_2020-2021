-------------------------------------------------------------------------------
-- Title      : COMP.CE.240
-- Project    : Group 17
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop12.tuni.fi>
-- Company    : 
-- Created    : 2020-11-03
-- Last update: 2020-11-03
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Generic width adder with registered output
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-11-03  1.0      mikkone8        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
  generic (
    operand_width_g : integer
    );

  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;
    a_in, b_in : in  std_logic_vector(operand_width_g - 1 downto 0);
    sum_out    : out std_logic_vector(operand_width_g downto 0)
    );
end adder;

architecture rtl of adder is

  signal result_r : signed(operand_width_g downto 0);
  
begin

  sum_out <= std_logic_vector(result_r);

  add : process(clk, rst_n)
  begin
    if (rst_n = '0') then
      result_r <= (others => '0');
    elsif rising_edge(clk) then
      result_r <= resize(signed(a_in), operand_width_g + 1) +
                  resize(signed(b_in), operand_width_g + 1);
    end if;
  end process;
  
end rtl;
