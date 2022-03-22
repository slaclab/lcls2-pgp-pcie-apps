##############################################################################
## This file is part of 'Camera link gateway'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'Camera link gateway', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Bypass the debug chipscope generation
return

############################
## Open the synthesis design
############################
open_run synth_1




###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_0

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {dmaClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {dmaRst}
ConfigProbe ${ilaName} {U_axilClk/locked}
ConfigProbe ${ilaName} {U_Core/appReadMaster[arvalid]}
ConfigProbe ${ilaName} {U_Core/appReadMaster[rready]}
ConfigProbe ${ilaName} {U_Core/appReadSlave[arready]}
ConfigProbe ${ilaName} {U_Core/appReadSlave[rvalid]}
ConfigProbe ${ilaName} {U_Core/appRst}
ConfigProbe ${ilaName} {U_Core/appReadMaster[araddr][*]}
ConfigProbe ${ilaName} {U_Core/appReadSlave[rresp][*]}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}





###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_1

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {userClk156}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {dmaRst}
ConfigProbe ${ilaName} {U_axilClk/locked}
ConfigProbe ${ilaName} {U_Core/appReadMaster[arvalid]}
ConfigProbe ${ilaName} {U_Core/appReadMaster[rready]}
ConfigProbe ${ilaName} {U_Core/appReadSlave[arready]}
ConfigProbe ${ilaName} {U_Core/appReadSlave[rvalid]}
ConfigProbe ${ilaName} {U_Core/appRst}
ConfigProbe ${ilaName} {U_Core/appReadMaster[araddr][*]}
ConfigProbe ${ilaName} {U_Core/appReadSlave[rresp][*]}






##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}
