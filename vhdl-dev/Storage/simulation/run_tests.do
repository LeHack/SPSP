# required external components
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl
vcom -work ext -2008 -explicit -stats=none ../ext/div16.vhd

# Mockups
vcom -work utils -2008 -explicit -stats=none mockups/fake_mem.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/eeprom.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/sdram.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/shift_reg.vhdl

# Drivers
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_formats.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_a.vhdl

# code to test
vcom -work modules -2008 -explicit -stats=none ../modules/Storage.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage_a.vhdl
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./storage_module_tb.vht
vsim work.storage_simulation_tb
do ./storage_module_wave.do
run -all
