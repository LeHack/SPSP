onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /spsp_simulation_tb/i1/seconds_cnt
add wave -noupdate -expand -group Settings -radix unsigned /spsp_simulation_tb/i1/HZ_DURATION
add wave -noupdate -expand -group Settings -radix unsigned /spsp_simulation_tb/i1/read_freq_setting
add wave -noupdate -expand -group Settings -radix unsigned /spsp_simulation_tb/i1/pm10_norm
add wave -noupdate -expand -group Settings -radix unsigned /spsp_simulation_tb/i1/sample_size
add wave -noupdate -expand -group Settings -radix unsigned /spsp_simulation_tb/i1/disp_timeout
add wave -noupdate -expand -group Settings /spsp_simulation_tb/i1/comms_btname
add wave -noupdate -expand -group Settings -radix decimal /spsp_simulation_tb/i1/pressure_ref
add wave -noupdate -expand -group Storage -color Magenta /spsp_simulation_tb/i1/storage_mod/enable
add wave -noupdate -expand -group Storage -color Magenta /spsp_simulation_tb/i1/storage_mod/ready
add wave -noupdate -expand -group Storage -radix hexadecimal /spsp_simulation_tb/i1/storage_mod/data_in
add wave -noupdate -expand -group Storage -radix hexadecimal /spsp_simulation_tb/i1/storage_mod/data_out
add wave -noupdate -expand -group Storage /spsp_simulation_tb/i1/storage_mod/data_type
add wave -noupdate -expand -group Sensor -color Magenta /spsp_simulation_tb/i1/scheduler_mod/sensor_mod/enable
add wave -noupdate -expand -group Sensor -color Magenta /spsp_simulation_tb/i1/scheduler_mod/sensor_mod/ready
add wave -noupdate -expand -group Sensor -radix unsigned /spsp_simulation_tb/i1/scheduler_mod/sensor_mod/humidity
add wave -noupdate -expand -group Sensor -radix unsigned /spsp_simulation_tb/i1/scheduler_mod/sensor_mod/pm10_reading
add wave -noupdate -expand -group Sensor -radix unsigned /spsp_simulation_tb/i1/scheduler_mod/sensor_mod/pressure
add wave -noupdate -expand -group Sensor -radix unsigned /spsp_simulation_tb/i1/scheduler_mod/sensor_mod/temperature
add wave -noupdate -expand -group Scheduler -color Magenta /spsp_simulation_tb/i1/scheduler_mod/ready
add wave -noupdate -expand -group Scheduler /spsp_simulation_tb/i1/scheduler_mod/trigger_run
add wave -noupdate -expand -group Scheduler -radix unsigned /spsp_simulation_tb/i1/scheduler_mod/trigger
add wave -noupdate -expand -group DataProcessor -color Magenta /spsp_simulation_tb/i1/processor_mod/enable
add wave -noupdate -expand -group DataProcessor -color Magenta /spsp_simulation_tb/i1/processor_mod/ready
add wave -noupdate -expand -group DataProcessor -radix unsigned /spsp_simulation_tb/i1/processor_mod/DATA_PROCESSOR/press_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /spsp_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /spsp_simulation_tb/i1/processor_mod/DATA_PROCESSOR/hum_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /spsp_simulation_tb/i1/processor_mod/DATA_PROCESSOR/pm10_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /spsp_simulation_tb/i1/processor_mod/DATA_PROCESSOR/pm10_perc_out
add wave -noupdate -expand -group Display -color Magenta /spsp_simulation_tb/i1/display_mod/enable
add wave -noupdate -expand -group Display -color Magenta /spsp_simulation_tb/i1/display_mod/ready
add wave -noupdate -expand -group Display -radix unsigned /spsp_simulation_tb/i1/display_mod/trigger
add wave -noupdate -expand -group Display /spsp_simulation_tb/i1/display_mod/disp_enable
add wave -noupdate -expand -group Display -radix unsigned /spsp_simulation_tb/i1/display_mod/disp_val
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {332844318 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 173
configure wave -valuecolwidth 75
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
WaveRestoreZoom {0 ps} {942613760 ps}
