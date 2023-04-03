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

```
PGP[lane].VC[0] = SRPv3 (register access)
PGP[lane].VC[1] = Camera Image (streaming data)
PGP[lane].VC[2] = Camera UART (streaming data)
PGP[lane].VC[3] = SEM UART (streaming data)
```

<!--- ######################################################## -->

# DMA channel mapping

```
DMA[lane].DEST[0] = SRPv3
DMA[lane].DEST[1] = Event Builder Batcher (super-frame)
DMA[lane].DEST[1].DEST[0] = XPM Trigger Message (sub-frame)
DMA[lane].DEST[1].DEST[1] = XPM Transition Message (sub-frame)
DMA[lane].DEST[1].DEST[2] = Camera Image (sub-frame)
DMA[lane].DEST[1].DEST[3] = XPM Timing Message (sub-frame)
DMA[lane].DEST[2] = Camera UART
DMA[lane].DEST[3] = SEM UART
DMA[lane].DEST[255:4] = Unused
```

<!--- ######################################################## -->

# How to build the PCIe firmware

1) Setup Xilinx licensing
```
$ source cameralink-gateway/firmware/setup_env_slac.sh
```

2) Go to the target directory and make the firmware:
```
$ cd cameralink-gateway/firmware/targets/ClinkKcu1500Pgp2b/
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
$ cd cameralink-gateway/software
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
