-------------------------------------------------------------------------------
-- Title      : COM.CE.240
-- Project    : Group 17
-------------------------------------------------------------------------------
-- File       : tb_multi_port_adder.vhd
-- Author     : Nuutti Mikkonen  <mikkone8@linux-desktop11.tuni.fi>
-- Company    : 
-- Created    : 2020-11-26
-- Last update: 2020-11-26
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Tb for multi port adder
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-11-26  1.0      mikkone8        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_multi_port_adder is
  generic (
    operand_width_g : integer := 3
    );

end tb_multi_port_adder;


architecture testbench of tb_multi_port_adder is

  constant period_c       : time    := 10 ns;
  constant num_operands_c : integer := 4;
  constant duv_delay_c    : integer := 2;

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';

  signal operands_r : std_logic_vector(num_operands_c*operand_width_g-1
                                       downto 0);
  signal sum            : std_logic_vector(operand_width_g - 1 downto 0);
  signal output_valid_r : std_logic_vector(duv_delay_c downto 0);

  file input_f       : text open read_mode is "input.txt";
  file ref_results_f : text open read_mode is "ref_results.txt";
  file output_f      : text open write_mode is "output.txt";
  
begin

  clk   <= not clk after period_c / 2;
  rst_n <= '1'     after 4 * period_c;

  i_duv : entity work.multi_port_adder
    generic map (
      operand_width_g   => operand_width_g,
      num_of_operands_g => num_operands_c
      )
    port map (
      clk         => clk,
      rst_n       => rst_n,
      operands_in => operands_r,
      sum_out     => sum
      );

  -- Set adder inputs to input file stim, set outputs_valid_r
  input_reader : process(rst_n, clk)
    variable read_v   : line;
    type value_t is array (num_operands_c - 1 downto 0) of integer;
    variable values_v : value_t;
  begin
    if (rst_n = '0') then
      operands_r     <= (others => '0');
      output_valid_r <= (others => '0');
    elsif rising_edge(clk) then
      if (not endfile(input_f)) then
        output_valid_r <= output_valid_r(duv_delay_c - 1 downto 0) & '1';
        readline(input_f, read_v);
        -- Ignore comments
        while (read_v.all(1) = '#') loop
          readline(input_f, read_v);
        end loop;
        for i in num_operands_c-1 downto 0 loop
          read(read_v, values_v(i));
          operands_r((i+1)*operand_width_g-1 downto i*operand_width_g)
            <= std_logic_vector(to_signed(values_v(i), operand_width_g));
        end loop;
      end if;
    end if;
  end process;

  -- Check adder output against reference values, write to file
  checker : process(rst_n, clk)
    variable read_v      : line;
    variable write_v     : line;
    variable ref_value_v : integer;
  begin
    if (rst_n = '0') then
    elsif rising_edge(clk) then
      if (output_valid_r(duv_delay_c) = '1') then
        if (not endfile(ref_results_f)) then
          readline(ref_results_f, read_v);
          -- Ignore comments
          while (read_v.all(1) = '#') loop
            readline(ref_results_f, read_v);
          end loop;
          read(read_v, ref_value_v);
          assert (ref_value_v = to_integer(signed(sum))) report "Miscompare" severity note;
          write(write_v, to_integer(signed(sum)));
          writeline(output_f, write_v);
        else
          assert false report "Simulation done" severity failure;
        end if;
      end if;
    end if;
  end process;
end testbench;
