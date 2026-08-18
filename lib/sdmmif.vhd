--------------------------------------------------------------------------------
-- sdmmif.vhd
-- simplified description library for memory-mapped interface
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリー
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sdmmif_type.all;

package sdmmif is
  subtype sdmmif_main_addr_st is std_logic_vector(MAIN_ADDRESS_BUS_WIDTH - 1 downto 0); -- メインモジュール側のアドレスバスの型
  subtype sdmmif_sub_addr_st is std_logic_vector(SUB_ADDRESS_BUS_WIDTH - 1 downto 0); -- サブモジュール側のアドレスバスの型
  subtype sdmmif_module_addr_st is std_logic_vector(MAIN_ADDRESS_BUS_WIDTH - 1 downto SUB_ADDRESS_BUS_WIDTH); -- どのサブモジュールのアクセスかを識別する部分のアドレス

  subtype sdmmif_data_bus_st is std_logic_vector(DATA_BUS_WIDTH - 1 downto 0); -- データバスの型

  --
  -- サブモジュールのフルアドレスが入力されると、そのサブモジュールのインデックス番号を返す。
  --
  -- メインモジュールでアドレスデコーダーをport mapする際、サブモジュールの個数分のバスがマッピングされる。
  -- 接続するサブモジュールが増えるたびにアドレスデコーダーのport mapの記述を変更するのは手間なので、
  -- アドレスデコーダーのport mapには、サブモジュールの個数分のバスの配列を記載することとした。
  type a_sdmmif_addresses_t is array (natural range <>) of std_logic_vector(MAIN_ADDRESS_BUS_WIDTH - 1 downto 0);
  function sdmmif_idx(MOD_ADDR : a_sdmmif_addresses_t; addr : sdmmif_main_addr_st) return natural;

  -- メインモジュールからアドレスデコーダーに出力するメモリーマップトインターフェイス用の信号の構造体
  type sdmmif_mout_r is record
    addr   : sdmmif_main_addr_st;
    rd     : std_logic;
    wr     : std_logic;
    wrdata : sdmmif_data_bus_st;
  end record;

  -- アドレスデコーダーからメインモジュールに出力するメモリーマップトインターフェイス用の信号の構造体
  type sdmmif_min_r is record
    rddata : sdmmif_data_bus_st;
  end record;

  -- アドレスデコーダーから(メインモジュールを通じて)それぞれのサブモジュールに出力するメモリーマップトインターフェイス用の信号の構造体
  type sdmmif_sin_r is record -- mmif sub-module signal in
    addr   : sdmmif_sub_addr_st;
    rd     : std_logic;
    wr     : std_logic;
    wrdata : sdmmif_data_bus_st;
  end record;

  -- それぞれのサブモジュールから(メインモジュールを通じて)アドレスデコーダーに出力するメモリーマップトインターフェイス用の信号の構造体
  type sdmmif_sout_r is record -- mmif sub-module signal out
    rddata : sdmmif_data_bus_st;
  end record;

  type a_sdmmif_sin_r is array (natural range <>) of sdmmif_sin_r;
  type a_sdmmif_sout_r is array (natural range <>) of sdmmif_sout_r;

  ------------------------------------------------------------
  -- メモリーマップトインターフェイスによるレジスター読み出しを非同期アクセスにする場合に、rddataのデフォルト値を代入する。
  -- この記述がないと、読み出されないビットの値がprocess内で定義されないので、inferred latchとなる。
  -- それを避けるために、サブモジュールのレジスターアクセス用のprocessの先頭に記述しておく。
  procedure clr_sdmmif_rddata_proc (
    signal clk      : in std_logic;
    signal rst      : in std_logic;
    constant sdmmin : in sdmmif_sin_r;
    signal sdmmout  : out sdmmif_sout_r
  );

  ----------------------------------------------------------------------
  -- サブモジュールにおいて簡潔な記述でレジスターを読み書きできるようにするプロシージャ群
  --
  -- プレフィックスのrw_, ro_, wo_ を書き換えるだけでレジスターをRead/Write, Read Only, Write Onlyに変更できるようにするために、
  -- プロシージャー間で引き数の数や順番を揃えている。
  -- 同じアドレスで同じレジスターにアクセスする場合は、Read/Writeの両方を1行で記述できるのが特長。
  -- プロシージャーの引き数はなるべく型が重ならないように記述することで、
  -- サブモジュールで使用する際に位置関連付け(Positional Association)で記述してもコーディングミスが起きにくいようにしている。
  --
  -- プレフィックス:
  -- rw_* : 読み書きできるレジスターに対するプロシージャー
  -- ro_* : 読み込み専用のレジスターに対するプロシージャー
  -- wo_* : 書き込み専用のレジスターに対するプロシージャー
  -- 
  -- clk: クロック
  -- rst: 正論理のリセット信号(synchronized asynchronous resetを想定)
  -- sdmmin: サブモジュールに入力されるsdmmifの信号群(record)
  -- sdmmout: サブモジュールから出力されるsdmmifの信号群(record)
  -- addr: 対象のレジスターのアドレス
  ------------------------------------------------------------
  -- 多ビットのレジスターの読み書き
  ------------------------------------------------------------
  -- メモリーマップトインターフェイスを通じてサブモジュールの多ビットのレジスターに読み書きできるようにする
  procedure rw_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant init     : in std_logic_vector;
    signal io         : inout std_logic_vector
  );

  -- メモリーマップトインターフェイスを通じてサブモジュールの多ビットのレジスターを読み込めるようにする
  procedure ro_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant i        : in std_logic_vector
  );

  -- メモリーマップトインターフェイスを通じてサブモジュールの多ビットのレジスターに書き込めるようにする
  procedure wo_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant init     : in std_logic_vector;
    signal o          : out std_logic_vector
  );

  ------------------------------------------------------------
  -- 1ビットのレジスターの読み書き
  ------------------------------------------------------------
  -- メモリーマップトインターフェイスを通じてサブモジュールの1ビットのレジスターに読み書きできるようにする
  procedure rw_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant init    : in std_logic;
    signal io        : inout std_logic
  );

  -- メモリーマップトインターフェイスを通じてサブモジュールの1ビットのレジスターを読み込めるようにする
  procedure ro_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant i       : in std_logic
  );

  -- メモリーマップトインターフェイスを通じてサブモジュール1ビットのレジスターに書き込めるようにする
  procedure wo_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant init    : in std_logic;
    signal o         : out std_logic
  );

  ------------------------------------------------------------
  -- コンペアマッチによる1クロックトリガー信号生成
  ------------------------------------------------------------
  procedure wr_cmp_match_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant data     : in std_logic_vector;
    signal match      : out std_logic
  );

  procedure wr_cmp_match_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant data    : in std_logic;
    signal match     : out std_logic
  );

  ------------------------------------------------------------
  -- 指定アドレス読み出しによる1クロック幅トリガー信号生成
  ------------------------------------------------------------
  procedure rdtrg_sdmmif_addr_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    constant sdmmout : in sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    signal trg       : out std_logic
  );

  ------------------------------------------------------------
  -- 指定アドレス書き込みによる1クロック幅トリガー信号生成
  ------------------------------------------------------------
  procedure wrtrg_sdmmif_addr_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    constant sdmmout : in sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    signal trg       : out std_logic
  );
end package;

package body sdmmif is
  function sdmmif_idx(MOD_ADDR : a_sdmmif_addresses_t; addr : sdmmif_main_addr_st) return natural is
    variable index : natural := 0;
  begin
    while index < MOD_ADDR'length loop
      if MOD_ADDR(index) = addr then
        return index;
      end if;
      index := index + 1;
    end loop;
    assert index = MOD_ADDR'length report "sdmmif_idx: address not found" severity failure;
    --      return 0;
  end function;

  ------------------------------------------------------------
  procedure clr_sdmmif_rddata_proc (
    signal clk      : in std_logic;
    signal rst      : in std_logic;
    constant sdmmin : in sdmmif_sin_r;
    signal sdmmout  : out sdmmif_sout_r
  ) is
  begin
    -- バスからのレジスター読み出しを非同期アクセスにする場合
    sdmmout.rddata <= (others => '0');

    -- バスからのレジスター読み出しを同期アクセスにする場合
    -- 何も書かないこと(rising_edge(clk)外でrddataの値を指定することになり、論理合成できなくなるため)
  end procedure;

  ------------------------------------------------------------
  -- 多ビットのバスアクセス
  ------------------------------------------------------------
  procedure rw_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant init     : in std_logic_vector;
    signal io         : inout std_logic_vector
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_highとbit_lowの値のチェック
    if (io'length /= bit_high - bit_low + 1) or (DATA_BUS_WIDTH <= bit_high) then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = データの読み書き先の信号のビット長がbit_highとbit_lowで表現されるビット長と一致しない。もしくはbit_highの値がデータバス幅よりも大きい。
    end if;

    -- initのビット長のチェック
    if io'length /= init'length then
      err_addr := err_code(2 downto 0); -- エラーコード 3 = 初期値のビット長がデータの書き込み先の信号のビット長と一致しない。
    end if;
    --------------------------------------------------

    -- バスからのレジスター読み出しを非同期アクセスにする場合
    if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
      sdmmout.rddata(bit_high downto bit_low) <= io;
    end if;

    -- -- バスからのレジスター読み出しを同期アクセスにする場合の例(動作未検証)
    -- if rising_edge(clk) then
    --   if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
    --     sdmmout.rddata(bit_high downto bit_low) <= io;
    --   end if;
    -- end if;

    -- バスからのレジスター書き込みは同期アクセス
    if (rst = '1') then
      io <= init;
    elsif rising_edge(clk) then
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
        io <= sdmmin.wrdata(bit_high downto bit_low);
      end if;
    end if;
  end procedure;

  procedure ro_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant i        : in std_logic_vector
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_highとbit_lowの値のチェック
    if (i'length /= bit_high - bit_low + 1) or (DATA_BUS_WIDTH <= bit_high) then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = データの読み込み先の信号のビット長がbit_highとbit_lowで表現されるビット長と一致しない。もしくはbit_highの値がデータバス幅よりも大きい。
    end if;
    --------------------------------------------------

    -- バスからのレジスター読み出しを非同期アクセスにする場合
    if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
      sdmmout.rddata(bit_high downto bit_low) <= i;
    end if;

    -- -- バスからのレジスター読み出しを同期アクセスにする場合の例(動作未検証)
    -- if rising_edge(clk) then
    --   if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
    --     sdmmout.rddata(bit_high downto bit_low) <= i;
    --   end if;
    -- end if;
  end procedure;

  procedure wo_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant init     : in std_logic_vector;
    signal o          : out std_logic_vector
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_highとbit_lowの値のチェック
    if (o'length /= bit_high - bit_low + 1) or (DATA_BUS_WIDTH <= bit_high) then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = データの書き込み先の信号のビット長がbit_highとbit_lowで表現されるビット長と一致しない。もしくはbit_highの値がデータバス幅よりも大きい。
    end if;

    -- initのビット長のチェック
    if o'length /= init'length then
      err_addr := err_code(2 downto 0); -- エラーコード 3 = 初期値のビット長がデータの書き込み先の信号のビット長と一致しない。
    end if;
    --------------------------------------------------

    -- バスからのレジスター書き込みは同期アクセス
    if (rst = '1') then
      o <= init;
    elsif rising_edge(clk) then
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
        o <= sdmmin.wrdata(bit_high downto bit_low);
      end if;
    end if;
  end procedure;

  ------------------------------------------------------------
  -- 1ビットのバスアクセス
  ------------------------------------------------------------
  procedure rw_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant init    : in std_logic;
    signal io        : inout std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_numの値のチェック
    if DATA_BUS_WIDTH <= bit_num then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = bit_numの値がデータバス幅よりも大きい。
    end if;
    --------------------------------------------------

    -- バスからのレジスター読み出しを非同期アクセスにする場合
    if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
      sdmmout.rddata(bit_num) <= io;
    end if;

    -- -- バスからのレジスター読み出しを同期アクセスにする場合の例(動作未検証)
    -- if rising_edge(clk) then
    --   if sdmmin(n).rd = '1' and unsigned(sdmmin(n).addr) = unsigned(addr) then
    --     sdmmout(n).rddata(bit_num) <= i;
    --   end if;
    -- end if;

    -- バスからのレジスター書き込みは同期アクセス
    if (rst = '1') then
      io <= init;
    elsif rising_edge(clk) then
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
        io <= sdmmin.wrdata(bit_num);
      end if;
    end if;
  end procedure;

  procedure ro_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant i       : in std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_numの値のチェック
    if DATA_BUS_WIDTH <= bit_num then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = bit_numの値がデータバス幅よりも大きい。
    end if;
    --------------------------------------------------

    -- バスからのレジスター読み出しを非同期アクセスにする場合
    if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
      sdmmout.rddata(bit_num) <= i;
    end if;

    -- -- バスからのレジスター読み出しを同期アクセスにする場合の例(動作未検証)
    -- if rising_edge(clk) then
    --   if sdmmin(n).rd = '1' and unsigned(sdmmin(n).addr) = unsigned(addr) then
    --     sdmmout(n).rddata(bit_num) <= i;
    --   end if;
    -- end if;
  end procedure;

  procedure wo_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant init    : in std_logic;
    signal o         : out std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_numの値のチェック
    if DATA_BUS_WIDTH <= bit_num then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = bit_numの値がデータバス幅よりも大きい。
    end if;
    --------------------------------------------------

    -- バスからのレジスター書き込みは同期アクセス
    if (rst = '1') then
      o <= init;
    elsif rising_edge(clk) then
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
        o <= sdmmin.wrdata(bit_num);
      end if;
    end if;
  end procedure;

  ------------------------------------------------------------
  -- コンペアマッチによる1クロック幅トリガー信号生成
  ------------------------------------------------------------
  procedure wr_cmp_match_sdmmif_bits_proc (
    signal clk        : in std_logic;
    signal rst        : in std_logic;
    constant sdmmin   : in sdmmif_sin_r;
    signal sdmmout    : out sdmmif_sout_r;
    constant addr     : in std_logic_vector;
    constant bit_high : in natural;
    constant bit_low  : in natural;
    constant data     : in std_logic_vector;
    signal match      : out std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_highとbit_lowの値のチェック
    if (data'length /= bit_high - bit_low + 1) or (DATA_BUS_WIDTH <= bit_high) then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = データの読み書き先の信号のビット長がbit_highとbit_lowで表現されるビット長と一致しない。もしくはbit_highの値がデータバス幅よりも大きい。
    end if;
    --------------------------------------------------

    if (rst = '1') then
      match <= '0';
    elsif rising_edge(clk) then
      match <= '0';
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) and sdmmin.wrdata(bit_high downto bit_low) = data then
        match <= '1';
      end if;
    end if;

  end procedure;


  procedure wr_cmp_match_sdmmif_1bit_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    signal sdmmout   : out sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    constant bit_num : in natural;
    constant data    : in std_logic;
    signal match     : out std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;

    -- bit_numの値のチェック
    if DATA_BUS_WIDTH <= bit_num then
      err_addr := err_code(1 downto 0); -- エラーコード 2 = bit_numの値がデータバス幅よりも大きい。
    end if;
    --------------------------------------------------

    if (rst = '1') then
      match <= '0';
    elsif rising_edge(clk) then
      match <= '0';
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) and sdmmin.wrdata(bit_num) = data then
        match <= '1';
      end if;
    end if;
  end procedure;

  ------------------------------------------------------------
  -- 指定アドレス読み出しによる1クロック幅トリガー信号生成
  ------------------------------------------------------------
  procedure rdtrg_sdmmif_addr_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    constant sdmmout : in sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    signal trg       : out std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;
    --------------------------------------------------

    if (rst = '1') then
      trg <= '0';
    elsif rising_edge(clk) then
      trg <= '0';
      if sdmmin.rd = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
        trg <= '1';
      end if;
    end if;
  end procedure;

  ------------------------------------------------------------
  -- 指定アドレス書き込みによる1クロック幅トリガー信号生成
  ------------------------------------------------------------
  procedure wrtrg_sdmmif_addr_proc (
    signal clk       : in std_logic;
    signal rst       : in std_logic;
    constant sdmmin  : in sdmmif_sin_r;
    constant sdmmout : in sdmmif_sout_r;
    constant addr    : in std_logic_vector;
    signal trg       : out std_logic
  ) is
    variable err_addr : std_logic_vector(to_integer(unsigned(addr)) - 1 downto 0);
    variable err_code : std_logic_vector(2 downto 0);
  begin
    --------------------------------------------------
    -- 引き数のエラーチェック: エラーの起きた呼び出し元のprocedureはトリッキーコードで表示する(Vivado対応)。
    -- 論理合成時はassertが想定通りに機能しない実装系が多いので、VHDLの「ビット長が異なるstd_logic_vectorへの代入はエラーとなる」ことを利用してエラーを出す。
    -- トリッキーコード:Vivadoの場合、どのprocedureの呼び出しでエラーとなったかが表示されないため、addrの数値をビット長に埋め込んでエラー表示させている。
    -- 結果として、右のようなエラーが出る。これは、アドレスが10進数で308(=0x134)でエラー1が起きたという意味になる。  [Synth 8-690] width mismatch in assignment; target has 308 bits, source has 1 bits
    --------------------------------------------------
    -- 引き数のaddrで示される値が入る最短のビット長がサブモジュールのアドレスのビット長よりも長い場合、エラー 1を出す。
    if unsigned(addr) >= 2**SUB_ADDRESS_BUS_WIDTH then
      err_addr := err_code(0 downto 0); -- エラーコード 1 = アドレスの値が指定のビット長に収まらない。
    end if;
    --------------------------------------------------

    if (rst = '1') then
      trg <= '0';
    elsif rising_edge(clk) then
      trg <= '0';
      if sdmmin.wr = '1' and unsigned(sdmmin.addr) = unsigned(addr) then
        trg <= '1';
      end if;
    end if;
  end procedure;
end package body;
