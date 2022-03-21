#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'Camera link gateway'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Camera link gateway', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import surf.protocols.batcher as batcher

class VcDataTap(pr.Device):
    def __init__(   self,
            name        = "VcDataTap",
            description = "Selects the VC used for the AxiStreamBatcherEventBuilder",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = 'Tap',
            offset       = 0x100,
            bitSize      = 2,
            mode         = 'RW',
        ))

class AppLane(pr.Device):
    def __init__(   self,
            name        = "AppLane",
            description = "PCIe Application Lane Container",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #######################################
        # SLAVE[INDEX=0][TDEST=0] = XPM Trigger
        # SLAVE[INDEX=0][TDEST=1] = XPM Event Transition
        # SLAVE[INDEX=1][TDEST=2] = Camera Image
        # SLAVE[INDEX=2][TDEST=3] = XPM Timing
        #######################################
        self.add(batcher.AxiStreamBatcherEventBuilder(
            name         = 'EventBuilder',
            offset       = 0x0_0000,
            numberSlaves = 3, # Total number of slave indexes (not necessarily same as TDEST)
            tickUnit     = '156.25MHz',
            expand       = True,
        ))

        self.add(VcDataTap(
            name         = 'VcDataTap',
            offset       = 0x1_0000,
            expand       = True,
        ))

class MigLane(pr.Device):
    def __init__(self,
                 name         = "MigLane",
                 description  = "RAM Controller",
                 **kwargs) :
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = 'blockSize',
            offset       = 0x000,
            bitSize      = 4,
            mode         = 'RW',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'blocksPause',
            offset       = 0x004,
            bitSize      = 9,
            bitOffset    = 8,
            mode         = 'RW',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'blocksFree',
            offset       = 0x008,
            bitSize      = 9,
            bitOffset    = 0,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'blocksQueued',
            offset       = 0x008,
            bitSize      = 9,
            bitOffset    = 12,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'writeQueCnt',
            offset       = 0x00C,
            bitSize      = 8,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'wrIndex',
            offset       = 0x010,
            bitSize      = 9,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'wcIndex',
            offset       = 0x014,
            bitSize      = 9,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'rdIndex',
            offset       = 0x018,
            bitSize      = 9,
            mode         = 'RO',
        ))

class MigLaneDetail(pr.Device):
    def __init__(self,
                 name         = "MigLaneDetail",
                 description  = "RAM Controller",
                 **kwargs) :
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = 'wid',
            offset       = 0x000,
            bitSize      = 8,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'rid',
            offset       = 0x000,
            bitSize      = 8,
            bitOffset    = 8,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'vid',
            offset       = 0x000,
            bitSize      = 8,
            bitOffset    = 16,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'wdest',
            offset       = 0x004,
            bitSize      = 8,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'rdest',
            offset       = 0x004,
            bitSize      = 8,
            bitOffset    = 8,
            mode         = 'RO',
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'vdest',
            offset       = 0x004,
            bitSize      = 8,
            bitOffset    = 16,
            mode         = 'RO',
        ))


class MigToPcie(pr.Device):
    def __init__( self,
                  name        = "MigToPcie",
                  description = "Local RAM to Host RAM Controller",
                  numLanes    = 4,
                  **kwargs ) :
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = 'monEnable',
            offset       = 0x000,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'usrRst',
            offset       = 0x000,
            bitSize      = 1,
            bitOffset    = 1,
            mode         = 'RW',
        ))

        for i in range(numLanes):
            self.add(MigLane(
                name   = ('MigLane[%i]' % i),
                offset = (0x080+i*0x20),
                expand = True,
            ))

        for i in range(numLanes):
            self.add(MigLaneDetail(
                name   = ('MigLaneDetail[%i]' % i),
                offset = (0x180+i*0x20),
                expand = True,
            ))

        #  MonClk
        for i in range(4):
            self.add(pr.RemoteVariable(
                name         = f'MonClock{i}Raw',
                offset       = (0x100+i*4),
                bitSize      = 29,
                mode         = 'RO',
                hidden       = True,
                pollInterval = 1,
            ))

        def addMonClk(name,raw):
            self.add(pr.LinkVariable(
                name         = name,
                units        = "MHz",
                mode         = 'RO',
                dependencies = [raw],
                linkedGet    = lambda: raw.value() * 1.0e-6,
                disp         = '{:0.3f}',
            ))

        addMonClk('MonClock0Frequency',self.MonClock0Raw)
        addMonClk('MonClock1Frequency',self.MonClock1Raw)
        addMonClk('MonClock2Frequency',self.MonClock2Raw)
        addMonClk('MonClock3Frequency',self.MonClock3Raw)

class Application(pr.Device):
    def __init__(   self,
                    name        = "Application",
                    description = "PCIe Lane Container",
                    numLanes    = 4, # number of PGP Lanes
                    useDdr      = False,
                    **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        for i in range(numLanes):

            self.add(AppLane(
                name   = ('AppLane[%i]' % i),
                offset = (i*0x0008_0000),
                expand = True,
            ))

        if useDdr:
            self.add(MigToPcie(
                name     = 'MigToPcie',
                numLanes = numLanes,
                offset   = (numLanes*0x0008_0000),
                expand   = True,
            ))
