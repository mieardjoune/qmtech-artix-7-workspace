#  Copyright 2026 M. I. E. ARDJOUNE
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# ==============================================================================
# Xilinx UG949 Compliant Synthesis & Implementation Script
# Target: QMTECH Artix-7 (xc7a100tfgg676-1)
# ==============================================================================
set prj_dir    [lindex $argv 0]
set top_module [lindex $argv 1]

set part "xc7a100tfgg676-1"

set output_dir ${prj_dir}/build
set report_dir ${prj_dir}/reports

# Performance optimizations (UG949)
set_param general.maxThreads 8
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter max_loop_limit 100000"

# Read generics/parameters safely
set generics_list {}
if {[file exists ${prj_dir}/params.txt]} {
    set fp [open ${prj_dir}/params.txt r]
    foreach line [split [read $fp] "\n"] {
        set trimmed [string trim $line]
        if {$trimmed != ""} { lappend generics_list $trimmed }
    }
    close $fp
}

# Read Sources (IEEE 1800-2012 and IEEE 1076-2008)
foreach f [glob -nocomplain ${prj_dir}/src/*.v ${prj_dir}/src/*.sv] { read_verilog -sv $f }
foreach f [glob -nocomplain ${prj_dir}/src/*.vhd ${prj_dir}/src/*.vhdl] { read_vhdl $f }
foreach f [glob -nocomplain ${prj_dir}/constraints/*.xdc] { read_xdc $f }

# Synthesis Phase
if { [llength $generics_list] > 0 } {
    synth_design -top $top_module -part $part -generic $generics_list -assert
} else {
    synth_design -top $top_module -part $part -assert
}

# Implementation Phase (place/route/physopt run with the Explore directive,
# which trades longer runtime for better QoR)
opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore

# Strict Timing Check (Fail Fast)
set timing_paths [get_timing_paths -delay_type min_max -max_paths 1]
if { [llength $timing_paths] > 0 } {
    set wns [get_property SLACK $timing_paths]
    puts "Worst Negative Slack (WNS): $wns ns"
    if { $wns < 0.0 } {
        puts "CRITICAL WARNING: Timing constraints violated (WNS = $wns ns). Design will fail on hardware!"
        exit 1
    }
} else {
    puts "INFO: No internal constrained timing paths found. Skipping WNS verification."
}

# Generate Outputs Safely
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

if {[catch {write_bitstream -bin_file -force $output_dir/${top_module}.bit} err]} {
    puts "CRITICAL ERROR: Bitstream generation failed: $err"
    exit 1
}

# Export Verilog Netlist & Standard Delay Format (SDF) for accurate Gate-Level Simulation
if {[catch {
    write_verilog -mode timesim -sdf_anno true -force ${prj_dir}/sim/post_route_netlist.v
    write_sdf -mode timesim -force ${prj_dir}/sim/post_route.sdf
} err]} {
    puts "CRITICAL ERROR: Timing netlist extraction failed: $err"
    exit 1
}

# Comprehensive Reporting
report_timing_summary -file $report_dir/timing_summary.txt
report_utilization -file $report_dir/utilization.txt
report_power -file $report_dir/power.txt
report_methodology -file $report_dir/methodology.txt
exit 0
