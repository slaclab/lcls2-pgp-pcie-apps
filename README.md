# lcls2-pgp-pcie-apps

<!--- ######################################################## -->

# Before you clone the GIT repository

https://confluence.slac.stanford.edu/x/vJmDFg

# Clone the GIT repository

```
$ git clone --recursive git@github.com:slaclab/lcls2-pgp-pcie-apps
```

<!--- ######################################################## -->

# SLAC PGP GEN4 PCIe Fiber mapping

```
QSFP[0][0] = PGP.Lane[0].VC[3:0]
QSFP[0][1] = PGP.Lane[1].VC[3:0]
QSFP[0][2] = PGP.Lane[2].VC[3:0]
QSFP[0][3] = PGP.Lane[3].VC[3:0]
QSFP[1][0] = LCLS-I  Timing Receiver
QSFP[1][1] = LCLS-II Timing Receiver
QSFP[1][2] = Unused QSFP Link
QSFP[1][3] = Unused QSFP Link
SFP = Unused SFP Link
```

<!--- ######################################################## -->

# KCU1500 & C1100 PCIe Fiber mapping

```
QSFP[0][0] = PGP.Lane[0].VC[3:0]
QSFP[0][1] = PGP.Lane[1].VC[3:0]
QSFP[0][2] = PGP.Lane[2].VC[3:0]
QSFP[0][3] = PGP.Lane[3].VC[3:0]
QSFP[1][0] = LCLS-I  Timing Receiver
QSFP[1][1] = LCLS-II Timing Receiver
QSFP[1][2] = Unused QSFP Link
QSFP[1][3] = Unused QSFP Link
```

<!--- ######################################################## -->

# PGP Virtual Channel Mapping

[VcDataTap defined in the software here](https://github.com/slaclab/lcls2-pgp-fw-lib/blob/master/python/lcls2_pgp_fw_lib/shared/_Application.py#L38)

```python
for i in range(4):
  if (i==VcDataTap):
    # PGP VC used for the AxiStreamBatcherEventBuilder
    PGP[lane].VC[VcDataTap] = DMA[lane].DEST[VcDataTap].DEST[2]
  else:
    # PGP VC mapped to DMA's TDEST
    PGP[lane].VC[i] = DMA[lane].DEST[i]
```

<!--- ######################################################## -->

# DMA channel mapping

[VcDataTap defined in the software here](https://github.com/slaclab/lcls2-pgp-fw-lib/blob/master/python/lcls2_pgp_fw_lib/shared/_Application.py#L38)

```python
for i in range(4):
  if (i==VcDataTap):
    # AxiStreamBatcherEventBuilder
    DMA[lane].DEST[VcDataTap] = Event Builder Batcher (super-frame)
    DMA[lane].DEST[VcDataTap].DEST[0] = XPM Trigger Message (sub-frame)
    DMA[lane].DEST[VcDataTap].DEST[1] = XPM Transition Message (sub-frame)
    DMA[lane].DEST[VcDataTap].DEST[2] = PGP[lane].VC[VcDataTap] (sub-frame)
    DMA[lane].DEST[VcDataTap].DEST[3] = XPM Timing Message (sub-frame)
  else:
    # PGP VC mapped to DMA's TDEST
    DMA[lane].DEST[i] = PGP[lane].VC[i]
```

<!--- ######################################################## -->

# How to build the PCIe firmware

1) Setup Xilinx licensing
```
$ source lcls2-pgp-pcie-apps/firmware/setup_env_slac.sh
```

2) Go to the target directory and make the firmware:
```
$ cd lcls2-pgp-pcie-apps/firmware/targets/XilinxC1100/Lcls2XilinxC1100Pgp4_6Gbps
$ make
```

3) Optional: Review the results in GUI mode
```
$ make gui
```

<!--- ######################################################## -->

# How to load the driver

https://confluence.slac.stanford.edu/x/HLuDFg

<!--- ######################################################## -->

# How to install the Rogue With Anaconda

> https://slaclab.github.io/rogue/installing/anaconda.html

<!--- ######################################################## -->

# XPM Triggering Documentation

https://docs.google.com/document/d/1B_sIkk9Fxsw2EjOBpGVFpfCCWoIiOJoVGTrkTshZfew/edit?usp=sharing

<!--- ######################################################## -->

# How to reprogram the PCIe firmware via Rogue software

1) Setup the rogue environment
```
$ cd lcls2-pgp-pcie-apps/software
$ source setup_env_slac.sh
```

2) Run the PCIe firmware update script:
```
$ python scripts/updatePcieFpga.py --path <PATH_TO_IMAGE_DIR>
```
where <PATH_TO_IMAGE_DIR> is path to image directory (example: ../firmware/targets/XilinxC1100/Lcls2XilinxC1100Pgp4_6Gbps/)

3) Reboot the computer
```
sudo reboot
```

<!--- ######################################################## -->

# Example of starting up with PGP4, LCLS-I timing (startupMode=False), VcDataTap=0 (dataVc=0), and stand alone mode (locally generated timing)
```
$ python scripts/devGui.py --pgp4 1 --startupMode 0 --dataVc 0 --standAloneMode 1
Then execute the StartRun() command to start the triggering
```

<!--- ######################################################## -->
