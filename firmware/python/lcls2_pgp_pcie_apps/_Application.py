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

class AppLane(pr.Device):
    def __init__(   self,
            name        = "AppLane",
            description = "PCIe Application Lane Container",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #######################################
        # SLAVE[TDEST=0] = XPM Trigger
        # SLAVE[TDEST=1] = XPM Event Transition
        # SLAVE[TDEST=2] = Camera Image
        #######################################
        self.add(batcher.AxiStreamBatcherEventBuilder(
            name         = 'EventBuilder',
            offset       = 0x00000,
            numberSlaves = 2,
            tickUnit     = '156.25MHz',
            expand       = True,
        ))

class Application(pr.Device):
    def __init__(   self,
            name        = "Application",
            description = "PCIe Lane Container",
            numLanes    = 4, # number of PGP Lanes
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        for i in range(numLanes):

            self.add(AppLane(
                name   = ('AppLane[%i]' % i),
                offset = (i*0x0008_0000),
                expand = True,
            ))
