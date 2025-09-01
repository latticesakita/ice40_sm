set current_path "O:/src/Propel/iCE40UP/ice40_sm"

cd $current_path

set radiant_project "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm.rdf"

set DEVICE "iCE40UP5K-SG48I"

set DESIGN "ice40_sm"

array set VFILE_LIST ""
set VFILE_LIST(1) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/ice40_sm_top.v"
set VFILE_LIST(2) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/timer/1.0.0/timer.ipx"
set VFILE_LIST(3) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/latticesemi.com/ip/cpu/1.8.0/cpu.ipx"
set VFILE_LIST(4) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/system0/1.0.0/system0.ipx"
set VFILE_LIST(5) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/gpio/1.0.0/gpio.ipx"
set VFILE_LIST(6) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/system1/1.0.0/system1.ipx"
set VFILE_LIST(7) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/uart/1.0.0/uart.ipx"
set VFILE_LIST(8) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/latticesemi.com/module/ahb_brg/1.4.0/ahb_brg.ipx"
set VFILE_LIST(9) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/ice40_ip_if/1.0.0/ice40_ip_if.ipx"
set VFILE_LIST(10) "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/ice40_sm.v"

set index [array names VFILE_LIST]
if { [file exists $radiant_project] == 1} {
    prj_open $radiant_project
    prj_set_device -part $DEVICE -performance High-Performance_1.2V
} else {
    prj_create -name "ice40_sm" -impl "impl_1" -dev $DEVICE -performance High-Performance_1.2V -synthesis "synplify"
    prj_save
}

prj_remove_source "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/dram_if/1.0.0/dram_if.ipx"
prj_remove_source "O:/src/Propel/iCE40UP/ice40_sm/ice40_sm/lib/personal/ip/spram_if/1.0.0/spram_if.ipx"

foreach i $index {
    if { [catch {prj_add_source $VFILE_LIST($i)} fid] } {
        puts "file already exists in project."
    }
}

prj_save

