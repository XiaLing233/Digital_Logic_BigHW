######################################################################
#
# File name : sel_display7_tb_simulate.do
# Created on: Fri Dec 06 15:00:26 +0800 2024
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vsim -voptargs="+acc" -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -lib xil_defaultlib xil_defaultlib.sel_display7_tb xil_defaultlib.glbl

do {sel_display7_tb_wave.do}

view wave
view structure
view signals

do {sel_display7_tb.udo}

run 1000ns
