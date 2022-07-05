from setuptools import setup

# use softlinks to make the various "board-support-package" submodules
# look like subpackages.  Then __init__.py will modify
# sys.path so that the correct "local" versions of surf etc. are
# picked up.  A better approach would be using relative imports
# in the submodules, but that's more work.  -cpo

setup(
    name = 'lcls2_pgp_pcie_apps',
    description = 'LCLS II pgp package',
    packages = [
        'lcls2_pgp_pcie_apps',
        'lcls2_pgp_pcie_apps.axipcie',
        'lcls2_pgp_pcie_apps.l2si_core',
        'lcls2_pgp_pcie_apps.daq_stream_cache',
        'lcls2_pgp_pcie_apps.lcls2_pgp_fw_lib.hardware.XilinxKcu1500',
        'lcls2_pgp_pcie_apps.lcls2_pgp_fw_lib.hardware.SlacPgpCardG4',
        'lcls2_pgp_pcie_apps.lcls2_pgp_fw_lib.hardware',
        'lcls2_pgp_pcie_apps.lcls2_pgp_fw_lib.hardware.shared',
        'lcls2_pgp_pcie_apps.lcls2_pgp_fw_lib',
        'lcls2_pgp_pcie_apps.surf.misc',
        'lcls2_pgp_pcie_apps.surf.xilinx',
        'lcls2_pgp_pcie_apps.surf.axi',
        'lcls2_pgp_pcie_apps.surf',
        'lcls2_pgp_pcie_apps.surf.ethernet.xaui',
        'lcls2_pgp_pcie_apps.surf.ethernet.udp',
        'lcls2_pgp_pcie_apps.surf.ethernet.ten_gig',
        'lcls2_pgp_pcie_apps.surf.ethernet',
        'lcls2_pgp_pcie_apps.surf.ethernet.mac',
        'lcls2_pgp_pcie_apps.surf.ethernet.gige',
        'lcls2_pgp_pcie_apps.surf.dsp',
        'lcls2_pgp_pcie_apps.surf.dsp.fixed',
        'lcls2_pgp_pcie_apps.surf.protocols.clink',
        'lcls2_pgp_pcie_apps.surf.protocols.ssp',
        'lcls2_pgp_pcie_apps.surf.protocols.jesd204b',
        'lcls2_pgp_pcie_apps.surf.protocols.i2c',
        'lcls2_pgp_pcie_apps.surf.protocols',
        'lcls2_pgp_pcie_apps.surf.protocols.ssi',
        'lcls2_pgp_pcie_apps.surf.protocols.batcher',
        'lcls2_pgp_pcie_apps.surf.protocols.rssi',
        'lcls2_pgp_pcie_apps.surf.protocols.pgp',
        'lcls2_pgp_pcie_apps.surf.devices.intel',
        'lcls2_pgp_pcie_apps.surf.devices.nxp',
        'lcls2_pgp_pcie_apps.surf.devices.cypress',
        'lcls2_pgp_pcie_apps.surf.devices.linear',
        'lcls2_pgp_pcie_apps.surf.devices.micron',
        'lcls2_pgp_pcie_apps.surf.devices',
        'lcls2_pgp_pcie_apps.surf.devices.analog_devices',
        'lcls2_pgp_pcie_apps.surf.devices.microchip',
        'lcls2_pgp_pcie_apps.surf.devices.transceivers',
        'lcls2_pgp_pcie_apps.surf.devices.silabs',
        'lcls2_pgp_pcie_apps.surf.devices.ti',
        'lcls2_pgp_pcie_apps.LclsTimingCore',
    ],
    package_dir = {
        'lcls2_pgp_pcie_apps': 'firmware/python/lcls2_pgp_pcie_apps',
        'lcls2_pgp_pcie_apps.surf': 'firmware/submodules/surf/python/surf',
        'lcls2_pgp_pcie_apps.surf': 'firmware/submodules/surf/python/surf',
        'lcls2_pgp_pcie_apps.axipcie': 'firmware/submodules/axi-pcie-core/python/axipcie',
        'lcls2_pgp_pcie_apps.LclsTimingCore': 'firmware/submodules/lcls-timing-core/python/LclsTimingCore',
        'lcls2_pgp_pcie_apps.lcls2_pgp_fw_lib': 'firmware/submodules/lcls2-pgp-fw-lib/python/lcls2_pgp_fw_lib',
        'lcls2_pgp_pcie_apps.l2si_core': 'firmware/submodules/l2si-core/python/l2si_core'
    }
)
