# required external components
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl

# required modules
vcom -work modules -2008 -explicit -stats=none mockups/Storage.vhdl
vcom -work modules -2008 -explicit -stats=none mockups/Scheduler.vhdl

# code to test
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work -2008 ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./bus_tb.vht
vsim work.bus_simulation_tb
do ./bus_wave.do
run -all
