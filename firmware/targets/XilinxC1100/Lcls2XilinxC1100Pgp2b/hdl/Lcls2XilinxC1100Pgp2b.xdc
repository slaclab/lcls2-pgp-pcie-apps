##############################################################################
## This file is part of 'lcls2-pgp-pcie-apps'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'lcls2-pgp-pcie-apps', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable    [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE           [current_design]
set_property CONFIG_MODE SPIx4                         [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 63.8          [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup         [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes       [current_design]

set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_HSIO}]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_App}]
set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {U_Hardware}]
set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {U_HbmDmaBuffer}]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axilClk/MmcmGen.U_Mmcm/CLKOUT0]] -group [get_clocks hbmRefClkP]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[0].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[0].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[1].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[1].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[2].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[2].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[3].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_HSIO/GEN_LANE[3].GEN_PGP2b.U_Lane/REAL_PGP.U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
