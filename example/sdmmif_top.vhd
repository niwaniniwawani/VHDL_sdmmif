--------------------------------------------------------------------------------
-- sdmmif_top.vhd
-- simplified description library for memory-mapped interface - example code of top module (main module)
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリーを使用したサンプルのトップモジュール(メインモジュール)
--------------------------------------------------------------------------------
-- package sdmmif_top_inout
--
-- メインモジュールがFPGAのGPIOピンに接続する信号を記述する
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sdmmif.all;        -- sdmmif_sin_r, sdmmif_sout_r の定義を読み込む

library IEEE;
use IEEE.std_logic_1164.all;

-- top モジュールの入出力ポートのレコード型定義
package sdmmif_top_inout is
  -- XX_pin_r は FPGA の入力ピンに接続する信号を記載する
  type top_pin_r is record
    sig1 : std_logic_vector(7 downto 0);
  end record;

  -- XX_pout_r は FPGA の出力ピンに接続する信号を記載する
  type top_pout_r is record
    sig1 : std_logic_vector(15 downto 0);
  end record;
end package;

--------------------------------------------------------------------------------
-- entity sdmmif_top
--
-- メインモジュールの例の本体
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

use work.sdmmif.all;

use work.sub_1_inout.all;
use work.sub_2_inout.all;
use work.sdmmif_top_inout.all;

-- トップモジュールでrecordを使用した場合、論理合成やタイミングシミュレーションは可能だが、
-- VivadoのPost-Synthesis/Post-implementation Timing/Functional Simulationではエラーになるので注意。

entity sdmmif_top is
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- 使い方説明用のサンプルコードなので、FPGA内のメモリーマップトインターフェイスを外部にむき出しにしている。
    -- 通常の外部インターフェイスはMCU用のバスやSPI、UART等なので、普通はこんな風には使わない。
    sdmmif_mout : in sdmmif_mout_r;
    sdmmif_min  : out sdmmif_min_r;

    -- サブモジュールの外部I/Oポート
    sub_1_pin   : in sub_1_pin_r;
    sub_1_pout  : out sub_1_pout_r;
    sub_2_pin   : in sub_2_pin_r;
    sub_2_pout  : out sub_2_pout_r;

    top_pin  : in top_pin_r;
    top_pout : out top_pout_r
  );
end entity;

architecture RTL of sdmmif_top is
  -- MODule ADDRess; メモリーマップトインターフェイスバスに接続するサブモジュールの先頭アドレスを列挙する。
  constant MOD_ADDR : a_sdmmif_addresses_t := (x"1000", x"3000", x"4000");

  -- 各サブモジュール用のバスインターフェイスの配列
  signal a_sdmmin  : a_sdmmif_sin_r(MOD_ADDR'range);
  signal a_sdmmout : a_sdmmif_sout_r(MOD_ADDR'range);
begin
  -- アドレスデコーダーのインスタンス
  address_decoder_inst : entity work.sdmmif_address_decoder generic map(MOD_ADDR) port map (sdmmif_mout, sdmmif_min, a_sdmmin, a_sdmmout);

  sub_1_inst : entity work.sub_1 port map (clk, rst, a_sdmmin(sdmmif_idx(MOD_ADDR, x"1000")), a_sdmmout(sdmmif_idx(MOD_ADDR, x"1000")), sub_1_pin, sub_1_pout);
  sub_2_inst : entity work.sub_2 port map (clk, rst, a_sdmmin(sdmmif_idx(MOD_ADDR, x"3000")), a_sdmmout(sdmmif_idx(MOD_ADDR, x"3000")), sub_2_pin, sub_2_pout);

  -- トップモジュール内でもレジスターを設けてメモリーマップトインターフェイスに接続したい場合がある。その場合のレジスターアクセスの記述方法。
  sdmmif_access_b : block
    signal top_pout_q : top_pout_r; -- Quartus Prime Lite の場合、サブプログラムでは VHDL-2008 の出力ポートから読み込む機能に対応していないため、出力ポートは内部信号で中継する必要がある。
  begin
    process (all) -- process(all) : VHDL-2008: process(all)
      -- メインモジュールでもサブモジュールと同じレジスターアクセスのコード表記にしたいので、エイリアスで表記する。
      alias sdmmin is a_sdmmin(sdmmif_idx(MOD_ADDR, x"4000"));
      alias sdmmout is a_sdmmout(sdmmif_idx(MOD_ADDR, x"4000"));
    begin
      clr_sdmmif_rddata_proc(clk, rst, sdmmin, sdmmout);

      -- サブモジュールのアドレス空間はsdmmif_type.vhdにて9ビットに設定しているが、sdmmif.vhdの中でアドレスを範囲なしのstd_logic_vectorで記述しているため、
      -- オフセットさえ記載していれば、短縮表記(9ビットよりも短く表記)や0パディングした表記(9ビットよりも長く表記)でも表記可能。
      -- 9ビットよりも長いビット数が必要な値を記載した場合には、エラーになる(そのようにsdmmif.vhdを構成している)。
      ro_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"0", 7, 0, top_pin.sig1);
      rw_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"0123", 15, 0, x"0000", top_pout_q.sig1);
      ro_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"134", 15, 0, top_pout_q.sig1);
--      ro_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"0234", 15, 0, top_pout_q.sig1); -- これはコンパイルエラーになる

      top_pout <= top_pout_q;
    end process;
  end block;
end architecture;
