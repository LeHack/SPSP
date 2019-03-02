onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /storage_simulation_tb/i1/clocks
add wave -noupdate /storage_simulation_tb/i1/state
add wave -noupdate -expand -group Input /storage_simulation_tb/KEY
add wave -noupdate -expand -group Input /storage_simulation_tb/DIPSW
add wave -noupdate -expand -group Display -radix hexadecimal /storage_simulation_tb/i1/display/dvalue
add wave -noupdate -expand -group Display /storage_simulation_tb/i1/display/dpoint
add wave -noupdate -group SDRAM -color Magenta /storage_simulation_tb/i1/storage_drv/sdram/enable
add wave -noupdate -group SDRAM -color Magenta /storage_simulation_tb/i1/storage_drv/sdram/ready
add wave -noupdate -group SDRAM -radix hexadecimal /storage_simulation_tb/i1/storage_drv/sdram/addr
add wave -noupdate -group SDRAM /storage_simulation_tb/i1/storage_drv/sdram/rw
add wave -noupdate -group SDRAM -radix hexadecimal -childformat {{/storage_simulation_tb/i1/storage_drv/sdram/data_out(15) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(14) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(13) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(12) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(11) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(10) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(9) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(8) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(7) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(6) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(5) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(4) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(3) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(2) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(1) -radix unsigned} {/storage_simulation_tb/i1/storage_drv/sdram/data_out(0) -radix unsigned}} -subitemconfig {/storage_simulation_tb/i1/storage_drv/sdram/data_out(15) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(14) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(13) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(12) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(11) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(10) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(9) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(8) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(7) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(6) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(5) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(4) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(3) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(2) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(1) {-height 17 -radix unsigned} /storage_simulation_tb/i1/storage_drv/sdram/data_out(0) {-height 17 -radix unsigned}} /storage_simulation_tb/i1/storage_drv/sdram/data_out
add wave -noupdate -group SDRAM -radix hexadecimal /storage_simulation_tb/i1/storage_drv/sdram/data_in
add wave -noupdate -group SDRAM -radix hexadecimal /storage_simulation_tb/i1/storage_drv/sdram/fake_memory
add wave -noupdate -expand -group EEPROM -color Magenta /storage_simulation_tb/i1/storage_drv/eeprom/enable
add wave -noupdate -expand -group EEPROM -color Magenta /storage_simulation_tb/i1/storage_drv/eeprom/ready
add wave -noupdate -expand -group EEPROM -radix decimal /storage_simulation_tb/i1/storage_drv/eeprom/addr
add wave -noupdate -expand -group EEPROM /storage_simulation_tb/i1/storage_drv/eeprom/rw
add wave -noupdate -expand -group EEPROM -radix hexadecimal /storage_simulation_tb/i1/storage_drv/eeprom/data_in
add wave -noupdate -expand -group EEPROM -radix hexadecimal /storage_simulation_tb/i1/storage_drv/eeprom/data_out
add wave -noupdate -expand -group EEPROM -radix hexadecimal /storage_simulation_tb/i1/storage_drv/eeprom/fake_memory
add wave -noupdate -expand -group {Test data} -color Magenta /storage_simulation_tb/i1/storage_drv/enable
add wave -noupdate -expand -group {Test data} -color Magenta /storage_simulation_tb/i1/storage_drv/ready
add wave -noupdate -expand -group {Test data} /storage_simulation_tb/i1/storage_drv/io_stage
add wave -noupdate -expand -group {Test data} -color Firebrick /storage_simulation_tb/i1/storage_drv/error
add wave -noupdate -expand -group {Test data} -radix hexadecimal /storage_simulation_tb/i1/storage_drv/data_in
add wave -noupdate -expand -group {Test data} -radix hexadecimal /storage_simulation_tb/i1/storage_drv/data_out
add wave -noupdate -expand -group {Test data} /storage_simulation_tb/i1/storage_drv/data_type
add wave -noupdate -expand -group {Test data} /storage_simulation_tb/i1/storage_drv/overflow
add wave -noupdate -expand -group {Test data} /storage_simulation_tb/i1/storage_drv/reset_settings
add wave -noupdate -expand -group {Test data} /storage_simulation_tb/i1/storage_drv/rw
add wave -noupdate -expand -group {Test data} /storage_simulation_tb/i1/storage_drv/state
add wave -noupdate -expand -group {Test data} -radix unsigned /storage_simulation_tb/i1/storage_drv/timestamp
add wave -noupdate -radix hexadecimal /storage_simulation_tb/test_exp
add wave -noupdate -radix hexadecimal /storage_simulation_tb/test_got
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4685401693 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 148
configure wave -valuecolwidth 67
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 20000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {4660027009 ps} {4731551636 ps}
