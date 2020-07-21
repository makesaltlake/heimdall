EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 1 1
Title ""
Date "2020-07-20"
Rev "0.2"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector_Generic:Conn_01x09 J1
U 1 1 5F14F04E
P 1600 4050
F 0 "J1" H 1518 4667 50  0000 C CNN
F 1 "Conn_01x09" H 1518 4576 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x09_P2.54mm_Vertical" H 1600 4050 50  0001 C CNN
F 3 "~" H 1600 4050 50  0001 C CNN
	1    1600 4050
	-1   0    0    -1  
$EndComp
Wire Wire Line
	1800 3650 2050 3650
Wire Wire Line
	1800 3850 2800 3850
$Comp
L SparkFun-Electromechanical:SPEAKER LS1
U 1 1 5F15A47C
P 6850 4550
F 0 "LS1" H 7178 4645 45  0000 L CNN
F 1 "SPEAKER" H 7178 4561 45  0000 L CNN
F 2 "Electromechanical:PCB_MOUNT_SPEAKER" H 6850 4950 20  0001 C CNN
F 3 "" H 6850 4550 50  0001 C CNN
F 4 "COMP-11789" H 7178 4466 60  0000 L CNN "Field4"
	1    6850 4550
	1    0    0    -1  
$EndComp
Text Label 3650 3950 0    50   ~ 0
CS
Text Label 3650 4050 0    50   ~ 0
SCK
Text Label 3650 4150 0    50   ~ 0
MOSI
Text Label 3650 4250 0    50   ~ 0
MISO
Text Label 3650 4350 0    50   ~ 0
LED
Text Label 3650 3750 0    50   ~ 0
+3V3
Text Label 3650 3850 0    50   ~ 0
GND
Text Label 3650 4450 0    50   ~ 0
Buzzer
Text Label 3650 3650 0    50   ~ 0
+5V
$Comp
L LED:WS2812B D1
U 1 1 5F15EA18
P 5700 5250
F 0 "D1" H 6044 5296 50  0000 L CNN
F 1 "WS2812B" H 6044 5205 50  0000 L CNN
F 2 "LED_SMD:LED_WS2812B_PLCC4_5.0x5.0mm_P3.2mm" H 5750 4950 50  0001 L TNN
F 3 "https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf" H 5800 4875 50  0001 L TNN
	1    5700 5250
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Resistors:470OHM R1
U 1 1 5F162B61
P 4950 5250
F 0 "R1" H 4950 5550 45  0000 C CNN
F 1 "470OHM" H 4950 5466 45  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0918_L18.0mm_D9.0mm_P22.86mm_Horizontal" H 4950 5400 20  0001 C CNN
F 3 "" H 4950 5250 60  0001 C CNN
F 4 "RES-07869" H 4950 5371 60  0000 C CNN "Field4"
	1    4950 5250
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Capacitors:1000UF-RADIAL-5MM-25V-20% C1
U 1 1 5F15FBF3
P 2350 5200
F 0 "C1" H 2478 5245 45  0000 L CNN
F 1 "1000UF-RADIAL-5MM-25V-20%" H 2478 5161 45  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D12.5mm_P5.00mm" H 2350 5450 20  0001 C CNN
F 3 "" H 2350 5200 50  0001 C CNN
F 4 "CAP-09538" H 2478 5066 60  0000 L CNN "Field4"
	1    2350 5200
	0    -1   1    0   
$EndComp
Wire Wire Line
	2800 3850 5900 3850
Connection ~ 2800 3850
Wire Wire Line
	1800 3750 5900 3750
Wire Wire Line
	1800 3950 5900 3950
Wire Wire Line
	1800 4050 5900 4050
Wire Wire Line
	1800 4150 5900 4150
Wire Wire Line
	1800 4250 5900 4250
$Comp
L Connector_Generic:Conn_01x06 J2
U 1 1 5F170A36
P 6100 3950
F 0 "J2" H 6180 3942 50  0000 L CNN
F 1 "Conn_01x06" H 6180 3851 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x06_P2.54mm_Vertical" H 6100 3950 50  0001 C CNN
F 3 "~" H 6100 3950 50  0001 C CNN
	1    6100 3950
	1    0    0    -1  
$EndComp
Wire Wire Line
	1800 4450 6450 4450
Wire Wire Line
	2800 3850 2800 4650
Connection ~ 2800 4650
Wire Wire Line
	2800 4650 6450 4650
Wire Wire Line
	4300 4350 4300 5250
Wire Wire Line
	4300 5250 4750 5250
Wire Wire Line
	1800 4350 4300 4350
Wire Wire Line
	5150 5250 5400 5250
Wire Wire Line
	2050 5200 2050 3650
Connection ~ 2050 3650
Wire Wire Line
	5700 5550 2800 5550
Wire Wire Line
	5700 4950 5700 3650
Wire Wire Line
	2050 3650 5700 3650
Wire Wire Line
	2800 4650 2800 5200
Wire Wire Line
	2050 5200 2250 5200
Wire Wire Line
	2550 5200 2800 5200
Connection ~ 2800 5200
Wire Wire Line
	2800 5200 2800 5550
$EndSCHEMATC
