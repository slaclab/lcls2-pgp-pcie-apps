-------------------------------------------------------------------------------
-- File       : AppToMigWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2022-03-09
-------------------------------------------------------------------------------
-- Description: Wrapper for Xilinx Axi Data Mover
-- Axi stream input (dscReadMasters.command) launches an AxiReadMaster to
-- read from a memory mapped device and write to another memory mapped device
-- with an AxiWriteMaster to a start address given by the AxiLite bus register
-- writes.  Completion of the transfer results in another axi write.
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
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
use surf.AxiDmaPkg.all;
use work.AppMigPkg.all;

entity AppToMigDma is
  generic ( AXI_BASE_ADDR_G     : slv(31 downto 0) := (others=>'0');
            SLAVE_AXIS_CONFIG_G : AxiStreamConfigType;
            DEBUG_G             : boolean          := false );
  port    ( -- Clock and reset
    sAxisClk         : in  sl; -- 156MHz
    sAxisRst         : in  sl;
    sAxisMaster      : in  AxiStreamMasterType;
    sAxisSlave       : out AxiStreamSlaveType ;
    sAlmostFull      : out sl;
    sFull            : out sl;
    -- AXI4 Interface to MIG
    mAxiClk          : in  sl; -- 200MHz
    mAxiRst          : in  sl;
    mAxiWriteMaster  : out AxiWriteMasterType ;
    mAxiWriteSlave   : in  AxiWriteSlaveType  ;
    -- Command/Status to MigToPcieDma
    rdDescReq        : out AxiReadDmaDescReqType;
    rdDescReqAck     : in  sl;
    rdDescRet        : in  AxiReadDmaDescRetType;
    rdDescRetAck     : out sl;
    -- Configuration
    memReady         : in  sl := '0';
    config           : in  MigConfigType;
    -- Status
    status           : out MigStatusType;
    -- DMA Monitoring
    axilClk          : in  sl := '0';
    axilRst          : in  sl := '0';
    axilWriteMaster  : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
    axilWriteSlave   : out AxiLiteWriteSlaveType;
    axilReadMaster   : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
    axilReadSlave    : out AxiLiteReadSlaveType );
end AppToMigDma;

architecture mapping of AppToMigDma is

  signal mAxisMaster : AxiStreamMasterType;
  signal mAxisSlave  : AxiStreamSlaveType;

  signal doutTransfer  : slv(AXI_WRITE_DMA_DESC_RET_SIZE_C-1 downto 0);
  
  signal mPause  : sl;
  signal mFull   : sl;

  type TagState is (IDLE_T, REQUESTED_T, COMPLETED_T);
  type TagStateArray is array(natural range<>) of TagState;
  
  constant BIS : integer := BLOCK_INDEX_SIZE_C;
  
  type RegType is record
    wrIndex        : slv(BIS-1 downto 0);  -- write request
    wcIndex        : slv(BIS-1 downto 0);  -- write complete
    rdIndex        : slv(BIS-1 downto 0);  -- read complete
    wrTag          : TagStateArray(15 downto 0);
    wrTransfer     : sl;
    wrTransferAddr : slv(BIS-1 downto 0);
    wrTransferDin  : slv(AXI_WRITE_DMA_DESC_RET_SIZE_C-1 downto 0);
    rdenb          : sl;
    wrDescAck      : AxiWriteDmaDescAckType;
    wrDescRetAck   : sl;
    rdDescReq      : AxiReadDmaDescReqType;
    rdDescRetAck   : sl;
    blocksFree     : slv(BIS-1 downto 0);
    tlast          : sl;
    recvdQueCnt    : slv(7 downto 0);
    writeQueCnt    : slv(7 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    wrIndex        => (others=>'0'),
    wcIndex        => (others=>'0'),
    rdIndex        => (others=>'0'),
    wrTag          => (others=>IDLE_T),
    wrTransfer     => '0',
    wrTransferAddr => (others=>'0'),
    wrTransferDin  => (others=>'0'),
    rdenb          => '0',
    wrDescAck      => AXI_WRITE_DMA_DESC_ACK_INIT_C,
    wrDescRetAck   => '0',
    rdDescReq      => AXI_READ_DMA_DESC_REQ_INIT_C,
    rdDescRetAck   => '0',
    blocksFree     => (others=>'0'),
    tlast          => '1',
    recvdQueCnt    => (others=>'0'),
    writeQueCnt    => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal isAxisSlave : AxiStreamSlaveType;
  signal isPause     : sl;
  signal isFull      : sl;
  
  -- DMA AXI Stream Configuration
  constant AXIO_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_NORMAL_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_NORMAL_C);

  component ila_0
    port ( clk          : in sl;
           probe0       : in slv(255 downto 0) );
  end component;

  signal sBlocksFree   : slv(BIS-1 downto 0);
  signal sBlocksFreeD  : slv(9 downto 0);

  signal rdenb          : sl;
  signal rdTransferAddr : slv(BIS-1 downto 0);  -- read complete

  signal wrDescReq    : AxiWriteDmaDescReqType;
  signal wrDescAck    : AxiWriteDmaDescAckType;
  signal wrDescRet    : AxiWriteDmaDescRetType;
  signal wrDescRetAck : sl;
  
begin

  GEN_DEBUG : if DEBUG_G generate
    sBlocksFreeD <= resize(sBlocksFree,10);
    U_ILA_APP : ila_0
      port map ( clk          => sAxisClk,
                 probe0(0)    => sAxisRst,
                 probe0(1)    => sAxisMaster.tValid,
                 probe0(2)    => sAxisMaster.tLast,
                 probe0(3)    => isAxisSlave.tReady,
                 probe0(4)    => isPause,
                 probe0( 68 downto  5) => sAxisMaster.tData(63 downto 0),
                 probe0( 76 downto 69) => (others=>'0'),
                 probe0( 77 )          => '0',
                 probe0( 78 )          => isFull,
                 probe0( 88 downto 79) => sBlocksFreeD,
                 probe0(255 downto 89) => (others=>'0') );
  end generate;

  sAxisSlave                <= isAxisSlave;
  sAlmostFull               <= isPause;
  sFull                     <= isFull;
  
  mPause <= '1' when (r.blocksFree < config.blocksPause) else '0';
  mFull  <= '1' when ((r.blocksFree < 4) or (config.inhibit='1')) else '0';

  U_Free  : entity surf.SynchronizerFifo
    generic map ( DATA_WIDTH_G => BIS )
    port map ( wr_clk  => mAxiClk,
               din     => r.blocksFree,
               rd_clk  => sAxisClk,
               dout    => sBlocksFree );
  
  U_Pause : entity surf.Synchronizer
    port map ( clk     => sAxisClk,
               rst     => sAxisRst,
               dataIn  => mPause,
               dataOut => isPause );

  U_Full : entity surf.Synchronizer
    port map ( clk     => sAxisClk,
               rst     => sAxisRst,
               dataIn  => mFull,
               dataOut => isFull );

  U_Ready : entity surf.Synchronizer
    port map ( clk     => mAxiClk,
               rst     => mAxiRst,
               dataIn  => memReady,
               dataOut => status.memReady );
  
  --
  --  Insert a fifo to cross clock domains
  --
  U_AxisFifo : entity surf.AxiStreamFifoV2
    generic map ( FIFO_ADDR_WIDTH_G   => 8,
                  SLAVE_AXI_CONFIG_G  => SLAVE_AXIS_CONFIG_G,
                  MASTER_AXI_CONFIG_G => AXIO_STREAM_CONFIG_C )
    port map ( sAxisClk    => sAxisClk,
               sAxisRst    => sAxisRst,
               sAxisMaster => sAxisMaster,
               sAxisSlave  => isAxisSlave,
               sAxisCtrl   => open,
               mAxisClk    => mAxiClk,
               mAxisRst    => mAxiRst,
               mAxisMaster => mAxisMaster,
               mAxisSlave  => mAxisSlave );

  GEN_DMA_DEBUG : if DEBUG_G generate
      DMA_AXIS_MON_IB : entity surf.AxiStreamMonAxiL
         generic map(
            COMMON_CLK_G     => true,
            AXIS_CLK_FREQ_G  => 200.00E+6,
            AXIS_NUM_SLOTS_G => 1,
            AXIS_CONFIG_G    => AXIO_STREAM_CONFIG_C)
         port map(
            -- AXIS Stream Interface
            axisClk          => mAxiClk,
            axisRst          => mAxiRst,
            axisMasters  (0) => mAxisMaster,
            axisSlaves   (0) => mAxisSlave,
            -- AXI lite slave port for register access
            axilClk          => axilClk,
            axilRst          => axilRst,
            sAxilWriteMaster => axilWriteMaster,
            sAxilWriteSlave  => axilWriteSlave,
            sAxilReadMaster  => axilReadMaster,
            sAxilReadSlave   => axilReadSlave );
  end generate;

  GEN_NO_DMA_DEBUG : if not DEBUG_G generate
    axilWriteSlave <= AXI_LITE_WRITE_SLAVE_INIT_C;
    axilReadSlave  <= AXI_LITE_READ_SLAVE_INIT_C;
  end generate;

  U_DmaWrite : entity surf.AxiStreamDmaV2Write
    generic map ( AXI_READY_EN_G => true,
                  AXIS_CONFIG_G  => AXIO_STREAM_CONFIG_C,
                  AXI_CONFIG_G   => APP2MIG_AXI_CONFIG_C )
    port map ( axiClk         => mAxiClk,
               axiRst         => mAxiRst,
               dmaWrDescReq   => wrDescReq,
               dmaWrDescAck   => wrDescAck,
               dmaWrDescRet   => wrDescRet,
               dmaWrDescRetAck=> wrDescRetAck,
               dmaWrIdle      => open,
               axiCache       => x"3",
               axisMaster     => mAxisMaster,
               axisSlave      => mAxisSlave,
               axiWriteMaster => mAxiWriteMaster,
               axiWriteSlave  => mAxiWriteSlave );
                    
  U_TransferFifo : entity surf.SimpleDualPortRam
    generic map ( DATA_WIDTH_G => AXI_WRITE_DMA_DESC_RET_SIZE_C,
                  ADDR_WIDTH_G => BIS )
    port map ( clka       => mAxiClk,
               wea        => r.wrTransfer,
               addra      => r.wrTransferAddr,
               dina       => r.wrTransferDin,
               clkb       => mAxiClk,
               enb        => rdenb,
               addrb      => rdTransferAddr,
               doutb      => doutTransfer );

  comb : process ( r, mAxiRst,
                   mAxisMaster, mAxisSlave,
                   wrDescReq,
                   wrDescRet,
                   rdDescReqAck,
                   rdDescRet,
                   doutTransfer ,
                   config ) is
    variable v       : RegType;
    variable i       : integer;
    variable wlen    : slv(22 downto 0);
    variable waddr   : slv(31 downto 0);
    variable rlen    : slv(22 downto 0);
    variable raddr   : slv(31 downto 0);
    variable stag    : slv( 3 downto 0);
    variable itag    : integer;
    variable axiRstQ : slv( 2 downto 0) := (others=>'1');
    variable dmaDesc : AxiWriteDmaDescRetType;
  begin
    v := r;

    dmaDesc := toAxiWriteDmaDescRet(doutTransfer,'1');
    
    v.wrTransfer               := '0';
    
    i := BLOCK_BASE_SIZE_C;
    
    --
    --  Stuff a new block address into the Axi engine
    --    on the first transfer of a new frame
    if (mAxisMaster.tValid = '1' and
        mAxisSlave.tReady  = '1') then
      if r.tlast = '1' then
        v.recvdQueCnt := v.recvdQueCnt + 1;
      end if;
      v.tlast := mAxisMaster.tLast;
    end if;
    
    itag := conv_integer(r.wrIndex(3 downto 0));
    if (wrDescReq.valid = '1') then
      waddr   := resize(r.wrIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      wlen    := (others=>'0');
      wlen(i) := '1';
      v.wrDescAck.valid   := '0';
      v.wrDescAck.address := resize(waddr,64);
      v.wrDescAck.dropEn  := '0';
      v.wrDescAck.maxSize := resize(wlen,32);
      v.wrDescAck.contEn  := '1';
      v.wrDescAck.buffId  := toSlv(itag,32);
      if (r.wrTag(itag) = IDLE_T and
          r.recvdQueCnt /= 0 and
          r.wrIndex + 16 /= r.rdIndex) then  -- prevent overwrite
        v.wrIndex                  := r.wrIndex + 1;
        v.recvdQueCnt              := v.recvdQueCnt - 1;
        v.wrTag(itag)              := REQUESTED_T;
        v.wrDescAck.valid          := '1';
      end if;
    end if;

    stag := wrDescRet.buffId(3 downto 0);
    itag := conv_integer(stag);
    v.wrDescRetAck := wrDescRet.valid;
    if wrDescRet.valid = '1' then
      v.wrTag(itag)      := COMPLETED_T;
      v.wrTransfer       := '1';
      v.wrTransferDin    := toSlv(wrDescRet);
      if stag < r.wcIndex(3 downto 0) then
        v.wrTransferAddr := (r.wcIndex(BIS-1 downto 4)+1) & stag;
      else
        v.wrTransferAddr := (r.wcIndex(BIS-1 downto 4)+0) & stag;
      end if;
    end if;
    
    itag := conv_integer(r.wcIndex(3 downto 0));
    if r.wrTag(itag) = COMPLETED_T then
      v.wrTag(itag) := IDLE_T;
      v.wcIndex     := r.wcIndex + 1;
    end if;

    if rdDescReqAck='1' then
      v.rdDescReq.valid := '0';
    end if;
    
    if (v.rdDescReq.valid='0' and
        r.rdenb ='1' and
        r.rdIndex /= r.wcIndex) then
      raddr   := resize(r.rdIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      rlen                       := resize(dmaDesc.size,rlen'length);
      v.rdDescReq.valid          := '1';
      v.rdDescReq.address        := resize(raddr,64);
      v.rdDescReq.size           := resize(rlen,32);
      v.rdDescReq.buffId         := resize(r.rdIndex,32);
      v.rdDescReq.firstUser      := dmaDesc.firstUser;
      v.rdDescReq.lastUser       := dmaDesc.lastUser;
      v.rdDescReq.continue       := dmaDesc.continue;
      v.rdDescReq.id             := dmaDesc.id;
      v.rdDescReq.dest           := dmaDesc.dest;
      v.rdIndex                  := r.rdIndex + 1;
    end if;

    if (r.wrTransfer = '1' and
        r.wrTransferAddr = v.rdIndex) then
      v.rdenb := '0';
    else
      v.rdenb := '1';
    end if;
    
    v.rdDescRetAck := rdDescRet.valid;
    if (rdDescRet.valid = '1') then
      v.writeQueCnt := v.writeQueCnt + 1;
    end if;

    v.blocksFree              := resize(r.rdIndex - r.wcIndex - 1, BIS);

    status.blocksFree         <= r.blocksFree;
    status.blocksQueued       <= resize(r.wrIndex - r.rdIndex, BIS);
    status.writeQueCnt        <= r.writeQueCnt;
    status.wrIndex            <= r.wrIndex;
    status.wcIndex            <= r.wcIndex;
    status.rdIndex            <= r.rdIndex;
    
    wrDescAck                 <= r.wrDescAck;
    wrDescRetAck              <= v.wrDescRetAck;
    rdDescReq                 <= r.rdDescReq;
    rdDescRetAck              <= v.rdDescRetAck;

    rdenb          <= v.rdenb;
    rdTransferAddr <= v.rdIndex;
    
    if axiRstQ(0) = '1' then
      v := REG_INIT_C;
    end if;
    
    rin <= v;

    axiRstQ := mAxiRst & axiRstQ(2 downto 1);
    
  end process comb;

  seq: process(mAxiClk) is
  begin
    if rising_edge(mAxiClk) then
      r <= rin;
    end if;
  end process seq;

end mapping;
