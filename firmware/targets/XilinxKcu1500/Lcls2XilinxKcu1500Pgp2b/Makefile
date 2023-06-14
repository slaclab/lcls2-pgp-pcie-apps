export PARALLEL_SYNTH = 1

# Define target part
export PRJ_PART = xcku115-flvb2104-2-e

# Define target output
target: prom

# Using a non-standard target directory structure, 
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../../..)

# Use top level makefile
include $(TOP_DIR)/targets/shared_config.mk
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk
