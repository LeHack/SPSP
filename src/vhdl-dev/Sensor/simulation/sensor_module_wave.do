onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sensor_simulation_tb/i1/clocks
add wave -noupdate -expand -group Sensor -color Magenta /sensor_simulation_tb/i1/sensor_mod/ready
add wave -noupdate -expand -group Sensor -color Magenta /sensor_simulation_tb/i1/sensor_mod/enable
add wave -noupdate -expand -group Sensor -color Magenta /sensor_simulation_tb/i1/sensor_mod/state
add wave -noupdate -expand -group Sensor /sensor_simulation_tb/i1/sensor_mod/SENSOR_MANAGER/enable_fired
add wave -noupdate -expand -group Sensor -radix unsigned /sensor_simulation_tb/i1/sens_temp
add wave -noupdate -expand -group Sensor -radix unsigned /sensor_simulation_tb/i1/sens_press
add wave -noupdate -expand -group Sensor -radix unsigned /sensor_simulation_tb/i1/sens_pm10
add wave -noupdate -expand -group Sensor -radix unsigned /sensor_simulation_tb/i1/sens_hum
add wave -noupdate -expand -group PM10 -color Magenta /sensor_simulation_tb/i1/sensor_mod/pm10sensor/enable
add wave -noupdate -expand -group PM10 -color Magenta /sensor_simulation_tb/i1/sensor_mod/pm10sensor/ready
add wave -noupdate -expand -group PM10 -color Magenta /sensor_simulation_tb/i1/sensor_mod/pm10sensor/state
add wave -noupdate -expand -group LPS331 -color Magenta /sensor_simulation_tb/i1/sensor_mod/pressure_sensor/enable
add wave -noupdate -expand -group LPS331 -color Magenta /sensor_simulation_tb/i1/sensor_mod/pressure_sensor/ready
add wave -noupdate -expand -group LPS331 -color Magenta /sensor_simulation_tb/i1/sensor_mod/pressure_sensor/state
add wave -noupdate -expand -group DHT11 -color Magenta /sensor_simulation_tb/i1/sensor_mod/humidity_sensor/enable
add wave -noupdate -expand -group DHT11 -color Magenta /sensor_simulation_tb/i1/sensor_mod/humidity_sensor/ready
add wave -noupdate -expand -group DHT11 -color Magenta /sensor_simulation_tb/i1/sensor_mod/humidity_sensor/state
add wave -noupdate -expand -group {Test data} -radix hexadecimal /sensor_simulation_tb/test_exp
add wave -noupdate -expand -group {Test data} -radix hexadecimal /sensor_simulation_tb/test_got
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7540000 ps} 0}
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
WaveRestoreZoom {0 ps} {89663944 ps}
