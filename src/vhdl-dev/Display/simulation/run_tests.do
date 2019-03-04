# required external components
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl

# required ext
vcom -work ext -2008 -explicit -stats=none ../ext/div16.vhd
vcom -work ext -2008 -explicit -stats=none ../ext/div24.vhd
vcom -work ext -2008 -explicit -stats=none ../ext/mult24.vhd

# required drivers
vcom -work utils -2008 -explicit -stats=none mockups/fake_mem.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/sdram.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/eeprom.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/shift_reg.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_formats.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_a.vhdl

# required modules
vcom -work modules -2008 -explicit -stats=none mockups/Sensor.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Scheduler.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Scheduler_a.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage_a.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/DataProcessor.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/DataProcessor_a.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Display.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Display_a.vhdl

# code to test
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./display_module_tb.vht
vsim work.display_simulation_tb
do ./display_module_wave.do
run -all
