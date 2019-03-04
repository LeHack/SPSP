EESchema Schematic File Version 4
LIBS:sensors_and_display_boards-cache
EELAYER 26 0
EELAYER END
$Descr User 7875 5906
encoding utf-8
Sheet 2 3
Title "Sensors board"
Date "2017-06-16"
Rev "1"
Comp "Łukasz Hejnak"
Comment1 "Pressure/temperature, humidity and PM10 sensor board"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text HLabel 907  1233 1    60   3State ~ 0
GP2Y-LED
Text HLabel 985  1233 1    60   Input ~ 0
GP2Y-GND
Text HLabel 1063 1233 1    60   Output ~ 0
GP2Y-V0
Text HLabel 1143 1233 1    60   Input ~ 0
GP2Y-Vcc
$Comp
L spsp_components:GP2Y1010AU0F U1
U 1 1 5A5E1552
P 2975 2053
F 0 "U1" H 3843 1703 60  0000 C CNN
F 1 "GP2Y1010AU0F" H 3855 1603 60  0000 C CNN
F 2 "Labels:Blank" H 2975 2053 60  0001 C CNN
F 3 "" H 2975 2053 60  0001 C CNN
	1    2975 2053
	1    0    0    -1  
$EndComp
$Comp
L sensors_and_display_boards-rescue:CP1 C1
U 1 1 5A5E1772
P 1905 2097
F 0 "C1" H 1930 2197 50  0000 L CNN
F 1 "220uF" H 1930 1997 50  0000 L CNN
F 2 "Capacitors_THT:CP_Radial_Tantal_D6.0mm_P2.50mm" H 1905 2097 50  0001 C CNN
F 3 "" H 1905 2097 50  0001 C CNN
	1    1905 2097
	1    0    0    -1  
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R1
U 1 1 5A5E1818
P 1563 1845
F 0 "R1" V 1643 1845 50  0000 C CNN
F 1 "150" V 1563 1845 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 1493 1845 50  0001 C CNN
F 3 "" H 1563 1845 50  0001 C CNN
	1    1563 1845
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:Conn_02x07_Odd_Even J2
U 1 1 5A5E1AE0
P 1755 4505
F 0 "J2" H 1805 4905 50  0000 C CNN
F 1 "Conn_02x07_Odd_Even" H 1805 4105 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x07_Pitch2.54mm" H 1755 4505 50  0001 C CNN
F 3 "" H 1755 4505 50  0001 C CNN
	1    1755 4505
	1    0    0    -1  
$EndComp
NoConn ~ 1555 4805
$Comp
L spsp_components:DHT11 U2
U 1 1 5A5ED0B8
P 4400 3212
F 0 "U2" H 4756 3058 50  0000 C CNN
F 1 "DHT11" H 4748 2944 50  0000 C CNN
F 2 "footprints:DHT11" H 4550 3462 50  0001 C CNN
F 3 "" H 4550 3462 50  0001 C CNN
	1    4400 3212
	1    0    0    -1  
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R2
U 1 1 5A5ED4D5
P 3629 3329
F 0 "R2" V 3709 3329 50  0000 C CNN
F 1 "5k" V 3629 3329 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 3559 3329 50  0001 C CNN
F 3 "" H 3629 3329 50  0001 C CNN
	1    3629 3329
	0    1    1    0   
$EndComp
Text HLabel 2889 3143 0    60   Input ~ 0
DHT-Vcc
Text HLabel 2890 3428 0    60   Input ~ 0
DHT-DATA
Text HLabel 2889 3526 0    60   Input ~ 0
DHT-GND
$Comp
L spsp_components:LPS331AP U3
U 1 1 5A5F01B0
P 5761 2408
F 0 "U3" H 5817 2458 60  0000 C CNN
F 1 "LPS331AP" H 5829 2348 60  0000 C CNN
F 2 "Labels:Blank" H 5661 3358 40  0001 C CNN
F 3 "" H 5661 3358 40  0000 C CNN
	1    5761 2408
	-1   0    0    -1  
$EndComp
NoConn ~ 6261 2092
NoConn ~ 6261 2782
NoConn ~ 6261 2880
Text HLabel 6591 1158 1    60   Input ~ 0
LPS-Vin
Text HLabel 6690 1158 1    60   Input ~ 0
LPS-GND
Text HLabel 6787 1158 1    60   3State ~ 0
LPS-SDA
Text HLabel 6885 1158 1    60   3State ~ 0
LPS-SCL
Text HLabel 6984 1158 1    60   3State ~ 0
LPS-SDO
Entry Wire Line
	7048 2192 7148 2292
Entry Wire Line
	7048 2290 7148 2390
Entry Wire Line
	7048 2389 7148 2489
Entry Wire Line
	7048 2486 7148 2586
Entry Wire Line
	7048 2586 7148 2686
Entry Wire Line
	7048 2192 7148 2292
Text Label 7047 2192 0    10   ~ 0
LPS-Vin
Text Label 7047 2290 0    10   ~ 0
LPS-GND
Text Label 7046 2389 0    10   ~ 0
LPS-SDA
Text Label 7047 2486 0    10   ~ 0
LPS-SCL
Text Label 7047 2586 0    10   ~ 0
LPS-SDO
Entry Wire Line
	1533 4205 1433 4305
Entry Wire Line
	1533 4305 1433 4405
Entry Wire Line
	1533 4405 1433 4505
Entry Wire Line
	1533 4505 1433 4605
Entry Wire Line
	1533 4605 1433 4705
Text Label 1534 4205 2    39   ~ 0
LPS-Vin
Text Label 2066 4205 0    39   ~ 0
LPS-GND
Text Label 1535 4305 2    39   ~ 0
LPS-SDA
Text Label 1536 4405 2    39   ~ 0
LPS-SCL
Text Label 2066 4305 0    39   ~ 0
LPS-SDO
Entry Wire Line
	2067 4205 2167 4305
Entry Wire Line
	2067 4305 2167 4405
Entry Wire Line
	2067 4405 2167 4505
Entry Wire Line
	2067 4505 2167 4605
Entry Wire Line
	2067 4605 2167 4705
Entry Wire Line
	2067 4705 2167 4805
Entry Wire Line
	1433 4805 1533 4705
Entry Wire Line
	3125 3243 3225 3143
Entry Wire Line
	3125 3528 3225 3428
Entry Wire Line
	3125 3626 3225 3526
Text Label 3228 3143 0    10   ~ 0
DHT-Vcc
Text Label 3224 3428 0    10   ~ 0
DHT-DATA
Text Label 3225 3526 0    10   ~ 0
DHT-GND
Text Label 2065 4405 0    39   ~ 0
DHT-DATA
Entry Wire Line
	793  2365 893  2265
Entry Wire Line
	793  2465 893  2365
Entry Wire Line
	793  2565 893  2465
Entry Wire Line
	793  2665 893  2565
Text Label 895  2265 2    10   ~ 0
GP2Y-Vcc
Text Label 898  2365 2    10   ~ 0
GP2Y-LED
Text Label 894  2465 2    10   ~ 0
GP2Y-GND
Text Label 894  2565 2    10   ~ 0
GP2Y-V0
Text Label 1534 4505 2    39   ~ 0
DHT-Vcc
Text Label 2066 4505 0    39   ~ 0
DHT-GND
Text Label 1534 4605 2    39   ~ 0
GP2Y-Vcc
Text Label 2066 4605 0    39   ~ 0
GP2Y-LED
Text Label 2067 4705 0    39   ~ 0
GP2Y-GND
Text Label 1535 4705 2    39   ~ 0
GP2Y-V0
NoConn ~ 2055 4805
Text GLabel 2066 4205 2    10   Output ~ 0
DGND
Text GLabel 2066 4505 2    10   Output ~ 0
DGND
Text GLabel 2066 4705 2    10   Output ~ 0
AGND
$Comp
L sensors_and_display_boards-rescue:Conn_02x07_Odd_Even J3
U 1 1 5A6E0A78
P 4741 1444
F 0 "J3" H 4791 1844 50  0000 C CNN
F 1 "Conn_02x07_Odd_Even" H 4791 1044 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x07_Pitch2.54mm" H 4741 1444 50  0001 C CNN
F 3 "" H 4741 1444 50  0001 C CNN
	1    4741 1444
	1    0    0    -1  
$EndComp
NoConn ~ 5041 1744
NoConn ~ 4541 1744
$Comp
L sensors_and_display_boards-rescue:C C2
U 1 1 5A6E3AB1
P 4029 3817
AR Path="/5A6E3AB1" Ref="C2"  Part="1" 
AR Path="/5A5DD67B/5A6E3AB1" Ref="C2"  Part="1" 
F 0 "C2" H 4054 3917 50  0000 L CNN
F 1 "50nF" H 4054 3717 50  0000 L CNN
F 2 "Capacitors_THT:C_Disc_D4.3mm_W1.9mm_P5.00mm" H 4067 3667 50  0001 C CNN
F 3 "" H 4029 3817 50  0001 C CNN
	1    4029 3817
	0    -1   -1   0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:C C3
U 1 1 5A6E3F3B
P 4029 4001
AR Path="/5A6E3F3B" Ref="C3"  Part="1" 
AR Path="/5A5DD67B/5A6E3F3B" Ref="C3"  Part="1" 
F 0 "C3" H 4054 4101 50  0000 L CNN
F 1 "50nF" H 4054 3901 50  0000 L CNN
F 2 "Capacitors_THT:C_Disc_D4.3mm_W1.9mm_P5.00mm" H 4067 3851 50  0001 C CNN
F 3 "" H 4029 4001 50  0001 C CNN
	1    4029 4001
	0    -1   -1   0   
$EndComp
Wire Wire Line
	893  2365 907  2365
Wire Wire Line
	2775 2365 2775 2367
Wire Wire Line
	2775 2269 2513 2269
Wire Wire Line
	1905 2247 1905 2269
Wire Wire Line
	1905 1947 1905 1845
Wire Wire Line
	1713 1845 1905 1845
Wire Wire Line
	2449 1144 2449 1845
Wire Wire Line
	2449 2171 2775 2171
Connection ~ 1905 1845
Wire Wire Line
	893  2265 1143 2265
Wire Wire Line
	1243 1845 1243 2265
Wire Wire Line
	1243 1845 1413 1845
Connection ~ 1243 2265
Wire Wire Line
	1905 2467 2634 2467
Connection ~ 1905 2269
Wire Wire Line
	893  2465 985  2465
Wire Wire Line
	893  2565 1063 2565
Wire Wire Line
	1243 2663 2752 2663
Wire Wire Line
	907  1233 907  2365
Connection ~ 907  2365
Wire Wire Line
	985  1233 985  2465
Wire Wire Line
	1063 1233 1063 2565
Connection ~ 1063 2565
Wire Wire Line
	1143 1233 1143 2265
Connection ~ 1143 2265
Connection ~ 1905 2465
Wire Wire Line
	3779 3330 3828 3330
Wire Wire Line
	3779 3330 3779 3329
Wire Wire Line
	3828 3143 3828 3330
Connection ~ 3828 3330
Wire Wire Line
	3479 3329 3326 3329
Wire Wire Line
	6262 2389 6787 2389
Wire Wire Line
	6262 2389 6262 2388
Wire Wire Line
	6262 2388 6261 2388
Wire Wire Line
	6261 2290 6690 2290
Wire Wire Line
	6261 2486 6885 2486
Wire Wire Line
	6261 2586 6984 2586
Wire Wire Line
	6261 2192 6591 2192
Wire Wire Line
	6591 1158 6591 1159
Connection ~ 6591 2192
Wire Wire Line
	6690 1158 6690 1244
Connection ~ 6690 2290
Wire Wire Line
	6787 1158 6787 1344
Connection ~ 6787 2389
Wire Wire Line
	6885 1158 6885 1444
Connection ~ 6885 2486
Wire Wire Line
	6984 1158 6984 1544
Connection ~ 6984 2586
Wire Wire Line
	1533 4205 1555 4205
Wire Wire Line
	1533 4305 1555 4305
Wire Wire Line
	1533 4405 1555 4405
Wire Wire Line
	1533 4505 1555 4505
Wire Wire Line
	1533 4605 1555 4605
Wire Wire Line
	2055 4705 2067 4705
Wire Wire Line
	2055 4605 2067 4605
Wire Wire Line
	2055 4505 2067 4505
Wire Wire Line
	2055 4405 2067 4405
Wire Wire Line
	2055 4305 2067 4305
Wire Wire Line
	2055 4205 2067 4205
Wire Wire Line
	3326 3329 3326 3428
Wire Bus Line
	1433 4805 1432 4805
Wire Wire Line
	1533 4705 1555 4705
Connection ~ 985  2465
Wire Wire Line
	4541 1144 2449 1144
Connection ~ 2449 1845
Wire Wire Line
	4541 1244 2513 1244
Wire Wire Line
	2513 1244 2513 2269
Connection ~ 2513 2269
Wire Wire Line
	4541 1344 2577 1344
Wire Wire Line
	2577 1344 2577 2365
Connection ~ 2577 2365
Wire Wire Line
	4541 1444 2634 1444
Wire Wire Line
	2634 1444 2634 2467
Connection ~ 2634 2467
Wire Wire Line
	4541 1544 2693 1544
Wire Wire Line
	2693 1544 2693 2565
Connection ~ 2693 2565
Wire Wire Line
	4541 1644 2752 1644
Wire Wire Line
	2752 1644 2752 2663
Connection ~ 2752 2663
Wire Wire Line
	5041 1144 6492 1144
Wire Wire Line
	6492 1144 6492 1159
Wire Wire Line
	6492 1159 6591 1159
Connection ~ 6591 1159
Wire Wire Line
	5041 1244 6690 1244
Connection ~ 6690 1244
Wire Wire Line
	5041 1344 6787 1344
Connection ~ 6787 1344
Wire Wire Line
	5041 1444 6885 1444
Connection ~ 6885 1444
Wire Wire Line
	5041 1544 6984 1544
Connection ~ 6984 1544
Wire Wire Line
	3879 3817 3879 3904
Wire Wire Line
	4179 3817 4179 3904
Connection ~ 3879 3904
Connection ~ 4179 3904
Wire Wire Line
	4179 3904 4300 3904
Wire Wire Line
	4300 3904 4300 3526
Wire Wire Line
	3828 3904 3879 3904
Wire Wire Line
	5041 1644 6498 1644
Wire Wire Line
	6498 1644 6498 2684
Wire Wire Line
	6498 2684 6261 2684
Connection ~ 6591 1644
Connection ~ 6498 1644
Wire Wire Line
	1905 1845 2449 1845
Wire Wire Line
	1243 2265 1243 2663
Wire Wire Line
	1905 2269 1905 2465
Wire Wire Line
	907  2365 2577 2365
Wire Wire Line
	1063 2565 2693 2565
Wire Wire Line
	1143 2265 1243 2265
Wire Wire Line
	1905 2465 1905 2467
Wire Wire Line
	3828 3330 4300 3330
Wire Wire Line
	3828 3330 3828 3904
Wire Wire Line
	6591 2192 7048 2192
Wire Wire Line
	6690 2290 7048 2290
Wire Wire Line
	6787 2389 7048 2389
Wire Wire Line
	6885 2486 7048 2486
Wire Wire Line
	6984 2586 7048 2586
Wire Wire Line
	985  2465 1905 2465
Wire Wire Line
	2449 1845 2449 2171
Wire Wire Line
	2513 2269 1905 2269
Wire Wire Line
	2577 2365 2775 2365
Wire Wire Line
	2634 2467 2775 2467
Wire Wire Line
	2693 2565 2775 2565
Wire Wire Line
	2752 2663 2775 2663
Wire Wire Line
	6591 1159 6591 1644
Wire Wire Line
	6690 1244 6690 2290
Wire Wire Line
	6787 1344 6787 2389
Wire Wire Line
	6885 1444 6885 2486
Wire Wire Line
	6984 1544 6984 2586
Wire Wire Line
	3879 3904 3879 4001
Wire Wire Line
	4179 3904 4179 4001
Wire Wire Line
	6591 1644 6591 2192
Wire Wire Line
	6498 1644 6591 1644
Wire Bus Line
	3125 3243 3125 3628
Wire Bus Line
	793  2365 793  2665
Wire Wire Line
	2889 3143 3828 3143
Wire Wire Line
	2889 3526 4300 3526
Wire Wire Line
	2890 3428 4300 3428
Wire Bus Line
	7148 2291 7148 2686
Wire Bus Line
	2167 4305 2167 4812
Wire Bus Line
	1433 4304 1433 4805
$EndSCHEMATC
