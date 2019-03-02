# required external components

# required ext
vcom -work ext -2008 -explicit -stats=none ../ext/div16.vhd
vcom -work ext -2008 -explicit -stats=none ../ext/div24.vhd
vcom -work ext -2008 -explicit -stats=none ../ext/mult24.vhd

# utils
vcom -work utils -2008 -explicit -stats=none ../utils/types.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider.vhdl
vcom -work utils -2008 -explicit -stats=none ../utils/clock_divider_a.vhdl
vcom -work segdispl -2008 -explicit -stats=none ../segdispl/types.vhdl

# required drivers
vcom -work utils -2008 -explicit -stats=none mockups/fake_mem.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/sdram.vhdl
vcom -work drivers -2008 -explicit -stats=none mockups/eeprom.vhdl
vcom -work segdispl -2008 -explicit -stats=none mockups/sm410564.vhdl

# required modules
vcom -work modules -2008 -explicit -stats=none mockups/Sensor.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Scheduler.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Scheduler_a.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/Storage_a.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/DataProcessor.vhdl
vcom -work modules -2008 -explicit -stats=none ../modules/DataProcessor_a.vhdl

# code to test
vcom -work work -2008 -explicit -stats=none ../Main.vhdl
vcom -work work -2008 -explicit -stats=none ../Main_a.vhdl

# additional test utils
vcom -work work ./image_pb.vhdl

# test bench and running
vcom -work work -2008 ./data_processor_module_tb.vht
vsim work.dataproc_simulation_tb
do ./data_processor_module_wave.do
run -all
