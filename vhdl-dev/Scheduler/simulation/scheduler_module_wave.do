onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /scheduler_simulation_tb/i1/clocks
add wave -noupdate -expand -group Scheduler -color Magenta /scheduler_simulation_tb/i1/scheduler_mod/ready
add wave -noupdate -expand -group Scheduler -color Magenta /scheduler_simulation_tb/i1/scheduler_mod/state
add wave -noupdate -expand -group Scheduler -radix hexadecimal /scheduler_simulation_tb/i1/scheduler_mod/measurement_out
add wave -noupdate -expand -group Scheduler -radix unsigned /scheduler_simulation_tb/i1/scheduler_mod/read_freq_setting
add wave -noupdate -expand -group Scheduler -radix unsigned /scheduler_simulation_tb/i1/scheduler_mod/div_number
add wave -noupdate -expand -group Scheduler -radix unsigned /scheduler_simulation_tb/i1/scheduler_mod/div_remainder
add wave -noupdate -expand -group Scheduler -radix unsigned /scheduler_simulation_tb/i1/scheduler_mod/REFERENCE_PRESS
add wave -noupdate -expand -group Scheduler -radix unsigned /scheduler_simulation_tb/i1/scheduler_mod/trigger
add wave -noupdate -expand -group Scheduler /scheduler_simulation_tb/i1/scheduler_mod/trigger_run
add wave -noupdate -expand -group Sensor -color Magenta /scheduler_simulation_tb/i1/scheduler_mod/sensor_mod/ready
add wave -noupdate -expand -group Sensor -color Magenta /scheduler_simulation_tb/i1/scheduler_mod/sensor_mod/enable
add wave -noupdate -expand -group Sensor -color Magenta /scheduler_simulation_tb/i1/scheduler_mod/sensor_mod/state
add wave -noupdate -expand -group {Test data} -radix hexadecimal /scheduler_simulation_tb/test_exp
add wave -noupdate -expand -group {Test data} -radix hexadecimal /scheduler_simulation_tb/test_got
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {30938915 ps} 0}
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
WaveRestoreZoom {0 ps} {83717063 ps}
