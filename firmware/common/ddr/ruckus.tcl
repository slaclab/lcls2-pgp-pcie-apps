# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -dir "$::DIR_PATH/rtl"

# Load xci files
loadIpCore -path "$::DIR_PATH/coregen/XilinxKcu1500Mig0Core.xci"
loadIpCore -path "$::DIR_PATH/coregen/XilinxKcu1500Mig1Core.xci"
loadIpCore -path "$::DIR_PATH/coregen/MigXbarV3.xci"
loadIpCore -path "$::DIR_PATH/coregen/ila_0.xci"

loadConstraints -path "$::DIR_PATH/coregen/XilinxKcu1500Mig0.xdc"
loadConstraints -path "$::DIR_PATH/coregen/XilinxKcu1500Mig1.xdc"
