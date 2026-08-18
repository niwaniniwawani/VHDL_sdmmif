--------------------------------------------------------------------------------
-- sub_1.vhd
-- simplified description library for memory-mapped interface - example code of sdmmif sub module
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリーを使用したサブモジュールの例 その1
--------------------------------------------------------------------------------
-- package sub_1_inout
--
-- サブモジュールがFPGAのGPIOピンに接続する信号を記述する
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

-- sub_1 モジュールの入出力ポートのレコード型定義
package sub_1_inout is
  -- XX_pin_r は FPGA の入力ピンに接続する信号を記載する
  type sub_1_pin_r is record
    miso : std_logic;
  end record;

  -- XX_pout_r は FPGA の出力ピンに接続する信号を記載する
  type sub_1_pout_r is record
    sclk : std_logic;
    cs_n : std_logic;
    mosi : std_logic;
  end record;
end package;
--------------------------------------------------------------------------------
-- entity sub_1
--
-- サブモジュールの例 その1 の本体
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sdmmif.all; -- sdmmif_sin_r, sdmmif_sout_r の定義を読み込む
use work.sub_1_inout.all; -- sub_1_pin_r, sub_1_pout_r の定義を読み込む

entity sub_1 is
  port (
    clk : in std_logic;
    rst : in std_logic;

    sdmmin  : in sdmmif_sin_r;
    sdmmout : out sdmmif_sout_r;

    pin  : in sub_1_pin_r;
    pout : out sub_1_pout_r
  );
end entity;

architecture RTL of sub_1 is
  signal data_out  : std_logic_vector(7 downto 0);
  signal data_in   : std_logic_vector(7 downto 0);
  signal start_trg : std_logic;

  function numof_bits (x : natural) return natural is
    variable temp          : natural := 1;
    variable count         : natural := 0;
  begin
    while temp <= x loop
      temp  := temp * 2;
      count := count + 1;
    end loop;
    return count;
  end function;
begin
  -- レジスターアクセス
  process (all) begin -- process(all) : VHDL-2008
    clr_sdmmif_rddata_proc(clk, rst, sdmmin, sdmmout);

    wr_cmp_match_sdmmif_1bit_proc(clk, rst, sdmmin, sdmmout, X"010", 0, '1', start_trg);
    rw_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"012", 7, 0, x"A5", data_out);
    ro_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"014", 7, 0, data_in);
  end process;

  -- start_trgのトリガーがかかることを示すために、トリガーがかかったらサンプルとしてSPI通信を行うようにしてあるが、
  -- SPI通信はこのサンプルコードの主題ではないので、単にAIが生成したコードを貼り付けた。
  spi_block           : block
    constant CLK_DIV    : natural := 40;
    constant BIT_LENGTH : natural := 8;

    signal running     : std_logic;
    signal clk_div_cnt : unsigned(numof_bits(CLK_DIV * 2) - 1 downto 0); -- integerを合成に使用したくない場合の回避方法(大抵はintegerを使っても合成できるが)
    signal bit_cnt     : unsigned(numof_bits(BIT_LENGTH) - 1 downto 0); -- integerを合成に使用したくない場合の回避方法(大抵はintegerを使っても合成できるが)
    signal mosi_shift  : std_logic_vector(BIT_LENGTH - 1 downto 0);
    signal miso_shift  : std_logic_vector(BIT_LENGTH - 1 downto 0);
  begin
    process (clk, rst) begin
      if rst = '1' then
        pout.sclk   <= '0';
        running     <= '0';
        clk_div_cnt <= (others => '0');
        mosi_shift  <= (others => '0');
      elsif rising_edge(clk) then
        if start_trg = '1' and running = '0' then -- 通信開始
          running     <= '1';
          mosi_shift  <= data_out;
          bit_cnt     <= (others => '0');
          pout.sclk   <= '0';
          clk_div_cnt <= (others => '0');
        end if;

        if running = '1' then
          if clk_div_cnt = CLK_DIV - 1 then -- クロック分周
            clk_div_cnt <= (others => '0');
            pout.sclk   <= not pout.sclk; -- VHDL-2008

            if pout.sclk = '0' then -- 立ち上がりで MISO を取り込む(Mode 0)
              miso_shift(7 downto 0) <= miso_shift(BIT_LENGTH - 2 downto 0) & pin.miso;
            else -- 立ち下がりで MOSI を更新
              if bit_cnt = BIT_LENGTH - 1 then
                running <= '0'; -- 完了
                data_in <= miso_shift;
              else
                bit_cnt <= bit_cnt + 1;
              end if;
              mosi_shift <= mosi_shift(BIT_LENGTH - 2 downto 0) & '0';
            end if;
          else
            clk_div_cnt <= clk_div_cnt + 1;
          end if;
        end if;
      end if;
    end process;
    pout.mosi <= mosi_shift(BIT_LENGTH - 1);
    pout.cs_n <= not running;
  end block;
end architecture;
