-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Camera link gateway PCIe card with PGPv4
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

library lcls2_pgp_fw_lib;

library axi_pcie_core;

library unisim;
use unisim.vcomponents.all;

entity Lcls2XilinxC1100Pgp4_6Gbps is
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
      qsfp0RefClkP : in    sl;
      qsfp0RefClkN : in    sl;
      qsfp0RxP     : in    slv(3 downto 0);
      qsfp0RxN     : in    slv(3 downto 0);
      qsfp0TxP     : out   slv(3 downto 0);
      qsfp0TxN     : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in    sl;
      qsfp1RefClkN : in    sl;
      qsfp1RxP     : in    slv(3 downto 0);
      qsfp1RxN     : in    slv(3 downto 0);
      qsfp1TxP     : out   slv(3 downto 0);
      qsfp1TxN     : out   slv(3 downto 0);
      -- HBM Ports
      hbmCatTrip   : out   sl;  -- HBM Catastrophic Over temperature Output signal to Satellite Controller: active HIGH indicator to Satellite controller to indicate the HBM has exceeds its maximum allowable temperature
      --------------
      --  Core Ports
      --------------
      -- System Ports
      userClkP     : in    sl;
      userClkN     : in    sl;
      hbmRefClkP   : in    sl;
      hbmRefClkN   : in    sl;
      -- SI5394 Ports
      si5394Scl    : inout sl;
      si5394Sda    : inout sl;
      si5394IrqL   : in    sl;
      si5394LolL   : in    sl;
      si5394LosL   : in    sl;
      si5394RstL   : out   sl;
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    slv(0 downto 0);
      pciRefClkN   : in    slv(0 downto 0);
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0));
end Lcls2XilinxC1100Pgp4_6Gbps;

architecture top_level of Lcls2XilinxC1100Pgp4_6Gbps is

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  -- 64-bit interface
   constant AXIL_CLK_FREQ_C   : real                := 156.25E+6;  -- units of Hz
   constant DMA_SIZE_C        : positive            := 4;

   constant BUFF_INDEX_C       : natural  := 0;
   constant HW_INDEX_C         : natural  := 1;
   constant APP_INDEX_C        : natural  := 2;
   constant NUM_AXIL_MASTERS_C : positive := 3;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      0               => (
         baseAddr     => x"0010_0000",
         addrBits     => 20,
         connectivity => x"FFFF"),
      1               => (
         baseAddr     => x"0080_0000",
         addrBits     => 22,
         connectivity => x"FFFF"),
      2               => (
         baseAddr     => x"00C0_0000",
         addrBits     => 22,
         connectivity => x"FFFF"));

   signal hbmRefClk  : sl;
   signal userClk    : sl;
   signal userClkBuf : sl;
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

   signal dmaClk        : sl;
   signal dmaRst        : sl;
   signal dmaObMasters  : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves   : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters  : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves   : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal buffIbMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal buffIbSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal pgpIbMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0)     := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpIbSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)      := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpObMasters : AxiStreamQuadMasterArray(DMA_SIZE_C-1 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal pgpObSlaves  : AxiStreamQuadSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));

   signal eventTrigMsgMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal eventTrigMsgSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal eventTrigMsgCtrl    : AxiStreamCtrlArray(DMA_SIZE_C-1 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);

   signal eventTimingMsgMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal eventTimingMsgSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

begin

   U_BUFG : BUFG
      port map (
         I => userClk,
         O => userClkBuf);

   ---------------------------
   -- AXI-Lite clock and Reset
   ---------------------------
   U_axilClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         SIMULATION_G       => ROGUE_SIM_EN_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 10.0,    -- 100MHz
         DIVCLK_DIVIDE_G    => 8,       -- 12.5MHz = 100MHz/8
         CLKFBOUT_MULT_F_G  => 96.875,  -- 1210.9375MHz = 96.875 x 12.5MHz
         CLKOUT0_DIVIDE_F_G => 7.75)    -- 156.25MHz = 1210.9375MHz/7.75
      port map(
         -- Clock Input
         clkIn     => userClkBuf,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   -----------------------------------
   -- Reference 25 MHz clock and Reset
   -----------------------------------
   U_userClk25 : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         SIMULATION_G      => ROGUE_SIM_EN_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G    => 10.0,     -- 100 MHz
         CLKFBOUT_MULT_G   => 10,       -- 1GHz = 10 x 100 MHz
         CLKOUT0_DIVIDE_G  => 40)       -- 25MHz = 1GHz/40
      port map(
         -- Clock Input
         clkIn     => userClkBuf,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => userClk25,
         -- Reset Outputs
         rstOut(0) => userRst25);

   -----------------------
   -- AXI-PCIE-CORE Module
   -----------------------
   U_Core : entity axi_pcie_core.XilinxVariumC1100Core
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
         userClk        => userClk,
         hbmRefClk      => hbmRefClk,
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
         userClkP       => userClkP,
         userClkN       => userClkN,
         hbmRefClkP     => hbmRefClkP,
         hbmRefClkN     => hbmRefClkN,
         -- SI5394 Ports
         si5394Scl      => si5394Scl,
         si5394Sda      => si5394Sda,
         si5394IrqL     => si5394IrqL,
         si5394LolL     => si5394LolL,
         si5394LosL     => si5394LosL,
         si5394RstL     => si5394RstL,
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

   U_HbmDmaBuffer : entity axi_pcie_core.HbmDmaBuffer
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => DMA_SIZE_C,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         AXIL_BASE_ADDR_G  => AXIL_CONFIG_C(BUFF_INDEX_C).baseAddr)
      port map (
         -- HBM Interface
         hbmRefClk        => hbmRefClk,
         hbmCatTrip       => hbmCatTrip,
         -- AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(BUFF_INDEX_C),
         axilReadSlave    => axilReadSlaves(BUFF_INDEX_C),
         axilWriteMaster  => axilWriteMasters(BUFF_INDEX_C),
         axilWriteSlave   => axilWriteSlaves(BUFF_INDEX_C),
         -- Trigger Event streams (eventClk domain)
         eventClk         => axilClk,
         eventTrigMsgCtrl => eventTrigMsgCtrl,
         -- AXI Stream Interface (axisClk domain)
         axisClk          => dmaClk,
         axisRst          => dmaRst,
         sAxisMasters     => buffIbMasters,
         sAxisSlaves      => buffIbSlaves,
         mAxisMasters     => dmaIbMasters,
         mAxisSlaves      => dmaIbSlaves);

   U_App : entity lcls2_pgp_fw_lib.Application
      generic map (
         TPD_G             => TPD_G,
         AXI_BASE_ADDR_G   => AXIL_CONFIG_C(APP_INDEX_C).baseAddr,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_C)
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
         eventTrigMsgCtrl      => open,
         eventTimingMsgMasters => eventTimingMsgMasters,
         eventTimingMsgSlaves  => eventTimingMsgSlaves,
         -- DMA Interface (dmaClk domain)
         dmaClk                => dmaClk,
         dmaRst                => dmaRst,
         dmaObMasters          => dmaObMasters,
         dmaObSlaves           => dmaObSlaves,
         dmaIbMasters          => buffIbMasters,
         dmaIbSlaves           => buffIbSlaves);

   ------------------
   -- Hardware Module
   ------------------
   U_HSIO : entity lcls2_pgp_fw_lib.C1100Hsio
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
         userClk156            => axilClk,
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
         -- QSFP[0] Ports
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
