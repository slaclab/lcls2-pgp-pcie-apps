##############################################################################
## This file is part of 'lcls2-pgp-pcie-apps'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'lcls2-pgp-pcie-apps', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
open_run synth_1

# Bug fix for Vivado not connecting the HBM's debug hub clock
SetDebugCoreClk {dbg_hub} {hbmRefClk}

# ###############################
# ## Set the name of the ILA core
# ###############################
# set ilaName u_ila_0

# ##################
# ## Create the core
# ##################
# CreateDebugCore ${ilaName}

# #######################
# ## Set the record depth
# #######################
# set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

# #################################
# ## Set the clock for the ILA core
# #################################
# SetDebugCoreClk ${ilaName} {U_HSIO/U_TimingRx/stableClk}

# #######################
# ## Set the debug Probes
# #######################

# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/stableRst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/gtRxControl[*}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/gtRxControlPllReset}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/gtRxControlReset}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/gtRxStatus[*}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/rxStatus[*}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/rxStatus_reg[*}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/rxUserRst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/timingRxControl[*}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/timingRxRstTmp}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/rxbypassrst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/rxRst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/txbypassrst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[0].REAL_PCIE.U_GTY/txUsrClkActive}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/rxbypassrst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/rxRst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/txbypassrst}
# ConfigProbe ${ilaName} {U_HSIO/U_TimingRx/GEN_VEC[1].REAL_PCIE.U_GTY/txUsrClkActive}

# ##########################
# ## Write the port map file
# ##########################
# WriteDebugProbes ${ilaName}
