onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /bus_simulation_tb/i1/clocks
add wave -noupdate -radix unsigned /bus_simulation_tb/i1/seconds_cnt
add wave -noupdate /bus_simulation_tb/i1/state
add wave -noupdate -expand -group Scheduler -color Magenta /bus_simulation_tb/i1/scheduler_mod/state
add wave -noupdate -expand -group Scheduler -color Magenta /bus_simulation_tb/i1/scheduler_mod/ready
add wave -noupdate -expand -group Scheduler -radix unsigned /bus_simulation_tb/i1/scheduler_mod/trigger
add wave -noupdate -expand -group Scheduler /bus_simulation_tb/i1/scheduler_mod/SCHEDULER_SENSORS/trigger_handled
add wave -noupdate -expand -group Scheduler -radix unsigned /bus_simulation_tb/i1/scheduler_mod/SCHEDULER_SENSORS/sleep
add wave -noupdate -expand -group Scheduler -radix binary /bus_simulation_tb/i1/scheduler_mod/measurement_out
add wave -noupdate -expand -group Scheduler -radix decimal /bus_simulation_tb/i1/scheduler_mod/read_freq_setting
add wave -noupdate -expand -group Storage -color Magenta /bus_simulation_tb/i1/storage_mod/state
add wave -noupdate -expand -group Storage -color Magenta /bus_simulation_tb/i1/storage_mod/enable
add wave -noupdate -expand -group Storage -color Magenta /bus_simulation_tb/i1/storage_mod/ready
add wave -noupdate -expand -group Storage /bus_simulation_tb/i1/storage_mod/rw
add wave -noupdate -expand -group Storage -radix unsigned /bus_simulation_tb/i1/storage_mod/timestamp
add wave -noupdate -expand -group Storage /bus_simulation_tb/i1/storage_mod/data_type
add wave -noupdate -expand -group Storage /bus_simulation_tb/i1/storage_mod/data_in
add wave -noupdate -expand -group Storage -radix unsigned /bus_simulation_tb/i1/storage_mod/data_out
add wave -noupdate -expand -group {Test data} -radix hexadecimal /bus_simulation_tb/test_exp
add wave -noupdate -expand -group {Test data} -radix hexadecimal /bus_simulation_tb/test_got
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {31812714 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 138
configure wave -valuecolwidth 68
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
WaveRestoreZoom {0 ps} {98919417 ps}
