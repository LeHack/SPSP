EESchema Schematic File Version 4
LIBS:sensors_and_display_boards-cache
EELAYER 26 0
EELAYER END
$Descr User 7087 7087
encoding utf-8
Sheet 3 3
Title "Display and comms board"
Date "2018-06-17"
Rev ""
Comp "Łukasz Hejnak"
Comment1 "Bluetooth 4.1 LE + 4x8 segment display controller + 2x tact sw"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text HLabel 1257 5624 3    60   3State ~ 0
DISP-PREV
Text HLabel 1179 5624 3    60   3State ~ 0
RN-PIO1
Text HLabel 1101 5626 3    60   3State ~ 0
RN-UART_TX
Text HLabel 1021 5626 3    60   3State ~ 0
RN-UART_RX
Text HLabel 943  5626 3    60   3State ~ 0
RN-WAKE_SW
Text HLabel 865  5626 3    60   3State ~ 0
RN-WAKE_HW
Text HLabel 1962 5622 3    60   Input ~ 0
DISPRN-VDD
Text HLabel 1882 5622 3    60   Input ~ 0
DISPRN-GND
Text HLabel 1804 5622 3    60   BiDi ~ 0
DISP-A0
Text HLabel 1724 5622 3    60   BiDi ~ 0
DISP-A1
Text HLabel 1646 5622 3    60   BiDi ~ 0
DISP-ENA
Text HLabel 1568 5622 3    60   BiDi ~ 0
DISP-DS
Text HLabel 1488 5622 3    60   BiDi ~ 0
DISP-SHCLK
Text HLabel 1410 5622 3    60   BiDi ~ 0
DISP-STCLK
Text HLabel 1332 5622 3    60   BiDi ~ 0
DISP-NEXT
NoConn ~ 1442 1750
NoConn ~ 1382 1750
NoConn ~ 1322 1750
NoConn ~ 1262 1750
NoConn ~ 832  1330
NoConn ~ 832  1100
NoConn ~ 832  1040
NoConn ~ 832  980 
NoConn ~ 1862 1390
NoConn ~ 1862 1330
NoConn ~ 1862 1280
NoConn ~ 1862 1220
NoConn ~ 1862 1160
NoConn ~ 1862 1100
NoConn ~ 1862 1040
NoConn ~ 832  1390
$Comp
L sensors_and_display_boards-rescue:Conn_02x07_Odd_Even J5
U 1 1 5A62A6DC
P 2050 2237
F 0 "J5" H 2100 2637 50  0000 C CNN
F 1 "FPGA Connector" H 2100 1837 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x07_Pitch2.54mm" H 2050 2237 50  0001 C CNN
F 3 "" H 2050 2237 50  0001 C CNN
	1    2050 2237
	1    0    0    -1  
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R8
U 1 1 5A6149B4
P 4568 2485
F 0 "R8" V 4648 2485 50  0001 C CNN
F 1 "220" V 4568 2485 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2485 50  0001 C CNN
F 3 "" H 4568 2485 50  0001 C CNN
	1    4568 2485
	0    1    1    0   
$EndComp
Entry Wire Line
	1232 5498 1332 5598
Entry Wire Line
	1310 5498 1410 5598
Entry Wire Line
	1388 5498 1488 5598
Entry Wire Line
	1468 5498 1568 5598
Entry Wire Line
	1546 5498 1646 5598
Entry Wire Line
	1624 5498 1724 5598
Entry Wire Line
	1704 5498 1804 5598
Entry Wire Line
	1782 5498 1882 5598
Entry Wire Line
	1862 5498 1962 5598
Text Label 1962 5600 1    10   ~ 0
PW-VDD
Text Label 1882 5600 1    10   ~ 0
PW-GND
Text Label 1804 5598 1    10   ~ 0
DISP-A0
Text Label 1724 5600 1    10   ~ 0
DISP-A1
Text Label 1646 5598 1    10   ~ 0
DISP-ENA
Text Label 1568 5600 1    10   ~ 0
DISP-DS
Text Label 1488 5600 1    10   ~ 0
DISP-SHCLK
Text Label 1410 5600 1    10   ~ 0
DISP-STCLK
Text Label 1332 5600 1    10   ~ 0
DISP-NEXT
Entry Wire Line
	765  5498 865  5598
Entry Wire Line
	843  5498 943  5598
Entry Wire Line
	921  5498 1021 5598
Entry Wire Line
	1001 5498 1101 5598
Entry Wire Line
	1079 5498 1179 5598
Entry Wire Line
	1157 5498 1257 5598
Text Label 1179 5601 1    10   ~ 0
RN-PIO1
Text Label 1101 5600 1    10   ~ 0
RN-UART_TX
Text Label 1021 5600 1    10   ~ 0
RN-UART_RX
Text Label 943  5600 1    10   ~ 0
RN-WAKE_SW
Text Label 865  5600 1    10   ~ 0
RN-WAKE_HW
Text Label 1257 5601 1    10   ~ 0
DISP-PREV
$Comp
L sensors_and_display_boards-rescue:SW_Push SW2
U 1 1 5B2523C3
P 4527 4771
F 0 "SW2" H 4577 4871 50  0000 L CNN
F 1 "B_NEXT" H 4527 4711 50  0000 C CNN
F 2 "Buttons_Switches_THT:SW_PUSH_6mm_h8mm" H 4527 4971 50  0001 C CNN
F 3 "" H 4527 4971 50  0001 C CNN
	1    4527 4771
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:SW_Push SW1
U 1 1 5B2524EB
P 4133 4771
F 0 "SW1" H 4183 4871 50  0000 L CNN
F 1 "B_PREV" H 4133 4711 50  0000 C CNN
F 2 "Buttons_Switches_THT:SW_PUSH_6mm_h8mm" H 4133 4971 50  0001 C CNN
F 3 "" H 4133 4971 50  0001 C CNN
	1    4133 4771
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:C C4
U 1 1 5B2529F0
P 3387 4725
AR Path="/5B2529F0" Ref="C4"  Part="1" 
AR Path="/5A5DD685/5B2529F0" Ref="C4"  Part="1" 
F 0 "C4" H 3412 4825 50  0001 L CNN
F 1 "100nF" H 3412 4625 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 3425 4575 50  0001 C CNN
F 3 "" H 3387 4725 50  0001 C CNN
	1    3387 4725
	1    0    0    -1  
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R7
U 1 1 5B253DFA
P 4568 2385
F 0 "R7" V 4648 2385 50  0001 C CNN
F 1 "220" V 4568 2385 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2385 50  0001 C CNN
F 3 "" H 4568 2385 50  0001 C CNN
	1    4568 2385
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:LED D1
U 1 1 5B253E9A
P 1171 2575
F 0 "D1" H 1171 2675 50  0000 C CNN
F 1 "LED" H 1171 2475 50  0000 C CNN
F 2 "LEDs:LED_1206_HandSoldering" H 1171 2575 50  0001 C CNN
F 3 "" H 1171 2575 50  0001 C CNN
	1    1171 2575
	1    0    0    -1  
$EndComp
$Comp
L spsp_components:FJ-5461BH U9
U 1 1 5B25A3ED
P 6038 3385
F 0 "U9" H 6432 3341 60  0000 C CNN
F 1 "FJ-5461BH" H 6408 3441 60  0000 C CNN
F 2 "footprints:FJ-5461BH" H 5468 2995 60  0001 C CNN
F 3 "" H 5468 2995 60  0001 C CNN
	1    6038 3385
	-1   0    0    1   
$EndComp
$Comp
L spsp_components:74HC595 U7
U 1 1 5B25A4AF
P 3277 2285
F 0 "U7" H 3683 1233 50  0000 C CNN
F 1 "74HC595" H 3695 1143 50  0000 C CNN
F 2 "Housings_SOIC:SOIC-16_3.9x9.9mm_Pitch1.27mm" H 3677 1735 50  0001 C CNN
F 3 "" H 3677 1735 50  0001 C CNN
	1    3277 2285
	1    0    0    -1  
$EndComp
$Comp
L spsp_components:74HC4066 U8
U 1 1 5B25A790
P 4751 868
F 0 "U8" H 5143 -190 50  0000 C CNN
F 1 "74HC4066" H 5149 -278 50  0000 C CNN
F 2 "Housings_SOIC:SOIC-14_3.9x8.7mm_Pitch1.27mm" H 5151 318 50  0001 C CNN
F 3 "" H 5151 318 50  0001 C CNN
	1    4751 868 
	1    0    0    -1  
$EndComp
$Comp
L spsp_components:74HC14 U5
U 1 1 5B25B8E6
P 2600 4100
F 0 "U5" H 2992 3042 50  0000 C CNN
F 1 "74HC14" H 2998 2954 50  0000 C CNN
F 2 "Housings_SOIC:SOIC-14_3.9x8.7mm_Pitch1.27mm" H 3000 3550 50  0001 C CNN
F 3 "" H 3000 3550 50  0001 C CNN
	1    2600 4100
	0    1    1    0   
$EndComp
$Comp
L spsp_components:74HC238 U6
U 1 1 5B25BE85
P 3262 868
F 0 "U6" H 3654 -190 50  0000 C CNN
F 1 "74HC238" H 3660 -278 50  0000 C CNN
F 2 "Housings_SOIC:SOIC-16_3.9x9.9mm_Pitch1.27mm" H 3662 318 50  0001 C CNN
F 3 "" H 3662 318 50  0001 C CNN
	1    3262 868 
	1    0    0    -1  
$EndComp
NoConn ~ 4262 1852
NoConn ~ 4262 1734
NoConn ~ 4262 1616
NoConn ~ 4262 1498
NoConn ~ 4377 3285
$Comp
L sensors_and_display_boards-rescue:R R9
U 1 1 5B260ED6
P 4568 2585
F 0 "R9" V 4648 2585 50  0001 C CNN
F 1 "220" V 4568 2585 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2585 50  0001 C CNN
F 3 "" H 4568 2585 50  0001 C CNN
	1    4568 2585
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R10
U 1 1 5B260F71
P 4568 2685
F 0 "R10" V 4648 2685 50  0001 C CNN
F 1 "220" V 4568 2685 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2685 50  0001 C CNN
F 3 "" H 4568 2685 50  0001 C CNN
	1    4568 2685
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R11
U 1 1 5B26100C
P 4568 2785
F 0 "R11" V 4648 2785 50  0001 C CNN
F 1 "220" V 4568 2785 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2785 50  0001 C CNN
F 3 "" H 4568 2785 50  0001 C CNN
	1    4568 2785
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R12
U 1 1 5B261067
P 4568 2885
F 0 "R12" V 4648 2885 50  0001 C CNN
F 1 "220" V 4568 2885 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2885 50  0001 C CNN
F 3 "" H 4568 2885 50  0001 C CNN
	1    4568 2885
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R13
U 1 1 5B2610A2
P 4568 2985
F 0 "R13" V 4648 2985 50  0001 C CNN
F 1 "220" V 4568 2985 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 2985 50  0001 C CNN
F 3 "" H 4568 2985 50  0001 C CNN
	1    4568 2985
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R14
U 1 1 5B26111D
P 4568 3085
F 0 "R14" V 4648 3085 50  0001 C CNN
F 1 "220" V 4568 3085 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4498 3085 50  0001 C CNN
F 3 "" H 4568 3085 50  0001 C CNN
	1    4568 3085
	0    1    1    0   
$EndComp
$Comp
L sensors_and_display_boards-rescue:Conn_01x02 J4
U 1 1 5B263AE8
P 1080 3094
F 0 "J4" H 1080 3194 50  0000 C CNN
F 1 "Power" H 1080 2894 50  0000 C CNN
F 2 "Connectors_JST:JST_PH_B2B-PH-K_02x2.00mm_Straight" H 1080 3094 50  0001 C CNN
F 3 "" H 1080 3094 50  0001 C CNN
	1    1080 3094
	-1   0    0    -1  
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R3
U 1 1 5B264870
P 846 2575
F 0 "R3" V 926 2575 50  0001 C CNN
F 1 "220" V 846 2575 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 776 2575 50  0001 C CNN
F 3 "" H 846 2575 50  0001 C CNN
	1    846  2575
	0    1    1    0   
$EndComp
NoConn ~ 832  920 
NoConn ~ 2350 2537
$Comp
L sensors_and_display_boards-rescue:C C5
U 1 1 5B268498
P 3702 4724
AR Path="/5B268498" Ref="C5"  Part="1" 
AR Path="/5A5DD685/5B268498" Ref="C5"  Part="1" 
F 0 "C5" H 3727 4824 50  0001 L CNN
F 1 "100nF" H 3727 4624 50  0000 L CNN
F 2 "Capacitors_SMD:C_1206_HandSoldering" H 3740 4574 50  0001 C CNN
F 3 "" H 3702 4724 50  0001 C CNN
	1    3702 4724
	1    0    0    -1  
$EndComp
NoConn ~ 1852 5100
NoConn ~ 1970 5100
NoConn ~ 2088 5100
NoConn ~ 2206 5100
NoConn ~ 2324 5100
NoConn ~ 2442 5100
NoConn ~ 1852 3900
NoConn ~ 1970 3900
$Comp
L sensors_and_display_boards-rescue:R R4
U 1 1 5B26D5F6
P 4133 4141
F 0 "R4" V 4213 4141 50  0001 C CNN
F 1 "10k" V 4133 4141 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4063 4141 50  0001 C CNN
F 3 "" H 4133 4141 50  0001 C CNN
	1    4133 4141
	-1   0    0    1   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R6
U 1 1 5B26D8E1
P 4527 4143
F 0 "R6" V 4607 4143 50  0001 C CNN
F 1 "10k" V 4527 4143 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4457 4143 50  0001 C CNN
F 3 "" H 4527 4143 50  0001 C CNN
	1    4527 4143
	-1   0    0    1   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R5
U 1 1 5B26E684
P 4251 4141
F 0 "R5" V 4331 4141 50  0001 C CNN
F 1 "10k" V 4251 4141 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4181 4141 50  0001 C CNN
F 3 "" H 4251 4141 50  0001 C CNN
	1    4251 4141
	-1   0    0    1   
$EndComp
$Comp
L sensors_and_display_boards-rescue:R R15
U 1 1 5B26E733
P 4645 4141
F 0 "R15" V 4725 4141 50  0001 C CNN
F 1 "10k" V 4645 4141 50  0000 C CNN
F 2 "Resistors_SMD:R_1206_HandSoldering" V 4575 4141 50  0001 C CNN
F 3 "" H 4645 4141 50  0001 C CNN
	1    4645 4141
	-1   0    0    1   
$EndComp
Wire Wire Line
	1962 5598 1962 5622
Wire Wire Line
	1882 5598 1882 5622
Wire Wire Line
	1804 5598 1804 5622
Wire Wire Line
	1724 5598 1724 5622
Wire Wire Line
	1646 5598 1646 5622
Wire Wire Line
	1568 5598 1568 5622
Wire Wire Line
	1488 5598 1488 5622
Wire Wire Line
	1410 5598 1410 5622
Wire Wire Line
	1332 5598 1332 5622
Wire Wire Line
	1257 5598 1257 5624
Wire Wire Line
	1179 5598 1179 5624
Wire Wire Line
	1101 5598 1101 5626
Wire Wire Line
	1021 5598 1021 5626
Wire Wire Line
	943  5598 943  5626
Wire Wire Line
	865  5598 865  5626
Wire Wire Line
	4262 1026 4374 1026
Wire Wire Line
	4374 1026 4374 1104
Wire Wire Line
	4374 1104 4551 1104
Wire Wire Line
	4262 1144 4375 1144
Wire Wire Line
	4375 1144 4375 1222
Wire Wire Line
	4375 1222 4551 1222
Wire Wire Line
	4262 1262 4376 1262
Wire Wire Line
	4376 1262 4376 1340
Wire Wire Line
	4376 1340 4551 1340
Wire Wire Line
	4262 1380 4377 1380
Wire Wire Line
	4377 1380 4377 1458
Wire Wire Line
	4377 1458 4551 1458
Wire Wire Line
	3062 1380 2962 1380
Wire Wire Line
	2962 1262 2962 1380
Wire Wire Line
	2962 1498 2963 1498
Wire Wire Line
	3062 1892 2964 1892
Wire Wire Line
	2963 1892 2963 1498
Connection ~ 2963 1498
Wire Wire Line
	3062 1262 2962 1262
Connection ~ 2962 1380
Wire Wire Line
	4551 1892 4460 1892
Wire Wire Line
	4460 1892 4460 2106
Wire Wire Line
	4460 2106 2964 2106
Wire Wire Line
	2964 2106 2964 1892
Connection ~ 2964 1892
Wire Wire Line
	4551 1774 4500 1774
Wire Wire Line
	4500 1774 4500 2133
Wire Wire Line
	2919 2133 4500 2133
Wire Wire Line
	2919 2133 2919 1774
Wire Wire Line
	2807 1774 2919 1774
Wire Wire Line
	5751 1026 5889 1026
Wire Wire Line
	5889 1026 5889 1262
Connection ~ 4500 2133
Wire Wire Line
	5751 1262 5889 1262
Connection ~ 5889 1262
Wire Wire Line
	5751 1498 5889 1498
Connection ~ 5889 1498
Wire Wire Line
	5751 1734 5889 1734
Connection ~ 5889 1734
Wire Wire Line
	6238 2915 6298 2915
Wire Wire Line
	6298 2915 6298 1852
Wire Wire Line
	6298 1852 5751 1852
Wire Wire Line
	6238 3035 6337 3035
Wire Wire Line
	6337 3035 6337 1616
Wire Wire Line
	6337 1616 5751 1616
Wire Wire Line
	6238 3145 6376 3145
Wire Wire Line
	6376 3145 6376 1380
Wire Wire Line
	6376 1380 5751 1380
Wire Wire Line
	6238 3265 6416 3265
Wire Wire Line
	6416 3265 6416 1144
Wire Wire Line
	6416 1144 5751 1144
Wire Wire Line
	4377 2385 4418 2385
Wire Wire Line
	4377 2485 4418 2485
Wire Wire Line
	4377 2585 4418 2585
Wire Wire Line
	4377 2685 4418 2685
Wire Wire Line
	4377 2785 4418 2785
Wire Wire Line
	4377 2885 4418 2885
Wire Wire Line
	4377 2985 4418 2985
Wire Wire Line
	4377 3085 4418 3085
Wire Wire Line
	4718 2385 4960 2385
Wire Wire Line
	4960 2385 4960 2435
Wire Wire Line
	4960 2435 5048 2435
Wire Wire Line
	4718 2485 4941 2485
Wire Wire Line
	4941 2485 4941 2555
Wire Wire Line
	4941 2555 5048 2555
Wire Wire Line
	4718 2585 4922 2585
Wire Wire Line
	4922 2585 4922 2675
Wire Wire Line
	4922 2675 5048 2675
Wire Wire Line
	4718 2685 4901 2685
Wire Wire Line
	4901 2685 4901 2795
Wire Wire Line
	4901 2795 5048 2795
Wire Wire Line
	4718 2785 4881 2785
Wire Wire Line
	4881 2785 4881 2915
Wire Wire Line
	4881 2915 5048 2915
Wire Wire Line
	4718 2885 4862 2885
Wire Wire Line
	4862 2885 4862 3035
Wire Wire Line
	4862 3035 5048 3035
Wire Wire Line
	4718 2985 4843 2985
Wire Wire Line
	4843 2985 4843 3145
Wire Wire Line
	4843 3145 5048 3145
Wire Wire Line
	4718 3085 4822 3085
Wire Wire Line
	4822 3085 4822 3265
Wire Wire Line
	4822 3265 5048 3265
Wire Wire Line
	2660 3315 2856 3315
Wire Wire Line
	2856 3315 2856 2985
Wire Wire Line
	2856 1892 2964 1892
Wire Wire Line
	2977 2985 2856 2985
Connection ~ 2856 2985
Wire Wire Line
	2977 3215 2807 3215
Wire Wire Line
	2807 3215 2807 3094
Connection ~ 2919 1774
Wire Wire Line
	2977 2685 2807 2685
Connection ~ 2807 2685
Wire Wire Line
	1202 1750 1202 2037
Wire Wire Line
	1280 3094 1320 3094
Connection ~ 2807 3094
Wire Wire Line
	1280 3194 1320 3194
Wire Wire Line
	2660 3194 2660 3315
Connection ~ 2856 3315
Wire Wire Line
	1862 920  1976 920 
Wire Wire Line
	1976 920  1976 676 
Wire Wire Line
	1976 676  591  676 
Wire Wire Line
	591  676  591  2575
Wire Wire Line
	591  3392 1320 3392
Wire Wire Line
	1320 3194 1320 3392
Connection ~ 1320 3194
Wire Wire Line
	1862 980  1937 980 
Wire Wire Line
	1937 980  1937 715 
Wire Wire Line
	1937 715  630  715 
Wire Wire Line
	630  715  630  2937
Wire Wire Line
	630  2937 1320 2937
Wire Wire Line
	1320 2937 1320 3094
Connection ~ 1320 3094
Wire Wire Line
	3062 1026 2499 1026
Wire Wire Line
	2499 1026 2499 1937
Wire Wire Line
	2499 1937 2350 1937
Wire Wire Line
	3062 1144 2538 1144
Wire Wire Line
	2538 1144 2538 2037
Wire Wire Line
	2538 2037 2350 2037
Wire Wire Line
	3062 1616 2577 1616
Wire Wire Line
	2577 1616 2577 2137
Wire Wire Line
	2577 2137 2350 2137
Wire Wire Line
	2977 2385 2577 2385
Wire Wire Line
	2577 2385 2577 2237
Wire Wire Line
	2577 2237 2350 2237
Wire Wire Line
	2977 2585 2538 2585
Wire Wire Line
	2538 2585 2538 2337
Wire Wire Line
	2538 2337 2350 2337
Wire Wire Line
	2977 2885 2499 2885
Wire Wire Line
	2499 2885 2499 2437
Wire Wire Line
	2499 2437 2350 2437
Wire Wire Line
	1502 1750 1502 1937
Wire Wire Line
	1502 1937 1850 1937
Wire Wire Line
	1202 2037 1391 2037
Wire Wire Line
	696  2575 591  2575
Connection ~ 591  2575
Wire Wire Line
	996  2575 1021 2575
Wire Wire Line
	1321 2575 1391 2575
Wire Wire Line
	1391 2575 1391 2037
Connection ~ 1391 2037
Wire Wire Line
	832  1280 748  1280
Wire Wire Line
	748  1280 748  2137
Wire Wire Line
	748  2137 1850 2137
Wire Wire Line
	832  1220 709  1220
Wire Wire Line
	709  1220 709  2237
Wire Wire Line
	709  2237 1850 2237
Wire Wire Line
	832  1160 670  1160
Wire Wire Line
	670  1160 670  2337
Wire Wire Line
	670  2337 1850 2337
Wire Wire Line
	1576 3392 1576 3900
Connection ~ 1320 3392
Connection ~ 1694 3094
Wire Wire Line
	1320 5238 3387 5238
Wire Wire Line
	4133 4971 4133 5238
Wire Wire Line
	3702 4874 3702 5238
Connection ~ 3702 5238
Connection ~ 4133 5238
Wire Wire Line
	3387 4875 3387 5238
Connection ~ 3387 5238
Wire Wire Line
	4527 5238 4527 4971
Wire Wire Line
	2442 3900 2442 3853
Wire Wire Line
	2442 3853 3702 3853
Wire Wire Line
	2206 3900 2206 3813
Wire Wire Line
	2206 3813 3387 3813
Wire Wire Line
	1694 3900 1694 3774
Wire Wire Line
	2324 3900 2324 2787
Wire Wire Line
	2324 2787 1707 2787
Wire Wire Line
	1707 2787 1707 2537
Wire Wire Line
	1707 2537 1850 2537
Wire Wire Line
	1850 2437 1668 2437
Wire Wire Line
	1668 2437 1668 2826
Wire Wire Line
	1668 2826 2088 2826
Wire Wire Line
	2088 2826 2088 3900
Wire Wire Line
	4133 4291 4133 4370
Wire Wire Line
	4527 4293 4527 4370
Wire Wire Line
	4133 3853 4133 3991
Wire Wire Line
	4527 3813 4527 3993
Wire Wire Line
	3702 4574 3702 3853
Connection ~ 3702 3853
Wire Wire Line
	3387 4575 3387 3813
Connection ~ 3387 3813
Wire Wire Line
	4251 3774 4251 3991
Wire Wire Line
	1694 3774 4251 3774
Connection ~ 1694 3774
Wire Wire Line
	4645 3774 4645 3991
Connection ~ 4251 3774
Wire Wire Line
	4251 4291 4251 4370
Wire Wire Line
	4251 4370 4133 4370
Connection ~ 4133 4370
Wire Wire Line
	4645 4291 4645 4370
Wire Wire Line
	4645 4370 4527 4370
Connection ~ 4527 4370
Text Label 1293 3194 2    10   ~ 0
PW-GND
Text Label 1293 3094 2    10   ~ 0
PW-VDD
Text Label 2351 1937 0    10   ~ 0
DISP-A0
Text Label 2351 2037 0    10   ~ 0
DISP-A1
Text Label 2351 2137 0    10   ~ 0
DISP-ENA
Text Label 2351 2237 0    10   ~ 0
DISP-DS
Text Label 2351 2337 0    10   ~ 0
DISP-SHCLK
Text Label 2351 2437 0    10   ~ 0
DISP-STCLK
Text Label 1849 2437 2    10   ~ 0
DISP-NEXT
Text Label 1849 2037 2    10   ~ 0
RN-PIO1
Text Label 1849 2337 2    10   ~ 0
RN-UART_TX
Text Label 1849 2237 2    10   ~ 0
RN-UART_RX
Text Label 1849 2137 2    10   ~ 0
RN-WAKE_SW
Text Label 1849 1937 2    10   ~ 0
RN-WAKE_HW
Text Label 1849 2537 2    10   ~ 0
DISP-PREV
$Comp
L spsp_components:RN4020 U4
U 1 1 5B25B27A
P 1742 1630
F 0 "U4" H 2148 886 60  0000 C CNN
F 1 "RN4020" H 2146 790 60  0000 C CNN
F 2 "footprints:RN4020" H 2991 1085 60  0001 C CNN
F 3 "" H 2991 1085 60  0000 C CNN
	1    1742 1630
	-1   0    0    1   
$EndComp
Wire Wire Line
	2963 1498 3062 1498
Wire Wire Line
	2962 1380 2962 1498
Wire Wire Line
	2964 1892 2963 1892
Wire Wire Line
	4500 2133 5889 2133
Wire Wire Line
	5889 1262 5889 1498
Wire Wire Line
	5889 1498 5889 1734
Wire Wire Line
	5889 1734 5889 2133
Wire Wire Line
	2856 2985 2856 1892
Wire Wire Line
	2919 1774 3062 1774
Wire Wire Line
	2807 2685 2807 1774
Wire Wire Line
	2807 3094 2807 2685
Wire Wire Line
	2856 3315 2977 3315
Wire Wire Line
	1320 3194 2660 3194
Wire Wire Line
	1320 3094 1694 3094
Wire Wire Line
	591  2575 591  3392
Wire Wire Line
	1391 2037 1850 2037
Wire Wire Line
	1320 3392 1576 3392
Wire Wire Line
	1320 3392 1320 5238
Wire Wire Line
	1694 3094 2807 3094
Wire Wire Line
	3702 5238 4133 5238
Wire Wire Line
	4133 5238 4527 5238
Wire Wire Line
	3387 5238 3702 5238
Wire Wire Line
	3702 3853 4133 3853
Wire Wire Line
	3387 3813 4527 3813
Wire Wire Line
	1694 3774 1694 3094
Wire Wire Line
	4251 3774 4645 3774
Wire Wire Line
	4133 4370 4133 4571
Wire Wire Line
	4527 4370 4527 4571
Wire Bus Line
	752  5498 1888 5498
$EndSCHEMATC
