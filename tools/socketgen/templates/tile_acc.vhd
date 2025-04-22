-- Copyright (c) 2011-2024 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

-----------------------------------------------------------------------------
--  Accelerator Tile
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;
use work.gencomp.all;
use work.monitor_pkg.all;
use work.esp_csr_pkg.all;
use work.misc.all;
use work.jtag_pkg.all;
use work.sldacc.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.tile.all;
use work.coretypes.all;
use work.esp_acc_regmap.all;
use work.socmap.all;
use work.grlib_config.all;

entity tile_acc is
  generic (
    this_hls_conf      : hlscfg_t             := 0;
    this_device        : devid_t              := 0;
    this_irq_type      : integer              := 0;
    this_has_l2        : integer range 0 to 1 := 0;
    this_has_dco       : integer range 0 to 2 := 0);
  port (
    raw_rstn           : in  std_ulogic;
    tile_rst           : in  std_ulogic;
    ext_clk            : in  std_ulogic;
    clk_div            : out std_ulogic;
    tile_clk_out       : out std_ulogic;
    tile_rstn_out      : out std_ulogic;
    -- DCO config
    dco_freq_sel       : in std_logic_vector(1 downto 0);
    dco_div_sel        : in std_logic_vector(2 downto 0);
    dco_fc_sel         : in std_logic_vector(5 downto 0);
    dco_cc_sel         : in std_logic_vector(5 downto 0);
    dco_clk_sel        : in std_ulogic;
    dco_en             : in std_ulogic;
    -- NOC
    test1_output_port   : in coh_noc_flit_type;
    test1_data_void_out : in std_ulogic;
    test1_stop_in       : in std_ulogic;
    test2_output_port   : in coh_noc_flit_type;
    test2_data_void_out : in std_ulogic;
    test2_stop_in       : in std_ulogic;
    test3_output_port   : in coh_noc_flit_type;
    test3_data_void_out : in std_ulogic;
    test3_stop_in       : in std_ulogic;
    test4_output_port   : in dma_noc_flit_type;
    test4_data_void_out : in std_ulogic;
    test4_stop_in       : in std_ulogic;
    test5_output_port   : in misc_noc_flit_type;
    test5_data_void_out : in std_ulogic;
    test5_stop_in       : in std_ulogic;
    test6_output_port   : in dma_noc_flit_type;
    test6_data_void_out : in std_ulogic;
    test6_stop_in       : in std_ulogic;
    test1_input_port    : out coh_noc_flit_type;
    test1_data_void_in  : out std_ulogic;
    test1_stop_out      : out std_ulogic;
    test2_input_port    : out coh_noc_flit_type;
    test2_data_void_in  : out std_ulogic;
    test2_stop_out      : out std_ulogic;
    test3_input_port    : out coh_noc_flit_type;
    test3_data_void_in  : out std_ulogic;
    test3_stop_out      : out std_ulogic;
    test4_input_port    : out dma_noc_flit_type;
    test4_data_void_in  : out std_ulogic;
    test4_stop_out      : out std_ulogic;
    test5_input_port    : out misc_noc_flit_type;
    test5_data_void_in  : out std_ulogic;
    test5_stop_out      : out std_ulogic;
    test6_input_port    : out dma_noc_flit_type;
    test6_data_void_in  : out std_ulogic;
    test6_stop_out      : out std_ulogic;
    --Monitor signals
    mon_noc             : in  monitor_noc_vector(1 to 6);
    mon_acc             : out monitor_acc_type;
    mon_cache           : out monitor_cache_type;
    mon_dvfs            : out monitor_dvfs_type;
	acc_activity		: out std_ulogic
    );

end;

architecture rtl of tile_acc is

  -- Tile synchronous reset
  signal rst          : std_ulogic;

  -- DCO
  signal tile_clk     : std_ulogic;
  signal dco_clk      : std_ulogic;
  signal dco_clk_lock : std_ulogic;
  signal dco_en_int   : std_ulogic;

  -- BUS
  signal apbi           : apb_slv_in_type;
  signal apbo           : apb_slv_out_vector;
  signal pready         : std_ulogic;
  signal pready_noc     : std_ulogic;
  signal mon_dvfs_int   : monitor_dvfs_type;
  signal mon_cache_int  : monitor_cache_type;
  signal mon_acc_int    : monitor_acc_type;

  signal coherence_req_wrreq        : std_ulogic;
  signal coherence_req_data_in      : coh_noc_flit_type;
  signal coherence_req_full         : std_ulogic;
  signal coherence_fwd_rdreq        : std_ulogic;
  signal coherence_fwd_data_out     : coh_noc_flit_type;
  signal coherence_fwd_empty        : std_ulogic;
  signal coherence_rsp_rcv_rdreq    : std_ulogic;
  signal coherence_rsp_rcv_data_out : coh_noc_flit_type;
  signal coherence_rsp_rcv_empty    : std_ulogic;
  signal coherence_rsp_snd_wrreq    : std_ulogic;
  signal coherence_rsp_snd_data_in  : coh_noc_flit_type;
  signal coherence_rsp_snd_full     : std_ulogic;
  signal coherence_fwd_snd_wrreq    : std_ulogic;
  signal coherence_fwd_snd_data_in  : coh_noc_flit_type;
  signal coherence_fwd_snd_full     : std_ulogic;
  signal dma_rcv_rdreq              : std_ulogic;
  signal dma_rcv_data_out           : dma_noc_flit_type;
  signal dma_rcv_empty              : std_ulogic;
  signal dma_snd_wrreq              : std_ulogic;
  signal dma_snd_data_in            : dma_noc_flit_type;
  signal dma_snd_full               : std_ulogic;
  signal coherent_dma_rcv_rdreq     : std_ulogic;
  signal coherent_dma_rcv_data_out  : dma_noc_flit_type;
  signal coherent_dma_rcv_empty     : std_ulogic;
  signal coherent_dma_snd_wrreq     : std_ulogic;
  signal coherent_dma_snd_data_in   : dma_noc_flit_type;
  signal coherent_dma_snd_full      : std_ulogic;
  signal interrupt_wrreq            : std_ulogic;
  signal interrupt_data_in          : misc_noc_flit_type;
  signal interrupt_full             : std_ulogic;
  signal interrupt_ack_rdreq        : std_ulogic;
  signal interrupt_ack_data_out     : misc_noc_flit_type;
  signal interrupt_ack_empty        : std_ulogic;
  signal apb_snd_wrreq              : std_ulogic;
  signal apb_snd_data_in            : misc_noc_flit_type;
  signal apb_snd_full               : std_ulogic;
  signal apb_rcv_rdreq              : std_ulogic;
  signal apb_rcv_data_out           : misc_noc_flit_type;
  signal apb_rcv_empty              : std_ulogic;

  -- Tile parameters
  signal tile_config : std_logic_vector(ESP_CSR_WIDTH - 1 downto 0);

  signal tile_id : integer range 0 to CFG_TILES_NUM - 1;

  signal this_pindex    : integer range 0 to NAPBSLV - 1;
  signal this_paddr     : integer range 0 to 4095;
  signal this_pmask     : integer range 0 to 4095;
  signal this_paddr_ext : integer range 0 to 4095;
  signal this_pmask_ext : integer range 0 to 4095;
  signal this_pirq      : integer range 0 to NAHBIRQ - 1;

  signal this_csr_pindex        : integer range 0 to NAPBSLV - 1;
  signal this_csr_pconfig       : apb_config_type;

  signal this_local_y : local_yx;
  signal this_local_x : local_yx;

  signal tp_acc_rst : std_ulogic;

  constant this_local_apb_en : std_logic_vector(0 to NAPBSLV - 1) := (
    0 => '1',                           -- CSRs
    1 => '1',                           -- ESP accelerator w/ DVFS controller
    others => '0');

  constant io_y                : local_yx                           := tile_y(io_tile_id);
  constant io_x                : local_yx                           := tile_x(io_tile_id);
  constant this_scatter_gather : integer range 0 to 1               := CFG_SCATTER_GATHER;

  constant little_end          : integer range 0 to 1               := GLOB_CPU_RISCV;

  signal coherence : integer range 0 to 3;

  -- add attribute 'keep' to fix a bug with Vivado HLS accelerators
  attribute keep : string;

  attribute keep of coherence_req_wrreq        : signal is "true";
  attribute keep of coherence_req_data_in      : signal is "true";
  attribute keep of coherence_req_full         : signal is "true";
  attribute keep of coherence_fwd_rdreq        : signal is "true";
  attribute keep of coherence_fwd_data_out     : signal is "true";
  attribute keep of coherence_fwd_empty        : signal is "true";
  attribute keep of coherence_rsp_rcv_rdreq    : signal is "true";
  attribute keep of coherence_rsp_rcv_data_out : signal is "true";
  attribute keep of coherence_rsp_rcv_empty    : signal is "true";
  attribute keep of coherence_rsp_snd_wrreq    : signal is "true";
  attribute keep of coherence_rsp_snd_data_in  : signal is "true";
  attribute keep of coherence_rsp_snd_full     : signal is "true";
  attribute keep of dma_rcv_rdreq              : signal is "true";
  attribute keep of dma_rcv_data_out           : signal is "true";
  attribute keep of dma_rcv_empty              : signal is "true";
  attribute keep of dma_snd_wrreq              : signal is "true";
  attribute keep of dma_snd_data_in            : signal is "true";
  attribute keep of dma_snd_full               : signal is "true";
  attribute keep of coherent_dma_rcv_rdreq     : signal is "true";
  attribute keep of coherent_dma_rcv_data_out  : signal is "true";
  attribute keep of coherent_dma_rcv_empty     : signal is "true";
  attribute keep of coherent_dma_snd_wrreq     : signal is "true";
  attribute keep of coherent_dma_snd_data_in   : signal is "true";
  attribute keep of coherent_dma_snd_full      : signal is "true";
  attribute keep of interrupt_wrreq            : signal is "true";
  attribute keep of interrupt_data_in          : signal is "true";
  attribute keep of interrupt_full             : signal is "true";
  attribute keep of interrupt_ack_rdreq        : signal is "true";
  attribute keep of interrupt_ack_data_out     : signal is "true";
  attribute keep of interrupt_ack_empty        : signal is "true";
  attribute keep of apb_snd_wrreq              : signal is "true";
  attribute keep of apb_snd_data_in            : signal is "true";
  attribute keep of apb_snd_full               : signal is "true";
  attribute keep of apb_rcv_rdreq              : signal is "true";
  attribute keep of apb_rcv_data_out           : signal is "true";
  attribute keep of apb_rcv_empty              : signal is "true";
  
begin

  -- DCO Reset synchronizer
  rst_gen: if this_has_dco = 1 generate
    tile_rstn_out : rstgen
      generic map (acthigh => 1, syncin => 0)
      port map (tile_rst, dco_clk, dco_clk_lock, rst, open);
  end generate rst_gen;

  no_rst_gen: if this_has_dco /= 1 generate
    rst <= tile_rst;
  end generate no_rst_gen;

  tile_rstn_out <= rst;

  -- DCO
  dco_en_int <= dco_en and raw_rstn;
  dco_gen: if this_has_dco = 1 generate

    dco_i: dco
      generic map (
        tech => CFG_FABTECH,
        enable_div2 => 0,
        dlog => 9)                      -- come out of reset after NoC, but
                                        -- before tile_io.
      port map (
        rstn     => raw_rstn,
        ext_clk  => ext_clk,
        en       => dco_en_int,
        clk_sel  => dco_clk_sel,
        cc_sel   => dco_cc_sel,
        fc_sel   => dco_fc_sel,
        div_sel  => dco_div_sel,
        freq_sel => dco_freq_sel,
        clk      => dco_clk,
        clk_div  => clk_div,
        lock     => dco_clk_lock);

    tile_clk <= dco_clk;
  end generate dco_gen;

  no_dco_gen: if this_has_dco /= 1 generate
    tile_clk     <= ext_clk;
    dco_clk_lock <= '1';
    clk_div <= tile_clk;
  end generate no_dco_gen;

  tile_clk_out <= tile_clk;

  -----------------------------------------------------------------------------
  -- Tile parameters
  -----------------------------------------------------------------------------
  tile_id          <= to_integer(unsigned(tile_config(ESP_CSR_TILE_ID_MSB downto ESP_CSR_TILE_ID_LSB)));

  this_pindex      <= tile_apb_idx(tile_id);
  this_paddr       <= tile_apb_paddr(tile_id);
  this_pmask       <= tile_apb_pmask(tile_id);
  this_paddr_ext   <= tile_apb_paddr_ext(tile_id);
  this_pmask_ext   <= tile_apb_pmask_ext(tile_id);
  this_pirq        <= tile_apb_irq(tile_id);

  this_csr_pindex  <= tile_csr_pindex(tile_id);
  this_csr_pconfig <= fixed_apbo_pconfig(this_csr_pindex);

  this_local_y     <= tile_y(tile_id);
  this_local_x     <= tile_x(tile_id);

  coherence        <= to_integer(unsigned(tile_config(ESP_CSR_ACC_COH_MSB downto ESP_CSR_ACC_COH_LSB)));

-------------------------------------------------------------------------------
-- ACCELERATOR ----------------------------------------------------------------
-------------------------------------------------------------------------------

  -- <<accelerator-wrappers-gen>>

  -----------------------------------------------------------------------------
  -- Tile queues
  -----------------------------------------------------------------------------

  -- Using only one apbo signal
  no_apb : for i in 0 to NAPBSLV - 1 generate
    local_apb : if this_local_apb_en(i) = '0' generate
      apbo(i)      <= apb_none;
      apbo(i).pirq <= (others => '0');
    end generate local_apb;
  end generate no_apb;

  -- Connect pready for APB3 accelerators
  pready_gen: process (pready, apbi) is
  begin  -- process pready_gen
    if apbi.psel(1) = '1' then
      pready_noc <= pready;
    else
      pready_noc <= '1';
    end if;
  end process pready_gen;

  -- APB proxy
  noc2apb_1 : noc2apb
    generic map (
      tech         => CFG_FABTECH,
      local_apb_en => this_local_apb_en)
    port map (
      rst              => rst,
      clk              => tile_clk,
      local_y          => this_local_y,
      local_x          => this_local_x,
      apbi             => apbi,
      apbo             => apbo,
      pready           => pready_noc,
      apb_snd_wrreq    => apb_snd_wrreq,
      apb_snd_data_in  => apb_snd_data_in,
      apb_snd_full     => apb_snd_full,
      apb_rcv_rdreq    => apb_rcv_rdreq,
      apb_rcv_data_out => apb_rcv_data_out,
      apb_rcv_empty    => apb_rcv_empty
    );

  --Monitors
  mon_dvfs  <= mon_dvfs_int;
  mon_cache <= mon_cache_int;
  mon_acc   <= mon_acc_int;

  -- Memory mapped registers
  acc_tile_csr : esp_tile_csr
    generic map(
      pindex  => 0)
    port map(
      clk => tile_clk,
      rstn => rst,
      pconfig => this_csr_pconfig,
      mon_ddr => monitor_ddr_none,
      mon_mem => monitor_mem_none,
      mon_noc => mon_noc,
      mon_l2 => mon_cache_int,
      mon_llc => monitor_cache_none,
      mon_acc => mon_acc_int,
      mon_dvfs => mon_dvfs_int,
      tile_config => tile_config,
      srst => open,
      tp_acc_rst => tp_acc_rst,
      apbi => apbi,
      apbo => apbo(0)
    );

  acc_tile_q_1 : acc_tile_q
    generic map (
      tech => CFG_FABTECH)
    port map (
      rst                        => rst,
      clk                        => tile_clk,
      coherence_req_wrreq        => coherence_req_wrreq,
      coherence_req_data_in      => coherence_req_data_in,
      coherence_req_full         => coherence_req_full,
      coherence_fwd_rdreq        => coherence_fwd_rdreq,
      coherence_fwd_data_out     => coherence_fwd_data_out,
      coherence_fwd_empty        => coherence_fwd_empty,
      coherence_rsp_rcv_rdreq    => coherence_rsp_rcv_rdreq,
      coherence_rsp_rcv_data_out => coherence_rsp_rcv_data_out,
      coherence_rsp_rcv_empty    => coherence_rsp_rcv_empty,
      coherence_rsp_snd_wrreq    => coherence_rsp_snd_wrreq,
      coherence_rsp_snd_data_in  => coherence_rsp_snd_data_in,
      coherence_rsp_snd_full     => coherence_rsp_snd_full,
      coherence_fwd_snd_wrreq    => coherence_fwd_snd_wrreq,
      coherence_fwd_snd_data_in  => coherence_fwd_snd_data_in,
      coherence_fwd_snd_full     => coherence_fwd_snd_full,
      dma_rcv_rdreq              => dma_rcv_rdreq,
      dma_rcv_data_out           => dma_rcv_data_out,
      dma_rcv_empty              => dma_rcv_empty,
      coherent_dma_snd_wrreq     => coherent_dma_snd_wrreq,
      coherent_dma_snd_data_in   => coherent_dma_snd_data_in,
      coherent_dma_snd_full      => coherent_dma_snd_full,
      dma_snd_wrreq              => dma_snd_wrreq,
      dma_snd_data_in            => dma_snd_data_in,
      dma_snd_full               => dma_snd_full,
      coherent_dma_rcv_rdreq     => coherent_dma_rcv_rdreq,
      coherent_dma_rcv_data_out  => coherent_dma_rcv_data_out,
      coherent_dma_rcv_empty     => coherent_dma_rcv_empty,
      apb_rcv_rdreq              => apb_rcv_rdreq,
      apb_rcv_data_out           => apb_rcv_data_out,
      apb_rcv_empty              => apb_rcv_empty,
      apb_snd_wrreq              => apb_snd_wrreq,
      apb_snd_data_in            => apb_snd_data_in,
      apb_snd_full               => apb_snd_full,
      interrupt_wrreq            => interrupt_wrreq,
      interrupt_data_in          => interrupt_data_in,
      interrupt_full             => interrupt_full,
      interrupt_ack_rdreq        => interrupt_ack_rdreq,
      interrupt_ack_data_out     => interrupt_ack_data_out,
      interrupt_ack_empty        => interrupt_ack_empty,
      noc1_out_data              => test1_output_port,
      noc1_out_void              => test1_data_void_out,
      noc1_out_stop              => test1_stop_out,
      noc1_in_data               => test1_input_port,
      noc1_in_void               => test1_data_void_in,
      noc1_in_stop               => test1_stop_in,
      noc2_out_data              => test2_output_port,
      noc2_out_void              => test2_data_void_out,
      noc2_out_stop              => test2_stop_out,
      noc2_in_data               => test2_input_port,
      noc2_in_void               => test2_data_void_in,
      noc2_in_stop               => test2_stop_in,
      noc3_out_data              => test3_output_port,
      noc3_out_void              => test3_data_void_out,
      noc3_out_stop              => test3_stop_out,
      noc3_in_data               => test3_input_port,
      noc3_in_void               => test3_data_void_in,
      noc3_in_stop               => test3_stop_in,
      noc4_out_data              => test4_output_port,
      noc4_out_void              => test4_data_void_out,
      noc4_out_stop              => test4_stop_out,
      noc4_in_data               => test4_input_port,
      noc4_in_void               => test4_data_void_in,
      noc4_in_stop               => test4_stop_in,
      noc5_out_data              => test5_output_port,
      noc5_out_void              => test5_data_void_out,
      noc5_out_stop              => test5_stop_out,
      noc5_in_data               => test5_input_port,
      noc5_in_void               => test5_data_void_in,
      noc5_in_stop               => test5_stop_in,
      noc6_out_data              => test6_output_port,
      noc6_out_void              => test6_data_void_out,
      noc6_out_stop              => test6_stop_out,
      noc6_in_data               => test6_input_port,
      noc6_in_void               => test6_data_void_in,
      noc6_in_stop               => test6_stop_in);

end;
