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

import setupLibPaths

import os
import time
import sys
import argparse
import importlib
import rogue
import pyrogue as pr
import l2si_core

# rogue.Logging.setLevel(rogue.Logging.Warning)

#################################################################

class DataDebug(rogue.interfaces.stream.Slave):
    def __init__(self, name, enPrint):
        rogue.interfaces.stream.Slave.__init__(self)

        self.channelData = [[] for _ in range(8)]
        self.name = name
        self.enPrint = enPrint

    def _acceptFrame(self, frame):
        channel = frame.getChannel()

        if channel == 0 or channel == 1:
            if self.enPrint:
                print('-------------------------')
            d = l2si_core.parseEventHeaderFrame(frame,self.enPrint)
            if self.enPrint:
                print(d)
                if channel == 1:
                    print('-------------------------')
                    print()

        if channel == 2:
            frameSize = frame.getPayload()
            ba = bytearray(frameSize)
            frame.read(ba, 0)
            if self.enPrint:
                print(f"Raw camera data channel - {len(ba)} bytes")
                print(frame.getNumpy(0, frameSize))
                print('-------------------------')
        if self.enPrint:
            print()

class myRoot(pr.Root):
    def __init__(self,
                dev    = '/dev/datadev_0',
                dataVc = 1,
                **kwargs):
        super().__init__(**kwargs)

        # Create arrays to be filled
        self.dmaStreams = [None for lane in range(4)]
        self._dbg       = [DataDebug(name='DataDebug',enPrint=False) for lane in range(4)]
        self.unbatchers = [rogue.protocols.batcher.SplitterV1() for lane in range(4)]

        # Connect the streams
        for lane in range(4):
            self.dmaStreams[lane] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+dataVc,1)
            self.dmaStreams[lane] >> self.unbatchers[lane] >> self._dbg[lane]

if __name__ == "__main__":

#################################################################

    # Set the argument parser
    parser = argparse.ArgumentParser()

    # Convert str to bool
    argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

    # Add arguments
    parser.add_argument(
        "--dev",
        type     = str,
        required = False,
        default  = '/dev/datadev_0',
        help     = "path to device",
    )

    parser.add_argument(
        "--dataVc",
        type     = int,
        required = False,
        default  = 1,
        help     = "VC used for the data path",
    )

    parser.add_argument(
        "--releaseZip",
        type     = str,
        required = False,
        default  = None,
        help     = "Sets the default YAML configuration file to be loaded at the root.start()",
    )

    # Get the arguments
    args = parser.parse_args()

    #################################################################

    with myRoot(dev=args.dev,dataVc=args.dataVc) as root:

        while(1):
            time.sleep(0.001)

    #################################################################
