# required external components
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl

# required drivers (mockups)
vcom -work drivers -2008 -explicit -stats=none mockup/lps331ap.vhdl
vcom -work drivers -2008 -explicit -stats=none mockup/gp2y1010.vhdl
vcom -work drivers -2008 -explicit -stats=none mockup/dht11.vhdl

# required modules
vcom -work modules -2008 -explicit -stats=none ../modules/Sensor.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Sensor_a.vhdl

# required ext
vcom -work ext -2008 -explicit -stats=none ../ext/div16.vhd
vcom -work ext -2008 -explicit -stats=none ../ext/spi_master.vhdl

# required drivers
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_formats.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/shift_reg.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/shift_reg_a.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_a.vhdl

# code to test
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./sensor_module_tb.vht
vsim work.sensor_simulation_tb
do ./sensor_module_wave.do
run -all
