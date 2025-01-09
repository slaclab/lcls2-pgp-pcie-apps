#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'lcls2-pgp-pcie-apps'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'lcls2-pgp-pcie-apps', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import pyrogue as pr
import rogue
import click

import axipcie

import lcls2_pgp_pcie_apps     as pcieApp
import lcls2_pgp_fw_lib.shared as shared
import l2si_core               as l2si
import surf.protocols.batcher  as batcher

rogue.Version.minVersion('6.4.0')

class DevRoot(shared.Root):

    def __init__(self,
                 dev            = '/dev/datadev_0',# path to PCIe device
                 enLclsI        = True,
                 enLclsII       = False,
                 yamlFileLclsI  = "config/defaults_LCLS-I.yml",
                 yamlFileLclsII = "config/defaults_LCLS-II.yml",
                 startupMode    = False, # False = LCLS-I timing mode, True = LCLS-II timing mode
                 standAloneMode = False, # False = using fiber timing, True = locally generated timing
                 pgp4           = False, # true = PGPv4, false = PGP2b
                 dataVc         = 1,
                 pollEn         = True,  # Enable automatic polling registers
                 initRead       = True,  # Read all registers at start of the system
                 pcieBoardType  = None,
                 useDdr         = False,
                 zmqSrvEn       = True,
                 **kwargs):

        # Set local variables
        self.dev            = dev
        self.startupMode    = startupMode
        self.standAloneMode = standAloneMode
        self.dataVc         = dataVc
        self.yamlFileLclsI  = yamlFileLclsI
        self.yamlFileLclsII = yamlFileLclsII

        # Pass custom value to parent via super function
        super().__init__(
            dev         = dev,
            pgp4        = pgp4,
            pollEn      = pollEn,
            initRead    = initRead,
            **kwargs)

        # Add ZMQ server
        if zmqSrvEn:
            self.zmqServer = pr.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
            self.addInterface(self.zmqServer)

        # Check for simulation
        if dev == 'sim':
            # Set the timeout
            self._timeout = 100000000 # firmware simulation slow and timeout base on real time (not simulation time)

        else:
            # Set the timeout
            self._timeout = 5000000 # 5.0 seconds default

        # Unhide the RemoteVariableDump command
        self.RemoteVariableDump.hidden = False

        # Create memory interface
        self.memMap = axipcie.createAxiPcieMemMap(dev, 'localhost', 8000)
        self.memMap.setName('PCIe_Bar0')

        # Instantiate the top level Device and pass it the memory map
        self.add(pcieApp.PcieFpga(
            name      = 'DevPcie',
            memBase   = self.memMap,
            pgp4      = pgp4,
            enLclsI   = enLclsI,
            enLclsII  = enLclsII,
            useDdr    = useDdr,
            boardType = pcieBoardType,
            expand    = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'RunState',
            description = 'Run state status, which is controlled by the StopRun() and StartRun() commands',
            mode        = 'RO',
            value       = False,
        ))

        @self.command(description  = 'Stops the triggers and blows off data in the pipeline')
        def StopRun():
            print ('ClinkDev.StopRun() executed')

            # Get devices
            eventBuilder = self.find(typ=batcher.AxiStreamBatcherEventBuilder)
            trigger      = self.find(typ=l2si.TriggerEventBuffer)

            # Turn off the triggering
            for devPtr in trigger:
                devPtr.MasterEnable.set(False)

            # Flush the downstream data/trigger pipelines
            for devPtr in eventBuilder:
                devPtr.Blowoff.set(True)

            # Update the run state status variable
            self.RunState.set(False)

        @self.command(description  = 'starts the triggers and allow steams to flow to DMA engine')
        def StartRun():
            print ('ClinkDev.StartRun() executed')

            # Get devices
            eventBuilder = self.find(typ=batcher.AxiStreamBatcherEventBuilder)
            trigger      = self.find(typ=l2si.TriggerEventBuffer)

            # Reset all counters
            self.CountReset()

            # Arm for data/trigger stream
            for devPtr in eventBuilder:
                devPtr.Blowoff.set(False)
                devPtr.SoftRst()

            # Turn on the triggering
            for devPtr in trigger:
                devPtr.MasterEnable.set(True)

            # Update the run state status variable
            self.RunState.set(True)

    def start(self, **kwargs):
        super().start(**kwargs)

        # Hide all the "enable" variables
        for enableList in self.find(typ=pr.EnableVariable):
            # Hide by default
            enableList.hidden = True

        # Check if not simulation
        if (self.dev != 'sim'):

            # Useful pointer
            timingRx = self.DevPcie.Hsio.TimingRx

            # Start up the timing system = LCLS-II mode
            if self.startupMode:

                # Set the default to  LCLS-II mode
                defaultFile = [self.yamlFileLclsII]

                # Startup in LCLS-II mode
                if self.standAloneMode:
                    timingRx.ConfigureXpmMini()
                else:
                    timingRx.ConfigLclsTimingV2()

            # Else LCLS-I mode
            else:

                # Set the default to  LCLS-I mode
                defaultFile = [self.yamlFileLclsI]

                # Startup in LCLS-I mode
                if self.standAloneMode:
                    timingRx.ConfigureTpgMiniStream()
                else:
                    timingRx.ConfigLclsTimingV1()

            # Read all the variables
            self.ReadAll()
            self.ReadAll()

            # Load the YAML configurations
            for yamlFile in defaultFile:
                if yamlFile is not None:
                    print(f'Loading {yamlFile} Configuration File...')
                    self.LoadConfig(yamlFile)

            # Set the VC data tap
            appLane = self.find(typ=shared.AppLane)
            for devPtr in appLane:
                devPtr.VcDataTap.set(self.dataVc)

    # Function calls after loading YAML configuration
    def initialize(self):
        super().initialize()

        # Check if not simulation
        if (self.dev != 'sim'):
            self.StopRun()
            self.CountReset()
