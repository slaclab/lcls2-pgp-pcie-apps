-------------------------------------------------------------------------------
-- File       : Lcls2XilinxKcu1500Pgp4_6Gbps_ddr.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Camera link gateway PCIe card with PGPv2b
-------------------------------------------------------------------------------
-- This file is part of 'Camera link gateway'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'Camera link gateway', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.Pgp4Pkg.all;

library lcls2_pgp_fw_lib;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;
use axi_pcie_core.MigPkg.all;

library daq_stream_cache;

library unisim;
use unisim.vcomponents.all;

entity Lcls2XilinxKcu1500Pgp4_6Gbps_ddr is
   generic (
      TPD_G          : time    := 1 ns;
      ROGUE_SIM_EN_G : boolean := false;
      PGP_TYPE_G     : string  := "PGP4";
      RATE_G         : string  := "6.25Gbps";
      BUILD_INFO_G   : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in    slv(1 downto 0);
      qsfp0RefClkN : in    slv(1 downto 0);
      qsfp0RxP     : in    slv(3 downto 0);
      qsfp0RxN     : in    slv(3 downto 0);
      qsfp0TxP     : out   slv(3 downto 0);
      qsfp0TxN     : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in    slv(1 downto 0);
      qsfp1RefClkN : in    slv(1 downto 0);
      qsfp1RxP     : in    slv(3 downto 0);
      qsfp1RxN     : in    slv(3 downto 0);
      qsfp1TxP     : out   slv(3 downto 0);
      qsfp1TxN     : out   slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in    sl;
      userClkP     : in    sl;
      userClkN     : in    sl;
      i2cRstL      : out   sl;
      i2cScl       : inout sl;
      i2cSda       : inout sl;
      -- QSFP[0] Ports
      qsfp0RstL    : out   sl;
      qsfp0LpMode  : out   sl;
      qsfp0ModSelL : out   sl;
      qsfp0ModPrsL : in    sl;
      -- QSFP[1] Ports
      qsfp1RstL    : out   sl;
      qsfp1LpMode  : out   sl;
      qsfp1ModSelL : out   sl;
      qsfp1ModPrsL : in    sl;
      -- Boot Memory Ports
      flashCsL     : out   sl;
      flashMosi    : out   sl;
      flashMiso    : in    sl;
      flashHoldL   : out   sl;
      flashWp      : out   sl;
      -- DDR Ports
      ddrClkP      : in    slv          (1 downto 0);
      ddrClkN      : in    slv          (1 downto 0);
      ddrOut       : out   DdrOutArray  (1 downto 0);
      ddrInOut     : inout DdrInOutArray(1 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0));
end Lcls2XilinxKcu1500Pgp4_6Gbps_ddr;

architecture top_level of Lcls2XilinxKcu1500Pgp4_6Gbps_ddr is

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  -- 64-bit interface
   constant AXIL_CLK_FREQ_C   : real                := 156.25E+6;  -- units of Hz
   constant NUM_LANES_C       : positive            := 4;
   constant DMA_SIZE_C        : positive            := NUM_LANES_C+1;

   constant NUM_AXIL_MASTERS_C : positive := 3;

   constant HW_INDEX_C  : natural := 0;
   constant APP_INDEX_C : natural := 1;
   constant CA_INDEX_C  : natural := 2;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
     HW_INDEX_C  => ( baseAddr     => x"0080_0000",
                      addrBits     => 22,
                      connectivity => x"FFFF" ),
     APP_INDEX_C => ( baseAddr     => x"00C0_0000",
                      addrBits     => 22,
                      connectivity => x"FFFF" ),
     CA_INDEX_C  => ( baseAddr     => x"0010_0000",
                      addrBits     => 20,
                      connectivity => x"FFFF" ) );

   signal userClk156 : sl;
   signal userClk25  : sl;
   signal userRst25  : sl;

   signal axilClk          : sl;
   signal axilRst          : sl;
   signal axilReadMaster   : AxiLiteReadMasterType;
   signal axilReadSlave    : AxiLiteReadSlaveType;
   signal axilWriteMaster  : AxiLiteWriteMasterType;
   signal axilWriteSlave   : AxiLiteWriteSlaveType;
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal dmaClk       : sl;
   signal dmaRst       : sl;
   signal dmaObMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal pgpIbMasters : AxiStreamMasterArray(NUM_LANES_C-1 downto 0)     := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpIbSlaves  : AxiStreamSlaveArray(NUM_LANES_C-1 downto 0)      := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpObMasters : AxiStreamQuadMasterArray(NUM_LANES_C-1 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal pgpObSlaves  : AxiStreamQuadSlaveArray(NUM_LANES_C-1 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));

   signal axisClkV      : slv(NUM_LANES_C-1 downto 0);
   signal axisRstV      : slv(NUM_LANES_C-1 downto 0);
   signal axisIbMasters : AxiStreamMasterArray(NUM_LANES_C-1 downto 0)     := (others => AXI_STREAM_MASTER_INIT_C);
   signal axisIbSlaves  : AxiStreamSlaveArray(NUM_LANES_C-1 downto 0)      := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal axisObMasters : AxiStreamMasterArray(NUM_LANES_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal axisObSlaves  : AxiStreamSlaveArray(NUM_LANES_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal eventTrigMsgMasters : AxiStreamMasterArray(NUM_LANES_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal eventTrigMsgSlaves  : AxiStreamSlaveArray(NUM_LANES_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal eventTrigMsgCtrl    : AxiStreamCtrlArray(NUM_LANES_C-1 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);

   signal eventTimingMsgMasters : AxiStreamMasterArray(NUM_LANES_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal eventTimingMsgSlaves  : AxiStreamSlaveArray(NUM_LANES_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal clk200, rst200 : sl;
   
begin

   ---------------------------------------
   -- AXI-Lite and reference 25 MHz clocks
   ---------------------------------------
   U_axilClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         SIMULATION_G      => ROGUE_SIM_EN_G,
         TYPE_G            => "MMCM",
         INPUT_BUFG_G      => true,
         FB_BUFG_G         => false,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 2,
         -- MMCM attributes
         CLKIN_PERIOD_G     => 6.4,      -- 156.25 MHz
         CLKFBOUT_MULT_G    => 8,        -- 1.25GHz = 8 x 156.25 MHz
         CLKOUT0_DIVIDE_F_G => 8.0,      -- 156.25MHz = 1.25GHz/8
         CLKOUT1_DIVIDE_G   => 50)       -- 25MHz = 1.25GHz/50

      port map(
         -- Clock Input
         clkIn     => userClk156,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         clkOut(1) => userClk25,
         -- Reset Outputs
         rstOut(0) => axilRst,
         rstOut(1) => userRst25);

   -----------------------
   -- AXI-PCIE-CORE Module
   -----------------------
   U_Core : entity axi_pcie_core.XilinxKcu1500Core
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_CH_COUNT_G => 4,     -- 4 Virtual Channels per DMA lane
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G           => DMA_SIZE_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         userClk156     => userClk156,
         -- DMA Interfaces
         dmaClk         => dmaClk,
         dmaRst         => dmaRst,
         dmaObMasters   => dmaObMasters,
         dmaObSlaves    => dmaObSlaves,
         dmaIbMasters   => dmaIbMasters,
         dmaIbSlaves    => dmaIbSlaves,
         -- AXI-Lite Interface
         appClk         => axilClk,
         appRst         => axilRst,
         appReadMaster  => axilReadMaster,
         appReadSlave   => axilReadSlave,
         appWriteMaster => axilWriteMaster,
         appWriteSlave  => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- System Ports
         emcClk         => emcClk,
         userClkP       => userClkP,
         userClkN       => userClkN,
         i2cRstL        => i2cRstL,
         i2cScl         => i2cScl,
         i2cSda         => i2cSda,
         -- QSFP[0] Ports
         qsfp0RstL      => qsfp0RstL,
         qsfp0LpMode    => qsfp0LpMode,
         qsfp0ModSelL   => qsfp0ModSelL,
         qsfp0ModPrsL   => qsfp0ModPrsL,
         -- QSFP[1] Ports
         qsfp1RstL      => qsfp1RstL,
         qsfp1LpMode    => qsfp1LpMode,
         qsfp1ModSelL   => qsfp1ModSelL,
         qsfp1ModPrsL   => qsfp1ModPrsL,
         -- Boot Memory Ports
         flashCsL       => flashCsL,
         flashMosi      => flashMosi,
         flashMiso      => flashMiso,
         flashHoldL     => flashHoldL,
         flashWp        => flashWp,
         -- PCIe Ports
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   U_App : entity lcls2_pgp_fw_lib.Application
      generic map (
         TPD_G             => TPD_G,
         AXI_BASE_ADDR_G   => AXIL_CONFIG_C(APP_INDEX_C).baseAddr,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => NUM_LANES_C)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk               => axilClk,
         axilRst               => axilRst,
         axilReadMaster        => axilReadMasters(APP_INDEX_C),
         axilReadSlave         => axilReadSlaves(APP_INDEX_C),
         axilWriteMaster       => axilWriteMasters(APP_INDEX_C),
         axilWriteSlave        => axilWriteSlaves(APP_INDEX_C),
         -- PGP Streams (axilClk domain)
         pgpIbMasters          => pgpIbMasters,
         pgpIbSlaves           => pgpIbSlaves,
         pgpObMasters          => pgpObMasters,
         pgpObSlaves           => pgpObSlaves,
         -- Trigger Event streams (axilClk domain)
         eventTrigMsgMasters   => eventTrigMsgMasters,
         eventTrigMsgSlaves    => eventTrigMsgSlaves,
         -- eventTrigMsgCtrl      => eventTrigMsgCtrl, -- Using daq_stream_cache.StreamCache for flow control
         eventTimingMsgMasters => eventTimingMsgMasters,
         eventTimingMsgSlaves  => eventTimingMsgSlaves,
         -- DMA Interface (axilClk domain)
         dmaClk                => axilClk,
         dmaRst                => axilRst,
         dmaObMasters          => axisObMasters,
         dmaObSlaves           => axisObSlaves,
         dmaIbMasters          => axisIbMasters,
         dmaIbSlaves           => axisIbSlaves );

   axisClkV <= (others=>axilClk);
   axisRstV <= (others=>axilRst);
   
   U_Cache : entity daq_stream_cache.StreamCache
     generic map (
       TPD_G             => TPD_G,
       AXI_BASE_ADDR_G   => AXIL_CONFIG_C(CA_INDEX_C).baseAddr,
       APP_AXIS_CONFIG_G => PGP4_AXIS_CONFIG_C,
       DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
       NUM_LANES_G       => NUM_LANES_C )
     port map (
         axilClk               => axilClk,
         axilRst               => axilRst,
         axilReadMaster        => axilReadMasters(CA_INDEX_C),
         axilReadSlave         => axilReadSlaves(CA_INDEX_C),
         axilWriteMaster       => axilWriteMasters(CA_INDEX_C),
         axilWriteSlave        => axilWriteSlaves(CA_INDEX_C),
         -- Trigger Event streams (axilClk domain)
         eventTrigMsgCtrl      => eventTrigMsgCtrl,
         -- PGP Streams (axilClk domain)
         appClk                => axisClkV,
         appRst                => axisRstV,
         appIbMasters          => axisIbMasters,
         appIbSlaves           => axisIbSlaves,
         appObMasters          => axisObMasters,
         appObSlaves           => axisObSlaves,
         -- DMA Interface (dmaClk domain)
         dmaClk                => dmaClk,
         dmaRst                => dmaRst,
         dmaObMasters          => dmaObMasters,
         dmaObSlaves           => dmaObSlaves,
         dmaIbMasters          => dmaIbMasters,
         dmaIbSlaves           => dmaIbSlaves,
         -- DDR Ports
         ddrClkP               => ddrClkP,
         ddrClkN               => ddrClkN,
         ddrOut                => ddrOut,
         ddrInOut              => ddrInOut
       );
   
   ------------------
   -- Hardware Module
   ------------------
   U_HSIO : entity lcls2_pgp_fw_lib.Kcu1500Hsio
      generic map (
         TPD_G               => TPD_G,
         ROGUE_SIM_EN_G      => ROGUE_SIM_EN_G,
         PGP_TYPE_G          => PGP_TYPE_G,
         RATE_G              => RATE_G,
         DMA_AXIS_CONFIG_G   => DMA_AXIS_CONFIG_C,
         AXIL_CLK_FREQ_G     => AXIL_CLK_FREQ_C,
         AXI_BASE_ADDR_G     => AXIL_CONFIG_C(HW_INDEX_C).baseAddr,
         EN_LCLS_I_TIMING_G  => true,
         EN_LCLS_II_TIMING_G => true)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- Reference Clock and Reset
         userClk156            => userClk156,
         userClk25             => userClk25,
         userRst25             => userRst25,
         -- AXI-Lite Interface (axilClk domain)
         axilClk               => axilClk,
         axilRst               => axilRst,
         axilReadMaster        => axilReadMasters(HW_INDEX_C),
         axilReadSlave         => axilReadSlaves(HW_INDEX_C),
         axilWriteMaster       => axilWriteMasters(HW_INDEX_C),
         axilWriteSlave        => axilWriteSlaves(HW_INDEX_C),
         -- PGP Streams (axilClk domain)
         pgpIbMasters          => pgpIbMasters,
         pgpIbSlaves           => pgpIbSlaves,
         pgpObMasters          => pgpObMasters,
         pgpObSlaves           => pgpObSlaves,
         -- Trigger / event interfaces
         triggerClk            => axilClk,
         triggerRst            => axilRst,
         triggerData           => open,
         eventClk              => axilClk,
         eventRst              => axilRst,
         eventTrigMsgMasters   => eventTrigMsgMasters,
         eventTrigMsgSlaves    => eventTrigMsgSlaves,
         eventTrigMsgCtrl      => eventTrigMsgCtrl,
         eventTimingMsgMasters => eventTimingMsgMasters,
         eventTimingMsgSlaves  => eventTimingMsgSlaves,
         ------------------
         --  Hardware Ports
         ------------------
         -- QSFP[0] Ports,
         qsfp0RefClkP          => qsfp0RefClkP,
         qsfp0RefClkN          => qsfp0RefClkN,
         qsfp0RxP              => qsfp0RxP,
         qsfp0RxN              => qsfp0RxN,
         qsfp0TxP              => qsfp0TxP,
         qsfp0TxN              => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP          => qsfp1RefClkP,
         qsfp1RefClkN          => qsfp1RefClkN,
         qsfp1RxP              => qsfp1RxP,
         qsfp1RxN              => qsfp1RxN,
         qsfp1TxP              => qsfp1TxP,
         qsfp1TxN              => qsfp1TxN);

end top_level;
