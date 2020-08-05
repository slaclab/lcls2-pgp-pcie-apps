-------------------------------------------------------------------------------
-- File       : AppLane.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

entity AppLane is
   generic (
      TPD_G             : time := 1 ns;
      AXI_BASE_ADDR_G   : slv(31 downto 0);
      DMA_AXIS_CONFIG_G : AxiStreamConfigType);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- PGP Streams (axilClk domain)
      pgpIbMaster     : out AxiStreamMasterType;
      pgpIbSlave      : in  AxiStreamSlaveType;
      pgpObMasters    : in  AxiStreamQuadMasterType;
      pgpObSlaves     : out AxiStreamQuadSlaveType;
      -- Trigger Event streams (axilClk domain)
      eventAxisMaster : in  AxiStreamMasterType;
      eventAxisSlave  : out AxiStreamSlaveType;
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType);
end AppLane;

architecture mapping of AppLane is

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := genAxiLiteConfig(2, AXI_BASE_ADDR_G, 19, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);

   signal tapMaster : AxiStreamMasterType;
   signal tapSlave  : AxiStreamSlaveType;

   signal eventMaster : AxiStreamMasterType;
   signal eventSlave  : AxiStreamSlaveType;

   signal txMaster : AxiStreamMasterType;
   signal txSlave  : AxiStreamSlaveType;

   signal appObMaster : AxiStreamMasterType;
   signal appObSlave  : AxiStreamSlaveType;

   signal tap   : slv(1 downto 0);
   signal dummy : slv(31 downto 2);

   signal rxMasters : AxiStreamQuadMasterType;
   signal rxSlaves  : AxiStreamQuadSlaveType;

   signal txMasters : AxiStreamQuadMasterType;
   signal txSlaves  : AxiStreamQuadSlaveType;

begin

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_AXIL_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 2,
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

   -----------------------
   -- DMA to HW ASYNC FIFO
   -----------------------
   U_DMA_to_HW : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => dmaClk,
         sAxisRst    => dmaRst,
         sAxisMaster => dmaObMaster,
         sAxisSlave  => dmaObSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => pgpIbMaster,
         mAxisSlave  => pgpIbSlave);

   ----------------------------------
   -- Event Builder
   ----------------------------------         
   U_EventBuilder : entity surf.AxiStreamBatcherEventBuilder
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => 2,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => (
            0           => "0000000-",   -- Trig on 0x0, Event on 0x1
            1           => "00000010"),  -- Map PGP[tap] to TDEST 0x2      
         TRANS_TDEST_G  => X"01",
         AXIS_CONFIG_G  => DMA_AXIS_CONFIG_G)
      port map (
         -- Clock and Reset
         axisClk         => axilClk,
         axisRst         => axilRst,
         -- AXI-Lite Interface (axisClk domain)
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0),
         -- AXIS Interfaces
         sAxisMasters(0) => eventAxisMaster,
         sAxisMasters(1) => tapMaster,   -- PGP[tap]
         sAxisSlaves(0)  => eventAxisSlave,
         sAxisSlaves(1)  => tapSlave,    -- PGP[tap]
         mAxisMaster     => eventMaster,
         mAxisSlave      => eventSlave);

   --------------------
   -- Data Path Routing
   --------------------
   U_AxiLiteRegs : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => 1,
         INI_WRITE_REG_G => (0 => x"0000_0001"))  -- default to VC1 as data path VC
      port map (
         -- AXI-Lite Bus
         axiClk                        => axilClk,
         axiClkRst                     => axilRst,
         axiReadMaster                 => axilReadMasters(1),
         axiReadSlave                  => axilReadSlaves(1),
         axiWriteMaster                => axilWriteMasters(1),
         axiWriteSlave                 => axilWriteSlaves(1),
         -- User Read/Write registers
         writeRegister(0)(1 downto 0)  => tap,
         writeRegister(0)(31 downto 2) => dummy);

   process(pgpObMasters, tap, tapSlave, txMaster, txSlaves)
   begin
      for i in 0 to 3 loop
         if i = tap then
            -- Event Builder
            tapMaster      <= pgpObMasters(i);
            pgpObSlaves(i) <= tapSlave;
            -- DMA Path after Event builder's FIFO
            txMasters(i)   <= txMaster;
            txSlave        <= txSlaves(i);
         else
            -- DMA Path
            txMasters(i)   <= pgpObMasters(i);
            pgpObSlaves(i) <= txSlaves(i);
         end if;
      end loop;
   end process;

   -------------------------------------
   -- Burst FIFO before interleaving MUX
   -------------------------------------
   U_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
         VALID_BURST_MODE_G  => true,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => eventMaster,
         sAxisSlave  => eventSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => txMaster,
         mAxisSlave  => txSlave);

   -----------------
   -- AXI Stream MUX
   -----------------
   U_Mux : entity surf.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => 4,
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => false,
         ILEAVE_REARB_G       => 128,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk         => axilClk,
         axisRst         => axilRst,
         -- Inbound Master Ports
         sAxisMasters(0) => pgpObMasters(0),
         sAxisMasters(1) => txMaster,
         sAxisMasters(2) => pgpObMasters(2),
         sAxisMasters(3) => pgpObMasters(3),
         -- Inbound Slave Ports
         sAxisSlaves(0)  => pgpObSlaves(0),
         sAxisSlaves(1)  => txSlave,
         sAxisSlaves(2)  => pgpObSlaves(2),
         sAxisSlaves(3)  => pgpObSlaves(3),
         -- Outbound Port
         mAxisMaster     => appObMaster,
         mAxisSlave      => appObSlave);

   -----------------------
   -- App to DMA ASYNC FIFO
   -----------------------
   U_APP_to_DMA : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => appObMaster,
         sAxisSlave  => appObSlave,
         -- Master Port
         mAxisClk    => dmaClk,
         mAxisRst    => dmaRst,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);

end mapping;
