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

import axipcie                                 as pcie
import lcls2_pgp_pcie_apps                     as dev
import lcls2_pgp_fw_lib.hardware.XilinxKcu1500 as xilinxKcu1500

class Kcu1500(pr.Device):
    def __init__(self,
                 numLanes = 4,
                 pgp4     = False,
                 enLclsI  = True,
                 enLclsII = False,
                 **kwargs):
        super().__init__(**kwargs)

        # Core Layer
        self.add(pcie.AxiPcieCore(
            offset      = 0x0000_0000,
            numDmaLanes = numLanes,
            expand      = False,
        ))

        # Application layer
        self.add(dev.Application(
            offset   = 0x00C0_0000,
            numLanes = numLanes,
            expand   = True,
        ))

        # Hardware Layer
        self.add(xilinxKcu1500.Kcu1500Hsio(
            name     = 'Hsio',
            offset    = 0x0080_0000,
            numLanes  = numLanes,
            pgp4      = pgp4,
            enLclsI   = enLclsI,
            enLclsII  = enLclsII,
            expand    = True,
        ))
