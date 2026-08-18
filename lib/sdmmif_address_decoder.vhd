--------------------------------------------------------------------------------
-- sdmmif_address_decoder.vhd
-- simplified description library for memory-mapped interface - address decoder
--
-- Copyright (c) 2026 niwaniniwawani
-- This software is released under the MIT License, see LICENSE.
--------------------------------------------------------------------------------
-- メモリーマップトインターフェイスの記述を簡素化するライブラリー - アドレスデコーダー
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sdmmif.all;

entity sdmmif_address_decoder is
  generic (
    SUBMODULE_ADDR : a_sdmmif_addresses_t
  );
  port (
    sdmmif_mout : in sdmmif_mout_r;
    sdmmif_min  : out sdmmif_min_r;

    a_sdmmin  : out a_sdmmif_sin_r(0 to SUBMODULE_ADDR'LENGTH - 1);
    a_sdmmout : in a_sdmmif_sout_r(0 to SUBMODULE_ADDR'LENGTH - 1)
  );
end entity;

architecture RTL of sdmmif_address_decoder is
begin
  -- rd のバス接続(非同期)
  connect_rd_generate : for m in SUBMODULE_ADDR'range generate
    a_sdmmin(m).rd <= sdmmif_mout.rd when sdmmif_mout.addr(sdmmif_module_addr_st'range) = SUBMODULE_ADDR(m)(sdmmif_module_addr_st'range) else '0';
  end generate;

  -- wr のバス接続(非同期)
  connect_wr_generate : for m in SUBMODULE_ADDR'range generate
    a_sdmmin(m).wr <= sdmmif_mout.wr when sdmmif_mout.addr(sdmmif_module_addr_st'range) = SUBMODULE_ADDR(m)(sdmmif_module_addr_st'range) else '0';
  end generate;

  -- rddata のバス接続(非同期)
  process (sdmmif_mout, a_sdmmout) begin
    sdmmif_min.rddata <= (others => '0');

    connect_rddata_loop : for m in SUBMODULE_ADDR'range loop
      if sdmmif_mout.addr(sdmmif_module_addr_st'range) = SUBMODULE_ADDR(m)(sdmmif_module_addr_st'range) and sdmmif_mout.rd = '1' then
        sdmmif_min.rddata <= a_sdmmout(m).rddata;
      end if;
    end loop;
  end process;

  -- wrdata のバス接続(非同期)
  connect_wrdata_generate : for m in SUBMODULE_ADDR'range generate
    a_sdmmin(m).wrdata <= sdmmif_mout.wrdata;
  end generate;

  -- addr の接続(非同期)
  connect_addr_generate : for m in SUBMODULE_ADDR'range generate
    a_sdmmin(m).addr <= sdmmif_mout.addr(sdmmif_sub_addr_st'range);
  end generate;
end architecture;
