onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /display_simulation_tb/i1/clocks
add wave -noupdate /display_simulation_tb/i1/state
add wave -noupdate -radix binary /display_simulation_tb/i1/event_handler/events
add wave -noupdate -radix unsigned /display_simulation_tb/i1/seconds_cnt
add wave -noupdate -expand -group Settings -radix unsigned /display_simulation_tb/i1/read_freq_setting
add wave -noupdate -expand -group Settings -radix unsigned /display_simulation_tb/i1/pm10_norm
add wave -noupdate -expand -group Settings -radix unsigned /display_simulation_tb/i1/sample_size
add wave -noupdate -expand -group Storage -color Magenta /display_simulation_tb/i1/strg_enable
add wave -noupdate -expand -group Storage -color Magenta /display_simulation_tb/i1/strg_ready
add wave -noupdate -expand -group Storage /display_simulation_tb/i1/storage_mod/state
add wave -noupdate -expand -group Storage /display_simulation_tb/i1/strg_rw
add wave -noupdate -expand -group Storage -radix unsigned /display_simulation_tb/i1/storage_mod/timestamp
add wave -noupdate -expand -group Storage -radix unsigned /display_simulation_tb/i1/storage_mod/data_out
add wave -noupdate -expand -group Storage /display_simulation_tb/i1/strg_data_type
add wave -noupdate -group Sensor -color Magenta /display_simulation_tb/i1/scheduler_mod/sensor_mod/enable
add wave -noupdate -group Sensor -color Magenta /display_simulation_tb/i1/scheduler_mod/sensor_mod/ready
add wave -noupdate -group Sensor -radix unsigned /display_simulation_tb/i1/scheduler_mod/sens_temp
add wave -noupdate -group Sensor -radix unsigned /display_simulation_tb/i1/scheduler_mod/sens_hum
add wave -noupdate -group Sensor -radix unsigned /display_simulation_tb/i1/scheduler_mod/sens_pm10
add wave -noupdate -group Sensor -radix unsigned /display_simulation_tb/i1/scheduler_mod/sens_press
add wave -noupdate -expand -group Scheduler -color Magenta /display_simulation_tb/i1/scheduler_mod/ready
add wave -noupdate -expand -group Scheduler /display_simulation_tb/i1/scheduler_mod/state
add wave -noupdate -expand -group Scheduler -color {Cornflower Blue} -radix unsigned /display_simulation_tb/i1/scheduler_mod/trigger
add wave -noupdate -expand -group Scheduler -radix hexadecimal /display_simulation_tb/i1/scheduler_mod/measurement_out
add wave -noupdate -expand -group DataProcessor -color Magenta /display_simulation_tb/i1/processor_mod/enable
add wave -noupdate -expand -group DataProcessor -color Magenta /display_simulation_tb/i1/processor_mod/ready
add wave -noupdate -expand -group DataProcessor -radix unsigned /display_simulation_tb/i1/processor_mod/DATA_PROCESSOR/temp_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /display_simulation_tb/i1/processor_mod/DATA_PROCESSOR/hum_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /display_simulation_tb/i1/processor_mod/DATA_PROCESSOR/pm10_out
add wave -noupdate -expand -group DataProcessor -radix unsigned /display_simulation_tb/i1/processor_mod/DATA_PROCESSOR/press_out
add wave -noupdate -expand -group Display -radix unsigned /display_simulation_tb/i1/KEYS
add wave -noupdate -expand -group Display -color Magenta /display_simulation_tb/i1/display_mod/enable
add wave -noupdate -expand -group Display -color Magenta /display_simulation_tb/i1/display_mod/ready
add wave -noupdate -expand -group Display /display_simulation_tb/i1/display_mod/state
add wave -noupdate -expand -group Display -color {Cornflower Blue} -radix unsigned /display_simulation_tb/i1/display_mod/trigger
add wave -noupdate -expand -group Display -color {Cornflower Blue} /display_simulation_tb/i1/display_mod/trigger_rst
add wave -noupdate -expand -group Display -color {Cornflower Blue} /display_simulation_tb/i1/display_mod/trigger_ack
add wave -noupdate -expand -group Display -radix unsigned /display_simulation_tb/i1/display_mod/timeout
add wave -noupdate -expand -group Display -color Gold /display_simulation_tb/i1/display_mod/key_event
add wave -noupdate -expand -group Display -color Gold /display_simulation_tb/i1/display_mod/key_event_ack
add wave -noupdate -expand -group Display -color Gold /display_simulation_tb/i1/display_mod/key_event_syn
add wave -noupdate -expand -group Display -radix hexadecimal /display_simulation_tb/i1/display_mod/data
add wave -noupdate -expand -group Display /display_simulation_tb/i1/display_mod/disp_enable
add wave -noupdate -expand -group Display -radix unsigned -childformat {{/display_simulation_tb/i1/display_mod/disp_val(15) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(14) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(13) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(12) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(11) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(10) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(9) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(8) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(7) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(6) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(5) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(4) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(3) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(2) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(1) -radix unsigned} {/display_simulation_tb/i1/display_mod/disp_val(0) -radix unsigned}} -subitemconfig {/display_simulation_tb/i1/display_mod/disp_val(15) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(14) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(13) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(12) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(11) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(10) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(9) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(8) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(7) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(6) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(5) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(4) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(3) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(2) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(1) {-height 17 -radix unsigned} /display_simulation_tb/i1/display_mod/disp_val(0) {-height 17 -radix unsigned}} /display_simulation_tb/i1/display_mod/disp_val
add wave -noupdate -expand -group Display /display_simulation_tb/i1/display_mod/DISPLAY_CYCLER/now_showing
add wave -noupdate -expand -group Display /display_simulation_tb/i1/display_mod/dpoint
add wave -noupdate -expand -group Display /display_simulation_tb/i1/display_mod/display_drv/MLTPLX_CH
add wave -noupdate -radix unsigned /display_simulation_tb/test_exp
add wave -noupdate -radix unsigned /display_simulation_tb/test_got
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {375591981 ps} 0}
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
WaveRestoreZoom {0 ps} {42635292256 ps}
