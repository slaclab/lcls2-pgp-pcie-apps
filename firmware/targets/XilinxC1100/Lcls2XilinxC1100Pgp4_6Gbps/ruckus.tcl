# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load base sub-modules
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls-timing-core
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/XilinxVariumC1100
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls2-pgp-fw-lib/hardware/XilinxVariumC1100

# Load the l2si-core source code
loadSource -lib l2si_core -dir "$::env(TOP_DIR)/submodules/l2si-core/xpm/rtl"
loadSource -lib l2si_core -dir "$::env(TOP_DIR)/submodules/l2si-core/base/rtl"

# Load local source Code
loadSource -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

# Updating impl_1 strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Set top-level simulation
set_property top {TimingRxTb} [get_filesets sim_1]
# set_property top {TimingGtCoreWrapperTb} [get_filesets sim_1]
