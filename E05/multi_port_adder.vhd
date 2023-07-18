-------------------------------------------------------------------------------
-- Title      : COMP.CE.240
-- Project    : Group 17
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop11.tuni.fi>
-- Company    : 
-- Created    : 2020-11-26
-- Last update: 2020-11-26
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Multi-port adder with generic width
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-11-26  1.0      mikkone8	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity multi_port_adder is
  generic (
    operand_width_g   : integer := 16;
    num_of_operands_g : integer := 4
    );
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    operands_in : in  std_logic_vector(operand_width_g * num_of_operands_g - 1
                                       downto 0);
    sum_out     : out std_logic_vector(operand_width_g - 1 downto 0)
    );
end multi_port_adder;

architecture structural of multi_port_adder is
  
  component adder is
    generic (
      operand_width_g : integer);
    port (
      clk        : in  std_logic;
      rst_n      : in  std_logic;
      a_in, b_in : in  std_logic_vector(operand_width_g - 1 downto 0);
      sum_out    : out std_logic_vector(operand_width_g downto 0));
  end component adder;

  type subtotal_t is array (num_of_operands_g / 2 - 1 downto 0) of
    std_logic_vector(operand_width_g downto 0);
  signal subtotal : subtotal_t;

  signal total : std_logic_vector(operand_width_g + 1 downto 0);
  
begin
  i_adder_1 : entity work.adder
    generic map (
      operand_width_g => operand_width_g)
    port map (
      clk     => clk,
      rst_n   => rst_n,
      a_in    => operands_in(operand_width_g - 1 downto 0),
      b_in    => operands_in(2 * operand_width_g - 1 downto operand_width_g),
      sum_out => subtotal(0));

  i_adder_2 : entity work.adder
    generic map (
      operand_width_g => operand_width_g)
    port map (
      clk     => clk,
      rst_n   => rst_n,
      a_in    => operands_in(3 * operand_width_g - 1 downto 2 * operand_width_g),
      b_in    => operands_in(4 * operand_width_g - 1 downto 3 * operand_width_g),
      sum_out => subtotal(1));

  i_adder_3 : entity work.adder
    generic map (
      operand_width_g => operand_width_g + 1)
    port map (
      clk     => clk,
      rst_n   => rst_n,
      a_in    => subtotal(0),
      b_in    => subtotal(1),
      sum_out => total);

  sum_out <= total(operand_width_g - 1 downto 0);

  assert (num_of_operands_g = 4) report "Invalid width" severity failure;

end structural;
