# VHDL_sdmmif
(VHDL) simplified description library for memory-mapped interface

## 概要
VHDLの記述は上下方向に長くなりがちで、コードの構造が見辛くなりがちです。
それを少しでも改善すべく、メモリーマップトインターフェイスを簡潔に記述できるライブラリーを作ってみました。

- このライブラリーを使うと、メモリーマップトインターフェイスはどのように記述できるの?
```VHDL
  signal data_out  : std_logic_vector(7 downto 0);
  signal data_in   : std_logic_vector(7 downto 0);
  signal start_trg : std_logic;
```
のような信号に対して、サブモジュールでこれらの信号にアクセスするコードは以下のような記述になります。
```VHDL
  -- レジスターアクセス
  process (all) begin -- process(all) : VHDL-2008
    clr_sdmmif_rddata_proc(clk, rst, sdmmin, sdmmout);

    wr_cmp_match_sdmmif_1bit_proc(clk, rst, sdmmin, sdmmout, X"010", 0, '1', start_trg);
    rw_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"012", 7, 0, x"A5", data_out);
    ro_sdmmif_bits_proc(clk, rst, sdmmin, sdmmout, X"14", 7, 0, data_in);
  end process;
```
上記は、
1. サブモジュールのアドレス0x010の0ビット目に'1'を書くと、start_trgが1クロックだけ立ち上がる。
2. サブモジュールのアドレス0x012の7〜0ビット目ではdata_outに読み書きできる。data_outはリセット時に0xA5で初期化される。
3. サブモジュールのアドレス0x012の7〜0ビット目ではdata_inの値を読み込める。
という記述になります。
VHDLに見えないコードかと思いますが、VHDLの文法に適合しており、論理合成もシミュレーションも可能です。

特長としては、
1. 読み書きおよび初期化を1行のコードで記述できる。(アドレスを変えるには、行内のアドレスを変えればよい。)
2. 記述がほぼレジスターマップなので、他に余計な定義は不要。例えば、レジスターのアドレスはこの行にしか出てこなくできるので、別途アドレス値をconstantで定義する必要がない。
3. 「読み出しは非同期アクセス、書き込みは同期アクセス」が1行で記述できる。(Avalon-MMはそのように記述したい場合が多いはず。)
4. アドレスの書き方が自由。サブモジュールのアドレス幅以内であれば、x"012"と書いてもよいしx"12"と書いてもよい。アドレス幅を越えたら(トリッキーな方法だが)エラーとなる。
といった感じです。

なお、現状では、Quartus Prime Lite 25.1とVivado 2025.2で動作確認しています。

## 使い方
- libにあるsdmmif.vhdとsdmmif_address_decoder.vhdをQuartus/Vivadoのプロジェクトに入れてください。
- そして、exampleにあるsdmmif_type.vhdに記述されたバス幅を適宜修正してプロジェクトに追加してください。
- バスアクセスのメイン側のモジュールの例がexampleのsdmmif_top.vhd、
  バスアクセスのサブ側のモジュールの例がexampleのsub_1.vhd、sub_2.vhdになります。
- 簡単なテストベンチがtb/sdmmif_tb.vhdに置いてあります。

