#!/bin/bash -f
# ------------------------------------------------------------------------
# Copyright 2019 The Aerospace Corporation
#
# This file is part of SatCat5.
#
# SatCat5 is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# SatCat5 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with SatCat5.  If not, see <https://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------
#
# This shell script compiles and runs all VHDL unit tests.
# The "run_all" function must be updated to add any new unit test or to
# change the simulation duration for an existing one.
#

# Find relevant VHDL files, add to project, and compile them all.
compile_all()
{
    # Create a new working folder with an empty .prj file.
    echo "******************** CREATING PROJECT"
    rm -rf xsim_tmp
    mkdir xsim_tmp
    echo -n > xsim_tmp/vhdl.prj

    # Define some helper functions:
    find_vhdl () {
        find $1 -name \*.vhd
    }
    add_to_prj () {
        sed -r 's/(.*)/vhdl xil_defaultlib \"..\/\1\"/' >> xsim_tmp/vhdl.prj
    }

    # Find source files in each folder.
    # Use "grep -v" to ignore specific filenames.
    find_vhdl "../../src/vhdl/common" | add_to_prj
    find_vhdl "../../src/vhdl/xilinx" | grep -v scrub_xilinx | add_to_prj
    find_vhdl "../../sim/vhdl" | add_to_prj

    # Compile design files
    echo "******************** COMPILING PROJECT"
    logfile=xsim_tmp/compile_vhdl.log
    opts_xvhdl="-m64 -relax -prj vhdl.prj -work xsim_tmp"
    (cd xsim_tmp && xvhdl $opts_xvhdl) 2>&1 | tee $logfile

    # Check for errors in the log.
    if grep ERROR $logfile; then
        echo "******************** COMPILE FAILED"
        return 1  # Compilation errors, can't run simulation
    else
        echo "******************** COMPILE SUCCESS"
        return 0  # No compile errors, proceed with simulation
    fi
}

# Simulate a single file ($1) for a given time ($2)
simulate_one()
{
    # Pre-simulation setup (aka "Elabortion")
    echo "******************** ELABORATING $1"
    opts_xelab="--relax --debug off --mt auto -m64 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot tb_snapshot"
    args_xelab="xil_defaultlib.$1 -log elaborate_$1.log"
    (cd xsim_tmp && xelab $opts_xelab $args_xelab)

    # Prep a TCL script for Vivado to run.
    echo "******************** SIMULATING $1 for $2"
    simcmd=cmd_tmp.tcl
    simout=simulate_$1.log
    echo "run $2" > xsim_tmp/$simcmd
    echo "quit" >> xsim_tmp/$simcmd

    # Launch simulation in XSIM.
    # To avoid giant logs on failure, limit the console output to the first
    # 1000 lines and limit simulation output to 20,000 lines.
    opts_xsim="-tclbatch $simcmd -onerror quit"
    (cd xsim_tmp && xsim tb_snapshot $opts_xsim -log $simout) | head -n 1000
    sed -i '20001,$ d' xsim_tmp/$simout
}

simulate_all()
{
    # Run each unit test for the designated time:
    simulate_one config_file2rom_tb 1us
    simulate_one config_mdio_rom_tb 30ms
    simulate_one config_port_eth_tb 4ms
    simulate_one config_port_uart_tb 16ms
    simulate_one config_send_status_tb 1ms
    simulate_one error_reporting_tb 10ms
    simulate_one eth_all8b10b_tb 2ms
    simulate_one eth_frame_adjust_tb 8ms
    simulate_one eth_frame_check_tb 2ms
    simulate_one io_spi_tb 1ms
    simulate_one lcd_control_tb 250ms
    simulate_one mac_lookup_tb 4ms
    simulate_one packet_delay_tb 1ms
    simulate_one packet_fifo_tb 10ms
    simulate_one port_rgmii_tb 1ms
    simulate_one port_rmii_tb 29ms
    simulate_one port_sgmii_common_tb 1ms
    simulate_one port_serial_auto_tb 200ms
    simulate_one port_serial_spi_tb 120ms
    simulate_one port_serial_uart_4wire_tb 700ms
    simulate_one port_serial_uart_2wire_tb 470ms
    simulate_one port_statistics_tb 2ms
    simulate_one round_robin_tb 20ms
    simulate_one sgmii_data_slip_tb 16ms
    simulate_one sgmii_serdes_rx_tb 1ms
    simulate_one sgmii_data_sync_tb 110ms
    simulate_one slip_decoder_tb 20us
    simulate_one slip_encoder_tb 4ms
    simulate_one switch_core_tb 12ms
}

# Initial setup
start_time=$(date +%T.%N)
source /opt/Xilinx/Vivado/2015.4/settings64.sh

# Create project and compile VHDL source.
# If successful, run all simulations.
compile_all && simulate_all

# Print elapsed time
end_time=$(date +%T.%N)
echo "Started: " $start_time
echo "Finished:" $end_time

