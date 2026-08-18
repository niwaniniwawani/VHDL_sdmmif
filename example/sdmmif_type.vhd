--------------------------------------------------------------------------------
-- sdmmif_type.vhd
-- simplified description library for memory-mapped interface - sdmmif type definition parameters
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリーを使用したサンプルの型定義パラメーター
--
-- 基本的には最初に設定すればそれ以降は変更不要なパラメーターを記載している。
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

package sdmmif_type is
  constant MAIN_ADDRESS_BUS_WIDTH : natural := 16; -- メインモジュール側のアドレスバス幅(アドレスデコードされる前のアドレスバス幅)
  constant SUB_ADDRESS_BUS_WIDTH  : natural := 9; -- サブモジュール側のアドレスバス幅(アドレスデコードされた後のアドレスバス幅)
  constant DATA_BUS_WIDTH         : natural := 16; -- データバス幅
end package;
