--------------------------------------------------------------------------------
-- sub_2.vhd
-- simplified description library for memory-mapped interface - example code of sdmmif sub module
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリーを使用したサブモジュールの例 その2
--------------------------------------------------------------------------------
-- package sub_2_inout
--
-- サブモジュールがFPGAのGPIOピンに接続する信号を記述する
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

-- sub_2 モジュールの入出力ポートのレコード型定義
package sub_2_inout is
  -- XX_pin_r は FPGA の入力ピンに接続する信号を記載する
  type sub_2_pin_r is record
    sig1 : std_logic;
  end record;

  -- XX_pout_r は FPGA の出力ピンに接続する信号を記載する
  type sub_2_pout_r is record
    sig1 : std_logic;
  end record;
end package;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- entity sub_2
--
-- サブモジュールの例 その2 の本体
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

use work.sdmmif.all; -- sdmmif_sin_r, sdmmif_sout_r の定義を読み込む
use work.sub_2_inout.all; -- sub_2_pin_r, sub_2_pout_r の定義を読み込む

entity sub_2 is
  port (
    clk : in std_logic;
    rst : in std_logic;

    sdmmin  : in sdmmif_sin_r;
    sdmmout : out sdmmif_sout_r;

    pin  : in sub_2_pin_r;
    pout : out sub_2_pout_r
  );
end entity;

architecture RTL of sub_2 is
begin
  -- レジスターアクセス
  process (all) begin -- process(all) : VHDL-2008
    clr_sdmmif_rddata_proc(clk, rst, sdmmin, sdmmout);

    ro_sdmmif_1bit_proc(clk, rst, sdmmin, sdmmout, X"020", 0, pin.sig1);
  end process;

  pout.sig1 <= not pin.sig1;
end architecture;
