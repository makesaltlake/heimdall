EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 1 1
Title "Heimdall Outside Board"
Date "2020-11-07"
Rev "02"
Comp ""
Comment1 "https://opensource.org/licenses/MIT"
Comment2 "License: MIT"
Comment3 "https://github.com/makesaltlake/heimdall"
Comment4 "Author: Rebecca Cran <rebecca@bsdio.com>"
$EndDescr
$Comp
L Connector_Generic:Conn_01x09 J1
U 1 1 5F14F04E
P 1150 5750
F 0 "J1" H 1068 6367 50  0000 C CNN
F 1 "Conn_01x09" H 1068 6276 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x09_P2.54mm_Vertical" H 1150 5750 50  0001 C CNN
F 3 "~" H 1150 5750 50  0001 C CNN
	1    1150 5750
	-1   0    0    -1  
$EndComp
Text Label 1850 5650 0    50   ~ 0
CS
Text Label 1850 5750 0    50   ~ 0
SCK
Text Label 1850 5850 0    50   ~ 0
MOSI
Text Label 1850 5950 0    50   ~ 0
MISO
Text Label 1450 6050 0    50   ~ 0
LED
Text Label 1800 5450 0    50   ~ 0
+3V3
Text Label 1850 5550 0    50   ~ 0
GND
Text Label 1450 6150 0    50   ~ 0
Buzzer
Text Label 1800 5350 0    50   ~ 0
+5V
Wire Wire Line
	1350 5650 5450 5650
Wire Wire Line
	1350 5750 5450 5750
Wire Wire Line
	1350 5850 5450 5850
Wire Wire Line
	1350 5950 5450 5950
$Comp
L Connector_Generic:Conn_01x06 J2
U 1 1 5F170A36
P 5650 5650
F 0 "J2" H 5730 5642 50  0000 L CNN
F 1 "Conn_01x06" H 5730 5551 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x06_P2.54mm_Vertical" H 5650 5650 50  0001 C CNN
F 3 "~" H 5650 5650 50  0001 C CNN
	1    5650 5650
	1    0    0    -1  
$EndComp
$Comp
L dk_Alarms-Buzzers-and-Sirens:PS1240P02BT BZ1
U 1 1 5F1935B3
P 4050 6500
F 0 "BZ1" H 4390 6598 60  0000 L CNN
F 1 "PS1240P02BT" H 4390 6492 60  0000 L CNN
F 2 "digikey-footprints:Piezo_Transducer_THT_PS1240P02BT" H 4250 6700 60  0001 L CNN
F 3 "https://product.tdk.com/info/en/catalog/datasheets/piezoelectronic_buzzer_ps_en.pdf" H 4250 6800 60  0001 L CNN
F 4 "445-2525-1-ND" H 4250 6900 60  0001 L CNN "Digi-Key_PN"
F 5 "PS1240P02BT" H 4250 7000 60  0001 L CNN "MPN"
F 6 "Audio Products" H 4250 7100 60  0001 L CNN "Category"
F 7 "Alarms, Buzzers, and Sirens" H 4250 7200 60  0001 L CNN "Family"
F 8 "https://product.tdk.com/info/en/catalog/datasheets/piezoelectronic_buzzer_ps_en.pdf" H 4250 7300 60  0001 L CNN "DK_Datasheet_Link"
F 9 "/product-detail/en/tdk-corporation/PS1240P02BT/445-2525-1-ND/935930" H 4250 7400 60  0001 L CNN "DK_Detail_Page"
F 10 "AUDIO PIEZO TRANSDUCER 30V TH" H 4250 7500 60  0001 L CNN "Description"
F 11 "TDK Corporation" H 4250 7600 60  0001 L CNN "Manufacturer"
F 12 "Active" H 4250 7700 60  0001 L CNN "Status"
	1    4050 6500
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Resistors:1KOHM-0603-1_10W-1% R3
U 1 1 5F1960FF
P 2900 6450
F 0 "R3" V 2995 6382 45  0000 R CNN
F 1 "1K" V 2911 6382 45  0000 R CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2900 6600 20  0001 C CNN
F 3 "" H 2900 6450 60  0001 C CNN
F 4 "RES-07856" V 2816 6382 60  0000 R CNN "Field4"
	1    2900 6450
	0    -1   -1   0   
$EndComp
$Comp
L LED:NeoPixel_THT D1
U 1 1 5F17E8A3
P 4550 4950
F 0 "D1" H 4894 4996 50  0000 L CNN
F 1 "NeoPixel_THT" H 4894 4905 50  0000 L CNN
F 2 "LED_THT:LED_D5.0mm-4_RGB" H 4600 4650 50  0001 L TNN
F 3 "https://www.adafruit.com/product/1938" H 4650 4575 50  0001 L TNN
	1    4550 4950
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Resistors:10KOHM-HORIZ-1_4W-1% R1
U 1 1 5F1AD489
P 2150 4800
F 0 "R1" H 2150 4500 45  0000 C CNN
F 1 "10K" H 2150 4584 45  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2150 4950 20  0001 C CNN
F 3 "" H 2150 4800 60  0001 C CNN
F 4 "RES-12183" H 2150 4679 60  0000 C CNN "Field4"
	1    2150 4800
	-1   0    0    1   
$EndComp
$Comp
L dk_Transistors-FETs-MOSFETs-Single:2N7000 Q2
U 1 1 5F1B8AC7
P 3050 4500
F 0 "Q2" V 3211 4500 60  0000 C CNN
F 1 "2N7000" V 3317 4500 60  0000 C CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 3250 4700 60  0001 L CNN
F 3 "https://www.onsemi.com/pub/Collateral/NDS7002A-D.PDF" H 3250 4800 60  0001 L CNN
F 4 "2N7000FS-ND" H 3250 4900 60  0001 L CNN "Digi-Key_PN"
F 5 "2N7000" H 3250 5000 60  0001 L CNN "MPN"
F 6 "Discrete Semiconductor Products" H 3250 5100 60  0001 L CNN "Category"
F 7 "Transistors - FETs, MOSFETs - Single" H 3250 5200 60  0001 L CNN "Family"
F 8 "https://www.onsemi.com/pub/Collateral/NDS7002A-D.PDF" H 3250 5300 60  0001 L CNN "DK_Datasheet_Link"
F 9 "/product-detail/en/on-semiconductor/2N7000/2N7000FS-ND/244278" H 3250 5400 60  0001 L CNN "DK_Detail_Page"
F 10 "MOSFET N-CH 60V 200MA TO-92" H 3250 5500 60  0001 L CNN "Description"
F 11 "ON Semiconductor" H 3250 5600 60  0001 L CNN "Manufacturer"
F 12 "Active" H 3250 5700 60  0001 L CNN "Status"
	1    3050 4500
	0    1    1    0   
$EndComp
Wire Wire Line
	1350 6150 1700 6150
Wire Wire Line
	1700 6150 1700 6950
Wire Wire Line
	1700 6950 2000 6950
Wire Wire Line
	2900 6250 2900 5450
Wire Wire Line
	5100 7150 5100 5550
Connection ~ 5100 5550
Wire Wire Line
	5100 5550 5450 5550
Wire Wire Line
	3250 4500 3350 4500
Wire Wire Line
	3350 4500 3350 4250
Wire Wire Line
	3350 4250 3400 4250
Connection ~ 3350 4500
Wire Wire Line
	2850 4500 2650 4500
Wire Wire Line
	1350 5450 1650 5450
Wire Wire Line
	1650 4200 1650 4800
Connection ~ 1650 5450
Wire Wire Line
	1650 5450 2900 5450
Wire Wire Line
	1650 4200 2950 4200
Wire Wire Line
	2650 4500 2650 4800
Wire Wire Line
	2350 4800 2450 4800
Wire Wire Line
	1950 4800 1650 4800
Connection ~ 1650 4800
Wire Wire Line
	1650 4800 1650 5450
$Comp
L SparkFun-Resistors:10KOHM-HORIZ-1_4W-1% R4
U 1 1 5F1AE5EE
P 3150 4950
F 0 "R4" H 3150 4650 45  0000 C CNN
F 1 "10K" H 3150 4734 45  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 3150 5100 20  0001 C CNN
F 3 "" H 3150 4950 60  0001 C CNN
F 4 "RES-12183" H 3150 4829 60  0000 C CNN "Field4"
	1    3150 4950
	1    0    0    -1  
$EndComp
Wire Wire Line
	2600 5350 2600 4950
Wire Wire Line
	2600 4950 2950 4950
Connection ~ 2600 5350
Wire Wire Line
	2600 5350 5250 5350
Wire Wire Line
	3350 4500 3350 4950
Wire Wire Line
	1350 6050 2450 6050
Wire Wire Line
	2450 6050 2450 4800
Connection ~ 2450 4800
Wire Wire Line
	2450 4800 2650 4800
NoConn ~ 4650 4950
Wire Wire Line
	5250 5350 5250 4650
$Comp
L power:PWR_FLAG #FLG01
U 1 1 5F231A90
P 1200 3350
F 0 "#FLG01" H 1200 3425 50  0001 C CNN
F 1 "PWR_FLAG" H 1200 3523 50  0000 C CNN
F 2 "" H 1200 3350 50  0001 C CNN
F 3 "~" H 1200 3350 50  0001 C CNN
	1    1200 3350
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG03
U 1 1 5F2324EB
P 1650 3350
F 0 "#FLG03" H 1650 3425 50  0001 C CNN
F 1 "PWR_FLAG" H 1650 3523 50  0000 C CNN
F 2 "" H 1650 3350 50  0001 C CNN
F 3 "~" H 1650 3350 50  0001 C CNN
	1    1650 3350
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG02
U 1 1 5F234D2D
P 2100 3350
F 0 "#FLG02" H 2100 3425 50  0001 C CNN
F 1 "PWR_FLAG" H 2100 3523 50  0000 C CNN
F 2 "" H 2100 3350 50  0001 C CNN
F 3 "~" H 2100 3350 50  0001 C CNN
	1    2100 3350
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Resistors:1KOHM-0603-1_10W-1% R2
U 1 1 5F241B2F
P 2200 6950
F 0 "R2" H 2200 7250 45  0000 C CNN
F 1 "1K" H 2200 7166 45  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2200 7100 20  0001 C CNN
F 3 "" H 2200 6950 60  0001 C CNN
F 4 "RES-07856" H 2200 7071 60  0000 C CNN "Field4"
	1    2200 6950
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0101
U 1 1 5F2455AF
P 1200 3650
F 0 "#PWR0101" H 1200 3500 50  0001 C CNN
F 1 "+5V" H 1215 3823 50  0000 C CNN
F 2 "" H 1200 3650 50  0001 C CNN
F 3 "" H 1200 3650 50  0001 C CNN
	1    1200 3650
	-1   0    0    1   
$EndComp
Wire Wire Line
	2400 6950 2600 6950
Wire Wire Line
	1350 5350 2600 5350
Wire Wire Line
	2900 7150 5100 7150
Connection ~ 2900 5450
Wire Wire Line
	2900 5450 5450 5450
$Comp
L power:+3V3 #PWR0102
U 1 1 5F2475A1
P 1650 3650
F 0 "#PWR0102" H 1650 3500 50  0001 C CNN
F 1 "+3V3" H 1665 3823 50  0000 C CNN
F 2 "" H 1650 3650 50  0001 C CNN
F 3 "" H 1650 3650 50  0001 C CNN
	1    1650 3650
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0103
U 1 1 5F2499D9
P 2100 3650
F 0 "#PWR0103" H 2100 3400 50  0001 C CNN
F 1 "GND" H 2105 3477 50  0000 C CNN
F 2 "" H 2100 3650 50  0001 C CNN
F 3 "" H 2100 3650 50  0001 C CNN
	1    2100 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	1200 3350 1200 3650
Wire Wire Line
	1650 3350 1650 3650
Wire Wire Line
	2100 3350 2100 3650
$Comp
L Connector:Conn_01x01_Male J3
U 1 1 5FA614DC
P 3350 6250
F 0 "J3" H 3458 6431 50  0000 C CNN
F 1 "Conn_01x01_Male" H 3458 6340 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x01_P2.54mm_Vertical" H 3350 6250 50  0001 C CNN
F 3 "~" H 3350 6250 50  0001 C CNN
	1    3350 6250
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_01x01_Male J4
U 1 1 5FA62088
P 3400 6800
F 0 "J4" H 3508 6981 50  0000 C CNN
F 1 "Conn_01x01_Male" H 3508 6890 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x01_P2.54mm_Vertical" H 3400 6800 50  0001 C CNN
F 3 "~" H 3400 6800 50  0001 C CNN
	1    3400 6800
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_01x01_Male J5
U 1 1 5FA690EE
P 3850 4950
F 0 "J5" H 3958 5131 50  0000 C CNN
F 1 "Conn_01x01_Male" H 3958 5040 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x01_P2.54mm_Vertical" H 3850 4950 50  0001 C CNN
F 3 "~" H 3850 4950 50  0001 C CNN
	1    3850 4950
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_01x01_Male J6
U 1 1 5FA69F83
P 4650 4650
F 0 "J6" H 4758 4831 50  0000 C CNN
F 1 "Conn_01x01_Male" H 4758 4740 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x01_P2.54mm_Vertical" H 4650 4650 50  0001 C CNN
F 3 "~" H 4650 4650 50  0001 C CNN
	1    4650 4650
	1    0    0    -1  
$EndComp
Wire Wire Line
	1350 5550 4550 5550
Wire Wire Line
	4550 5250 4550 5550
Connection ~ 4550 5550
Wire Wire Line
	4550 5550 5100 5550
Wire Wire Line
	3850 4250 3800 4250
Wire Wire Line
	4050 4950 4250 4950
Wire Wire Line
	4850 4650 5250 4650
Wire Wire Line
	2900 6650 2900 6750
Wire Wire Line
	3950 6400 3950 6250
Wire Wire Line
	3950 6250 3550 6250
Wire Wire Line
	3550 6250 2900 6250
Connection ~ 3550 6250
Connection ~ 2900 6250
Wire Wire Line
	3950 6500 3950 6800
Wire Wire Line
	3950 6800 3600 6800
Wire Wire Line
	3600 6800 3050 6800
Wire Wire Line
	3050 6800 3050 6650
Wire Wire Line
	3050 6650 2900 6650
Connection ~ 3600 6800
Connection ~ 2900 6650
Wire Wire Line
	4850 4650 4550 4650
Connection ~ 4850 4650
Wire Wire Line
	4050 4950 3850 4950
Wire Wire Line
	3850 4950 3850 4250
Connection ~ 4050 4950
$Comp
L Transistor_BJT:2N3904 Q1
U 1 1 5FA8FEA8
P 2800 6950
F 0 "Q1" H 2990 6996 50  0000 L CNN
F 1 "2N3904" H 2990 6905 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 3000 6875 50  0001 L CIN
F 3 "https://www.onsemi.com/pub/Collateral/2N3903-D.PDF" H 2800 6950 50  0001 L CNN
	1    2800 6950
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Resistors:470OHM-0603-1_10W-1% R5
U 1 1 5F209E6B
P 3600 4250
F 0 "R5" H 3600 4550 45  0000 C CNN
F 1 "500" H 3600 4466 45  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 3600 4400 20  0001 C CNN
F 3 "" H 3600 4250 60  0001 C CNN
F 4 "RES-07869" H 3600 4371 60  0000 C CNN "Field4"
	1    3600 4250
	1    0    0    -1  
$EndComp
$EndSCHEMATC
