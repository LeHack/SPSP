# required external components
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl

# required ext
vcom -work ext -2008 -explicit -stats=none ../ext/div16.vhd

# required modules
vcom -work modules -2008 -explicit -stats=none mockups/Sensor.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Scheduler.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Scheduler_a.vhdl

# code to test
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./scheduler_module_tb.vht
vsim work.scheduler_simulation_tb
do ./scheduler_module_wave.do
run -all
