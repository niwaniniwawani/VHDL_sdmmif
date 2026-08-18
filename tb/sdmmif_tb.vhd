--------------------------------------------------------------------------------
-- sdmmif_tb.vhd
-- simplified description library for memory-mapped interface - test bench
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリー用のテストベンチ
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sdmmif.all;

use work.sub_1_inout.all;
use work.sub_2_inout.all;
use work.sdmmif_top_inout.all;

entity sdmmif_tb is
end entity;

architecture RTL of sdmmif_tb is
  signal clk          : std_logic;
  signal rst          : std_logic;
  signal sdmmif_mout  : sdmmif_mout_r;
  signal sdmmif_min   : sdmmif_min_r;
  signal sub_1_pin    : sub_1_pin_r;
  signal sub_1_pout   : sub_1_pout_r;
  signal sub_2_pin    : sub_2_pin_r;
  signal sub_2_pout   : sub_2_pout_r;
  signal top_pin      : top_pin_r;
  signal top_pout     : top_pout_r;

  signal rddata       : sdmmif_data_bus_st;

  procedure rd_sdmmif_proc (
    signal clk         : in std_logic;
    signal sdmmif_mout : out sdmmif_mout_r;
    constant addr      : in std_logic_vector;
    signal rddata      : out std_logic_vector
  ) is
  begin
    sdmmif_mout <= ((others => '0'), '0', '0', (others => '0'));
    wait for 10 ns; -- シミュレーターやシミュレーションの種類によっては、clk のエッジと完全に同期すると、意図した順序で処理できない(上の行のrising_edge(clk)で処理される)ので、少しだけ遅らせる。
    sdmmif_mout <= (addr, '1', '0', (others => '0'));
    wait until rising_edge(clk);
    rddata <= sdmmif_min.rddata;
    sdmmif_mout <= ((others => '0'), '0', '0', (others => '0'));
  end procedure;

  procedure wr_sdmmif_proc (
    signal clk         : in std_logic;
    signal sdmmif_mout : out sdmmif_mout_r;
    constant addr      : in std_logic_vector;
    constant wrdata    : in std_logic_vector
  ) is
  begin
    sdmmif_mout <= ((others => '0'), '0', '0', (others => '0'));
    wait for 10 ns; -- シミュレーターやシミュレーションの種類によっては、clk のエッジと完全に同期すると、意図した順序で処理できない(上の行のrising_edge(clk)で処理される)ので、少しだけ遅らせる。
    sdmmif_mout <= (addr, '0', '1', wrdata);
    wait until rising_edge(clk);
    sdmmif_mout <= ((others => '0'), '0', '0', (others => '0'));
  end procedure;
begin
  top_inst : entity work.sdmmif_top port map (clk, rst, sdmmif_mout, sdmmif_min, sub_1_pin, sub_1_pout, sub_2_pin, sub_2_pout, top_pin, top_pout);

  process begin
    clk <= '0';
    wait for 50 ns;
    clk <= '1';
    wait for 50 ns;
  end process;

  process begin
    rst <= '1';
    wait for 110 ns;
    rst <= '0';
    wait;
  end process;

  process begin
    sub_1_pin <= (others => '0');
    top_pin <= (others => (others => '0'));
    wait;
  end process;


  process begin
    rddata <= (others => '0');
    sdmmif_mout <= ((others => '0'), '0', '0', (others => '0'));
    sub_2_pin <= (others => '0');
    wait for 110 ns; -- リセット完了まで待つ
    wait until rising_edge(clk);
    wr_sdmmif_proc(clk, sdmmif_mout, x"1010", x"0001");
    sub_2_pin <= (others => '1');
    rd_sdmmif_proc(clk, sdmmif_mout, x"3020", rddata);
    sub_2_pin <= (others => '0');
    rd_sdmmif_proc(clk, sdmmif_mout, x"3020", rddata);
    rd_sdmmif_proc(clk, sdmmif_mout, x"4123", rddata);
    wr_sdmmif_proc(clk, sdmmif_mout, x"4123", x"5432");
    rd_sdmmif_proc(clk, sdmmif_mout, x"4123", rddata);
    wait;
  end process;

end architecture;
