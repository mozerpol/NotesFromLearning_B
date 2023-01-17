###### Set module name only ######
set module        "all_gates"


# THE EASIEST WAY IS RUN SCRIPT FROM OTHER PROJECT INSIDE THIS PROJECT. JUST nest
# tcl script inside other tcl script. Thanks to this, I'll receive library which
# will include to the project easily. 
# https://support.xilinx.com/s/question/0D52E00006hprYZSAY/nested-tcl-scripts?language=en_US

##################################
#         PROJECT TREE:
#
# |___folder_example_name
# |   |___design.vhd
# |   |___testbench.vhd
# |   |___package.vhd
# |   |
# |   |___scripts
# |       |___script.tcl (this file)
# |       |___waveforms.do
# 
#         RULES:
# Design, testbench must have the VHD extension
# Waveforms must have the DO extension
# Script must have the TCL extension
#
#         HOW TO RUN:
# Go to directory where is script.tcl and run command: do script.tcl

set lib_name         $module\_lib
set design_name      ../$module\_design
set test_name        ../$module\_tb
set package_name     ../$module\_pkg
set waveforms        $module\_lib.$module\_tb
set systemTime_start [clock seconds]
set systemTime_end   [clock seconds]

set hdl_dir ../../and_gate
vcom -2008 -quiet -work and_gate_lib $hdl_dir/and_gate_pkg.vhd
vcom -2008 -quiet -work and_gate_lib $hdl_dir/and_gate_design.vhd

set hdl_dir ../../or_gate
vcom -2008 -quiet -work or_gate_lib $hdl_dir/or_gate_pkg.vhd
vcom -2008 -quiet -work or_gate_lib $hdl_dir/or_gate_design.vhd

proc s_create_lib_main {} {
    global lib_name
    echo "----> Create library:"
    if {[file exists $lib_name/_info]} {
       echo "Library already exists"
    } else {
       echo "Library $lib_name don't exist"
       echo "Create library inside: [pwd]"
       vlib $lib_name
    }
}

proc s_map_lib_main {} {
    global lib_name
    echo "----> Map library:"
    vmap $lib_name $lib_name
}

proc s_comp_package_main {} {
    global package_name lib_name
    echo "----> Compile files:"
    echo "-> Package"
    if {[file exist $package_name.vhd]} {
       vcom -2008 -quiet -work $lib_name $package_name.vhd
    } else {
       return "File $package_name not found, stop script"
    }
}

proc s_comp_design_main {} {
    global design_name lib_name
    echo "-> Design"
    if {[file exist $design_name.vhd]} {
       vcom -2008 -quiet -work $lib_name $design_name.vhd 
    } else {
       return "File $design_name not found, stop script"
    }
}

proc s_comp_test_main {} {
    global test_name lib_name
    echo "-> Testbench"
    if {[file exist $test_name.vhd]} {
       vcom -2008 -quiet -work $lib_name $test_name.vhd
    } else {
       return "File $test_name not found, stop script"
    }
}

proc s_load_waves {} {
    global waveforms
    echo "----> Load waveforms:"
    if {[file exist waveforms.do]} {
       vsim -voptargs=+acc $waveforms 
       # voptargs=+acc - Apply full visibility to all modules, Questa need this, may
       # in Modelsim can delete
       view wave -undock -title wave_TOP
       do waveforms.do
       echo "-> Waveform loaded"
    } else {
       echo "File waveforms.do not found"
    }
}

proc s_start_sim {} {
    echo "----> Run tests"
    run -all
    # Simstats time
    echo "Simulation start time : [clock format $systemTime_start -format %H:%M:%S]"
    echo "Simulation end time   : [clock format $systemTime_end -format %H:%M:%S]"
    echo "Simulation time       : [expr {$systemTime_end - $systemTime_start}] sec."
}

s_create_lib_main
s_map_lib_main
s_comp_package_main
s_comp_design_main
s_comp_test_main
s_load_waves
s_start_sim
