##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'PGP PCIe APP DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_HSIO}]
# set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_Application}]

set_clock_groups -asynchronous \
		 -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[*].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_6G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp6G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]] \
		 -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[*].GEN_PGP4.U_Lane/REAL_PGP.U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_6G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp6G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]]

#  Fix generated clocks from Kcu1500Hsio.xdc
create_generated_clock -name clk25 [get_pins {U_axilClk/MmcmGen.U_Mmcm/CLKOUT2}]
create_generated_clock -name clk156 [get_pins {U_axilClk/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous \
		 -group [get_clocks -include_generated_clocks {clk156}]  \
		 -group [get_clocks -include_generated_clocks {clk25}]
set_clock_groups -asynchronous \
		 -group [get_clocks -include_generated_clocks {clk156}]  \
		 -group [get_clocks -include_generated_clocks {timingGtRxOutClk0}]
set_clock_groups -asynchronous \
		 -group [get_clocks -include_generated_clocks {clk156}]  \
		 -group [get_clocks -include_generated_clocks {timingGtRxOutClk1}] 

#ERROR: [Place 30-716] Sub-optimal placement for a global clock-capable IO pin-BUFGCE-MMCM pair. If this sub optimal condition is acceptable for this design, you may use the CLOCK_DEDICATED_ROUTE constraint in the .xdc file to demote this message to a WARNING. However, the use of this override is highly discouraged. These examples can be used directly in the .xdc file to override this clock rule.

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets U_axilClk/CLKIN1]
