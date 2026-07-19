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
set prj_dir     [file normalize [lindex $argv 0]]
set top         [lindex $argv 1]
set vivado_base [lindex $argv 2]

cd $prj_dir/sim

# Generate XSIM config
set fp [open "xsim_cfg.tcl" w]
puts $fp "open_vcd waveform.vcd\ncatch {log_vcd \[get_objects -r /${top}_tb/*\]}\nrun 500ns\nclose_vcd\nexit"
close $fp

# Sanitize netlist header (Ubuntu OS-release injection workaround)
exec sed -i {1,20{/^[A-Z_][A-Z_]*="\?[^"]*$/d}} post_route_netlist.v

# Compile standard primitives & netlist
exec >@stdout xvlog $vivado_base/data/verilog/src/glbl.v post_route_netlist.v

set sv_tbs [glob -nocomplain $prj_dir/tb/*.sv]

if { [llength $sv_tbs] > 0 } {
    puts "--> Compiling SystemVerilog Testbench..."
    # Force any SystemVerilog packages to compile first
    foreach f [glob -nocomplain $prj_dir/src/*pkg.sv $prj_dir/tb/*pkg.sv] {
        exec >@stdout xvlog -sv -d GATE_SIM $f
    }
    
    # Compile remaining testbenches
    foreach f $sv_tbs {
        if {![string match "*pkg.sv" $f]} {
            exec >@stdout xvlog -sv -d GATE_SIM $f
        }
    }
} else {
    puts "--> Compiling VHDL Testbench..."
    foreach f [glob -nocomplain $prj_dir/tb/*.vhd] {
        exec >@stdout xvhdl -2008 $f
    }
}

puts "--> Elaborating Design with SDF Timing Annotation..."
# Elaborate
exec >@stdout xelab -debug typical -sdfmax /${top}_tb/uut=post_route.sdf -L simprims_ver -L unisims_ver -L unimacro_ver -L secureip work.${top}_tb work.glbl -s gate_sim

puts "--> Running Timing Simulation..."
# Simulate
exec >@stdout xsim gate_sim -tclbatch xsim_cfg.tcl
puts "--> Gate-level simulation completed successfully!"
