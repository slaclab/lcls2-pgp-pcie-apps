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

import axipcie                 as pcie
import lcls2_pgp_fw_lib.shared as shared
import surf.axi                as axi

class PcieFpga(pr.Device):
    def __init__(self,
                 pgp4      = False,
                 enLclsI   = True,
                 enLclsII  = False,
                 useDdr    = False,
                 boardType = None,
                 **kwargs):
        super().__init__(**kwargs)

        # Core Layer
        self.add(pcie.AxiPcieCore(
            offset      = 0x0000_0000,
            numDmaLanes = 4,
            boardType   = boardType,
            expand      = False,
        ))

        if useDdr:
            for i in range(4):
                self.add(axi.AxiStreamDmaV2Fifo(
                    name    = f'DmaBuffer[{i}]',
                    offset  = 0x0010_0000+i*0x100,
                    expand  = False,
                ))

        # Application layer
        self.add(shared.Application(
            offset   = 0x00C0_0000,
            numLanes = 4,
            expand   = False,
        ))

        # Hardware Layer
        self.add(shared.Hsio(
            name       = 'Hsio',
            offset     = 0x0080_0000,
            pgp4       = pgp4,
            enLclsI    = enLclsI,
            enLclsII   = enLclsII,
            expand     = True,
            laneConfig = {
                0: 'TBD',
                1: 'TBD',
                2: 'TBD',
                3: 'TBD',
            },
        ))
