# required external components

# required ext
vcom -work ext -2008 -explicit -stats=none ../ext/div16.vhd
vcom -work ext -2008 -explicit -stats=none ../ext/spi_master.vhdl

# utils
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl
vcom -work utils -2008 -explicit -stats=none mockups/fake_mem.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/rn4020_utils.vhdl

# required modules (mockups)
vcom -work drivers -2008 -explicit -stats=none mockups/rn4020.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/eeprom.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/sdram.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/shift_reg.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_formats.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564.vhdl
vcom -work drivers -2008 -explicit -stats=none ../drivers/sm410564_a.vhdl

# required modules
vcom -work modules -2008 -explicit -stats=none ../modules/Communications.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Communications_a.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage_a.vhdl

# code to test
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./communications_module_tb.vht
vsim work.communications_simulation_tb
do ./communications_module_wave.do
run -all
