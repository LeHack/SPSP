onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dataproc_simulation_tb/i1/clocks
add wave -noupdate /dataproc_simulation_tb/i1/state
add wave -noupdate -radix unsigned /dataproc_simulation_tb/i1/seconds_cnt
add wave -noupdate -expand -group Settings -radix unsigned /dataproc_simulation_tb/i1/read_freq_setting
add wave -noupdate -expand -group Settings -radix unsigned /dataproc_simulation_tb/i1/pm10_norm
add wave -noupdate -expand -group Settings -radix unsigned /dataproc_simulation_tb/i1/sample_size
add wave -noupdate -group Storage /dataproc_simulation_tb/i1/storage_mod/state
add wave -noupdate -group Storage /dataproc_simulation_tb/i1/strg_enable
add wave -noupdate -group Storage /dataproc_simulation_tb/i1/strg_ready
add wave -noupdate -group Storage /dataproc_simulation_tb/i1/strg_rw
add wave -noupdate -group Storage -radix unsigned /dataproc_simulation_tb/i1/storage_mod/timestamp
add wave -noupdate -group Storage /dataproc_simulation_tb/i1/strg_data_type
add wave -noupdate -group Sensor /dataproc_simulation_tb/i1/scheduler_mod/sens_ready
add wave -noupdate -group Sensor -radix unsigned /dataproc_simulation_tb/i1/scheduler_mod/sens_temp
add wave -noupdate -group Sensor -radix unsigned /dataproc_simulation_tb/i1/scheduler_mod/sens_hum
add wave -noupdate -group Sensor -radix unsigned /dataproc_simulation_tb/i1/scheduler_mod/sens_pm10
add wave -noupdate -group Sensor -radix unsigned /dataproc_simulation_tb/i1/scheduler_mod/sens_press
add wave -noupdate -expand -group Scheduler /dataproc_simulation_tb/i1/scheduler_mod/state
add wave -noupdate -expand -group Scheduler /dataproc_simulation_tb/i1/scheduler_mod/ready
add wave -noupdate -expand -group Scheduler -radix hexadecimal /dataproc_simulation_tb/i1/scheduler_mod/measurement_out
add wave -noupdate -expand -group Scheduler /dataproc_simulation_tb/i1/scheduler_mod/sens_enable
add wave -noupdate -expand -group Scheduler /dataproc_simulation_tb/i1/scheduler_mod/sens_ready
add wave -noupdate -expand -group Scheduler -radix unsigned /dataproc_simulation_tb/i1/scheduler_mod/trigger
add wave -noupdate -expand -group DataProcessor /dataproc_simulation_tb/i1/processor_mod/enable
add wave -noupdate -expand -group DataProcessor /dataproc_simulation_tb/i1/processor_mod/ready
add wave -noupdate -expand -group DataProcessor /dataproc_simulation_tb/i1/processor_mod/state
add wave -noupdate -expand -group DataProcessor /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/step
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_in
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/hum_in
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/pm10_in
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/press_in
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/hum_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/pm10_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/press_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_prev
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_cached
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_avg
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/sample_half
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/div_number
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/div_denominator
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/div_quotient
add wave -noupdate -expand -group DataProcessor -radix unsigned /dataproc_simulation_tb/i1/processor_mod/div_remainder
add wave -noupdate -expand -group DataProcessor -radix hexadecimal /dataproc_simulation_tb/i1/processor_mod/data_in
add wave -noupdate -expand -group DataProcessor -radix hexadecimal /dataproc_simulation_tb/i1/processor_mod/data_out
add wave -noupdate -radix unsigned /dataproc_simulation_tb/test_exp
add wave -noupdate -radix unsigned /dataproc_simulation_tb/test_got
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4871915284 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 116
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
WaveRestoreZoom {14796968167 ps} {14853170097 ps}
