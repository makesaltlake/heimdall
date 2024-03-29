EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Regulator_Linear:L7805 U2
U 1 1 5F0A52F0
P 4400 1150
F 0 "U2" H 4400 1392 50  0000 C CNN
F 1 "L7805" H 4400 1301 50  0000 C CNN
F 2 "Package_TO_SOT_THT:TO-220-3_Vertical" H 4425 1000 50  0001 L CIN
F 3 "http://www.st.com/content/ccc/resource/technical/document/datasheet/41/4f/b3/b0/12/d4/47/88/CD00000444.pdf/files/CD00000444.pdf/jcr:content/translations/en.CD00000444.pdf" H 4400 1100 50  0001 C CNN
	1    4400 1150
	1    0    0    -1  
$EndComp
$Comp
L Connector:Barrel_Jack_Switch J1
U 1 1 5F0AB201
P 1100 1600
F 0 "J1" H 1157 1917 50  0000 C CNN
F 1 "Barrel_Jack_Switch" H 1157 1826 50  0000 C CNN
F 2 "Connector_BarrelJack:BarrelJack_Horizontal" H 1150 1560 50  0001 C CNN
F 3 "~" H 1150 1560 50  0001 C CNN
	1    1100 1600
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR06
U 1 1 5F0AEA29
P 4950 1000
F 0 "#PWR06" H 4950 850 50  0001 C CNN
F 1 "+5V" H 4965 1173 50  0000 C CNN
F 2 "" H 4950 1000 50  0001 C CNN
F 3 "" H 4950 1000 50  0001 C CNN
	1    4950 1000
	1    0    0    -1  
$EndComp
$Comp
L power:+12V #PWR05
U 1 1 5F0AFE8D
P 3850 1000
F 0 "#PWR05" H 3850 850 50  0001 C CNN
F 1 "+12V" H 3865 1173 50  0000 C CNN
F 2 "" H 3850 1000 50  0001 C CNN
F 3 "" H 3850 1000 50  0001 C CNN
	1    3850 1000
	1    0    0    -1  
$EndComp
Wire Wire Line
	3850 1000 3850 1150
Wire Wire Line
	4950 1150 4950 1000
$Comp
L power:GND #PWR08
U 1 1 5F0B3CC3
P 1700 2050
F 0 "#PWR08" H 1700 1800 50  0001 C CNN
F 1 "GND" H 1705 1877 50  0000 C CNN
F 2 "" H 1700 2050 50  0001 C CNN
F 3 "" H 1700 2050 50  0001 C CNN
	1    1700 2050
	1    0    0    -1  
$EndComp
Wire Wire Line
	1400 1700 1700 1700
Wire Wire Line
	1700 1700 1700 2050
Wire Wire Line
	4700 1150 4950 1150
Wire Wire Line
	3850 1150 4100 1150
Wire Wire Line
	4400 1600 4400 1450
Connection ~ 4400 1600
Wire Wire Line
	3850 1600 4400 1600
Wire Wire Line
	3850 1400 3850 1600
Connection ~ 3850 1150
Wire Wire Line
	3850 1200 3850 1150
Connection ~ 4950 1150
Wire Wire Line
	4950 1200 4950 1150
Wire Wire Line
	4950 1600 4400 1600
Wire Wire Line
	4950 1400 4950 1600
$Comp
L Device:CP1_Small C3
U 1 1 5F0B8DB7
P 4950 1300
F 0 "C3" H 5041 1346 50  0000 L CNN
F 1 "22µF" H 5041 1255 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.00mm" H 4950 1300 50  0001 C CNN
F 3 "~" H 4950 1300 50  0001 C CNN
	1    4950 1300
	1    0    0    -1  
$EndComp
$Comp
L Device:CP1_Small C2
U 1 1 5F0B81BA
P 3850 1300
F 0 "C2" H 3941 1346 50  0000 L CNN
F 1 "22µF" H 3941 1255 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.00mm" H 3850 1300 50  0001 C CNN
F 3 "~" H 3850 1300 50  0001 C CNN
	1    3850 1300
	1    0    0    -1  
$EndComp
Wire Wire Line
	4400 4450 4000 4450
Wire Wire Line
	4000 4450 4000 4750
$Comp
L heimdall_insideboard-rescue:Relay_HJR-3FF-S-Z-5VDC-Javawizard_Common_Schematic_Symbols-heimdall_insideboard-rescue K1
U 1 1 5F0E96C1
P 8800 650
F 0 "K1" H 9180 146 50  0000 L CNN
F 1 "Relay_HJR-3FF-S-Z-5VDC" H 9180 55  50  0000 L CNN
F 2 "Javawizard_Common_Footprints:JW_Relay_Tianbo_HJR_3FF" H 8350 350 50  0001 C CNN
F 3 "" H 8350 350 50  0001 C CNN
	1    8800 650 
	1    0    0    -1  
$EndComp
$Comp
L Diode:1N4001 D1
U 1 1 5F0EC031
P 7950 1250
F 0 "D1" V 7904 1330 50  0000 L CNN
F 1 "1N4001" V 7995 1330 50  0000 L CNN
F 2 "Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal" H 7950 1075 50  0001 C CNN
F 3 "http://www.vishay.com/docs/88503/1n4001.pdf" H 7950 1250 50  0001 C CNN
	1    7950 1250
	0    1    1    0   
$EndComp
$Comp
L Transistor_BJT:2N3904 Q1
U 1 1 5F0F233F
P 8450 1800
F 0 "Q1" H 8640 1846 50  0000 L CNN
F 1 "2N3904" H 8640 1755 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 8650 1725 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 8450 1800 50  0001 L CNN
	1    8450 1800
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR01
U 1 1 5F0F281C
P 8550 800
F 0 "#PWR01" H 8550 650 50  0001 C CNN
F 1 "+5V" H 8565 973 50  0000 C CNN
F 2 "" H 8550 800 50  0001 C CNN
F 3 "" H 8550 800 50  0001 C CNN
	1    8550 800 
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 800  8550 850 
Wire Wire Line
	7950 1100 7950 850 
Wire Wire Line
	7950 850  8550 850 
Connection ~ 8550 850 
Wire Wire Line
	8550 850  8550 900 
Wire Wire Line
	8550 1500 8550 1550
Wire Wire Line
	8550 1550 7950 1550
Wire Wire Line
	7950 1550 7950 1400
Connection ~ 8550 1550
Wire Wire Line
	8550 1550 8550 1600
$Comp
L power:GND #PWR09
U 1 1 5F0F6E80
P 8550 2100
F 0 "#PWR09" H 8550 1850 50  0001 C CNN
F 1 "GND" H 8555 1927 50  0000 C CNN
F 2 "" H 8550 2100 50  0001 C CNN
F 3 "" H 8550 2100 50  0001 C CNN
	1    8550 2100
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 2100 8550 2000
$Comp
L Device:R_Small_US R1
U 1 1 5F0F80F5
P 8050 1800
F 0 "R1" V 7845 1800 50  0000 C CNN
F 1 "680" V 7936 1800 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 8050 1800 50  0001 C CNN
F 3 "~" H 8050 1800 50  0001 C CNN
	1    8050 1800
	0    1    1    0   
$EndComp
Wire Wire Line
	8150 1800 8250 1800
Wire Wire Line
	6000 4150 7450 4150
Wire Wire Line
	7450 4150 7450 5600
Wire Wire Line
	6000 3950 7350 3950
Wire Wire Line
	7350 3950 7350 1800
Wire Wire Line
	7350 1800 7950 1800
$Comp
L Connector:Screw_Terminal_01x04 J2
U 1 1 5F123CCA
P 10200 2000
F 0 "J2" H 10280 1992 50  0000 L CNN
F 1 "Screw_Terminal_01x04" H 10280 1901 50  0000 L CNN
F 2 "Javawizard_Common_Footprints:PinHeader_JW_1x04_P5.00mm_Vertical" H 10200 2000 50  0001 C CNN
F 3 "~" H 10200 2000 50  0001 C CNN
	1    10200 2000
	1    0    0    1   
$EndComp
Wire Wire Line
	10000 1800 9900 1800
Wire Wire Line
	9900 1800 9900 650 
Wire Wire Line
	9900 650  8850 650 
Wire Wire Line
	8850 650  8850 900 
Wire Wire Line
	10000 2000 9800 2000
Wire Wire Line
	9800 2000 9800 750 
Wire Wire Line
	9800 750  9050 750 
Wire Wire Line
	9050 750  9050 900 
$Comp
L power:GND #PWR010
U 1 1 5F129BC4
P 9900 2200
F 0 "#PWR010" H 9900 1950 50  0001 C CNN
F 1 "GND" H 9905 2027 50  0000 C CNN
F 2 "" H 9900 2200 50  0001 C CNN
F 3 "" H 9900 2200 50  0001 C CNN
	1    9900 2200
	1    0    0    -1  
$EndComp
Wire Wire Line
	10000 2100 9900 2100
Wire Wire Line
	9900 2100 9900 2200
Wire Wire Line
	10000 1900 9500 1900
Wire Wire Line
	8950 1900 8950 1500
$Comp
L Jumper:Jumper_2_Open JP1
U 1 1 5F12E98B
P 10500 1150
F 0 "JP1" V 10546 1062 50  0000 R CNN
F 1 "Jumper" V 10455 1062 50  0000 R CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 10500 1150 50  0001 C CNN
F 3 "~" H 10500 1150 50  0001 C CNN
	1    10500 1150
	0    -1   -1   0   
$EndComp
Wire Wire Line
	9500 1900 9500 1500
Wire Wire Line
	9500 1500 10500 1500
Wire Wire Line
	10500 1500 10500 1350
Connection ~ 9500 1900
Wire Wire Line
	9500 1900 8950 1900
$Comp
L power:+12V #PWR02
U 1 1 5F134B2A
P 10500 850
F 0 "#PWR02" H 10500 700 50  0001 C CNN
F 1 "+12V" H 10515 1023 50  0000 C CNN
F 2 "" H 10500 850 50  0001 C CNN
F 3 "" H 10500 850 50  0001 C CNN
	1    10500 850 
	1    0    0    -1  
$EndComp
Wire Wire Line
	10500 850  10500 950 
Wire Wire Line
	6000 4050 7450 4050
Wire Wire Line
	7450 4050 7450 3700
$Comp
L heimdall_insideboard-rescue:Relay_HJR-3FF-S-Z-5VDC-Javawizard_Common_Schematic_Symbols-heimdall_insideboard-rescue K2
U 1 1 5F14E304
P 8800 2550
F 0 "K2" H 9180 2046 50  0000 L CNN
F 1 "Relay_HJR-3FF-S-Z-5VDC" H 9180 1955 50  0000 L CNN
F 2 "Javawizard_Common_Footprints:JW_Relay_Tianbo_HJR_3FF" H 8350 2250 50  0001 C CNN
F 3 "" H 8350 2250 50  0001 C CNN
	1    8800 2550
	1    0    0    -1  
$EndComp
$Comp
L Diode:1N4001 D2
U 1 1 5F14E30A
P 7950 3150
F 0 "D2" V 7904 3230 50  0000 L CNN
F 1 "1N4001" V 7995 3230 50  0000 L CNN
F 2 "Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal" H 7950 2975 50  0001 C CNN
F 3 "http://www.vishay.com/docs/88503/1n4001.pdf" H 7950 3150 50  0001 C CNN
	1    7950 3150
	0    1    1    0   
$EndComp
$Comp
L Transistor_BJT:2N3904 Q2
U 1 1 5F14E310
P 8450 3700
F 0 "Q2" H 8640 3746 50  0000 L CNN
F 1 "2N3904" H 8640 3655 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 8650 3625 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 8450 3700 50  0001 L CNN
	1    8450 3700
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR011
U 1 1 5F14E316
P 8550 2700
F 0 "#PWR011" H 8550 2550 50  0001 C CNN
F 1 "+5V" H 8565 2873 50  0000 C CNN
F 2 "" H 8550 2700 50  0001 C CNN
F 3 "" H 8550 2700 50  0001 C CNN
	1    8550 2700
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 2700 8550 2750
Wire Wire Line
	7950 3000 7950 2750
Wire Wire Line
	7950 2750 8550 2750
Connection ~ 8550 2750
Wire Wire Line
	8550 2750 8550 2800
Wire Wire Line
	8550 3400 8550 3450
Wire Wire Line
	8550 3450 7950 3450
Wire Wire Line
	7950 3450 7950 3300
Connection ~ 8550 3450
Wire Wire Line
	8550 3450 8550 3500
$Comp
L power:GND #PWR015
U 1 1 5F14E326
P 8550 4000
F 0 "#PWR015" H 8550 3750 50  0001 C CNN
F 1 "GND" H 8555 3827 50  0000 C CNN
F 2 "" H 8550 4000 50  0001 C CNN
F 3 "" H 8550 4000 50  0001 C CNN
	1    8550 4000
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 4000 8550 3900
$Comp
L Device:R_Small_US R6
U 1 1 5F14E32D
P 8050 3700
F 0 "R6" V 7845 3700 50  0000 C CNN
F 1 "680" V 7936 3700 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 8050 3700 50  0001 C CNN
F 3 "~" H 8050 3700 50  0001 C CNN
	1    8050 3700
	0    1    1    0   
$EndComp
Wire Wire Line
	8150 3700 8250 3700
$Comp
L Connector:Screw_Terminal_01x04 J4
U 1 1 5F14E335
P 10200 3900
F 0 "J4" H 10280 3892 50  0000 L CNN
F 1 "Screw_Terminal_01x04" H 10280 3801 50  0000 L CNN
F 2 "Javawizard_Common_Footprints:PinHeader_JW_1x04_P5.00mm_Vertical" H 10200 3900 50  0001 C CNN
F 3 "~" H 10200 3900 50  0001 C CNN
	1    10200 3900
	1    0    0    1   
$EndComp
Wire Wire Line
	10000 3700 9900 3700
Wire Wire Line
	9900 3700 9900 2550
Wire Wire Line
	9900 2550 8850 2550
Wire Wire Line
	8850 2550 8850 2800
Wire Wire Line
	10000 3900 9800 3900
Wire Wire Line
	9800 3900 9800 2650
Wire Wire Line
	9800 2650 9050 2650
Wire Wire Line
	9050 2650 9050 2800
$Comp
L power:GND #PWR016
U 1 1 5F14E343
P 9900 4100
F 0 "#PWR016" H 9900 3850 50  0001 C CNN
F 1 "GND" H 9905 3927 50  0000 C CNN
F 2 "" H 9900 4100 50  0001 C CNN
F 3 "" H 9900 4100 50  0001 C CNN
	1    9900 4100
	1    0    0    -1  
$EndComp
Wire Wire Line
	10000 4000 9900 4000
Wire Wire Line
	9900 4000 9900 4100
Wire Wire Line
	10000 3800 9500 3800
Wire Wire Line
	8950 3800 8950 3400
$Comp
L Jumper:Jumper_2_Open JP2
U 1 1 5F14E34D
P 10500 3050
F 0 "JP2" V 10546 2962 50  0000 R CNN
F 1 "Jumper" V 10455 2962 50  0000 R CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 10500 3050 50  0001 C CNN
F 3 "~" H 10500 3050 50  0001 C CNN
	1    10500 3050
	0    -1   -1   0   
$EndComp
Wire Wire Line
	9500 3800 9500 3400
Wire Wire Line
	9500 3400 10500 3400
Wire Wire Line
	10500 3400 10500 3250
Connection ~ 9500 3800
Wire Wire Line
	9500 3800 8950 3800
$Comp
L power:+12V #PWR012
U 1 1 5F14E358
P 10500 2750
F 0 "#PWR012" H 10500 2600 50  0001 C CNN
F 1 "+12V" H 10515 2923 50  0000 C CNN
F 2 "" H 10500 2750 50  0001 C CNN
F 3 "" H 10500 2750 50  0001 C CNN
	1    10500 2750
	1    0    0    -1  
$EndComp
Wire Wire Line
	10500 2750 10500 2850
$Comp
L heimdall_insideboard-rescue:Relay_HJR-3FF-S-Z-5VDC-Javawizard_Common_Schematic_Symbols-heimdall_insideboard-rescue K3
U 1 1 5F1565E6
P 8800 4450
F 0 "K3" H 9180 3946 50  0000 L CNN
F 1 "Relay_HJR-3FF-S-Z-5VDC" H 9180 3855 50  0000 L CNN
F 2 "Javawizard_Common_Footprints:JW_Relay_Tianbo_HJR_3FF" H 8350 4150 50  0001 C CNN
F 3 "" H 8350 4150 50  0001 C CNN
	1    8800 4450
	1    0    0    -1  
$EndComp
$Comp
L Diode:1N4001 D3
U 1 1 5F1565EC
P 7950 5050
F 0 "D3" V 7904 5130 50  0000 L CNN
F 1 "1N4001" V 7995 5130 50  0000 L CNN
F 2 "Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal" H 7950 4875 50  0001 C CNN
F 3 "http://www.vishay.com/docs/88503/1n4001.pdf" H 7950 5050 50  0001 C CNN
	1    7950 5050
	0    1    1    0   
$EndComp
$Comp
L Transistor_BJT:2N3904 Q3
U 1 1 5F1565F2
P 8450 5600
F 0 "Q3" H 8640 5646 50  0000 L CNN
F 1 "2N3904" H 8640 5555 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 8650 5525 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 8450 5600 50  0001 L CNN
	1    8450 5600
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR017
U 1 1 5F1565F8
P 8550 4600
F 0 "#PWR017" H 8550 4450 50  0001 C CNN
F 1 "+5V" H 8565 4773 50  0000 C CNN
F 2 "" H 8550 4600 50  0001 C CNN
F 3 "" H 8550 4600 50  0001 C CNN
	1    8550 4600
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 4600 8550 4650
Wire Wire Line
	7950 4900 7950 4650
Wire Wire Line
	7950 4650 8550 4650
Connection ~ 8550 4650
Wire Wire Line
	8550 4650 8550 4700
Wire Wire Line
	8550 5300 8550 5350
Wire Wire Line
	8550 5350 7950 5350
Wire Wire Line
	7950 5350 7950 5200
Connection ~ 8550 5350
Wire Wire Line
	8550 5350 8550 5400
$Comp
L power:GND #PWR023
U 1 1 5F156608
P 8550 5900
F 0 "#PWR023" H 8550 5650 50  0001 C CNN
F 1 "GND" H 8555 5727 50  0000 C CNN
F 2 "" H 8550 5900 50  0001 C CNN
F 3 "" H 8550 5900 50  0001 C CNN
	1    8550 5900
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 5900 8550 5800
$Comp
L Device:R_Small_US R15
U 1 1 5F15660F
P 8050 5600
F 0 "R15" V 7845 5600 50  0000 C CNN
F 1 "680" V 7936 5600 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 8050 5600 50  0001 C CNN
F 3 "~" H 8050 5600 50  0001 C CNN
	1    8050 5600
	0    1    1    0   
$EndComp
Wire Wire Line
	8150 5600 8250 5600
$Comp
L Connector:Screw_Terminal_01x04 J6
U 1 1 5F156617
P 10200 5800
F 0 "J6" H 10280 5792 50  0000 L CNN
F 1 "Screw_Terminal_01x04" H 10280 5701 50  0000 L CNN
F 2 "Javawizard_Common_Footprints:PinHeader_JW_1x04_P5.00mm_Vertical" H 10200 5800 50  0001 C CNN
F 3 "~" H 10200 5800 50  0001 C CNN
	1    10200 5800
	1    0    0    1   
$EndComp
Wire Wire Line
	10000 5600 9900 5600
Wire Wire Line
	9900 5600 9900 4450
Wire Wire Line
	9900 4450 8850 4450
Wire Wire Line
	8850 4450 8850 4700
Wire Wire Line
	10000 5800 9800 5800
Wire Wire Line
	9800 5800 9800 4550
Wire Wire Line
	9800 4550 9050 4550
Wire Wire Line
	9050 4550 9050 4700
$Comp
L power:GND #PWR024
U 1 1 5F156625
P 9900 6000
F 0 "#PWR024" H 9900 5750 50  0001 C CNN
F 1 "GND" H 9905 5827 50  0000 C CNN
F 2 "" H 9900 6000 50  0001 C CNN
F 3 "" H 9900 6000 50  0001 C CNN
	1    9900 6000
	1    0    0    -1  
$EndComp
Wire Wire Line
	10000 5900 9900 5900
Wire Wire Line
	9900 5900 9900 6000
Wire Wire Line
	10000 5700 9500 5700
Wire Wire Line
	8950 5700 8950 5300
$Comp
L Jumper:Jumper_2_Open JP3
U 1 1 5F15662F
P 10500 4950
F 0 "JP3" V 10546 4862 50  0000 R CNN
F 1 "Jumper" V 10455 4862 50  0000 R CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 10500 4950 50  0001 C CNN
F 3 "~" H 10500 4950 50  0001 C CNN
	1    10500 4950
	0    -1   -1   0   
$EndComp
Wire Wire Line
	9500 5700 9500 5300
Wire Wire Line
	9500 5300 10500 5300
Wire Wire Line
	10500 5300 10500 5150
Connection ~ 9500 5700
Wire Wire Line
	9500 5700 8950 5700
$Comp
L power:+12V #PWR018
U 1 1 5F15663A
P 10500 4650
F 0 "#PWR018" H 10500 4500 50  0001 C CNN
F 1 "+12V" H 10515 4823 50  0000 C CNN
F 2 "" H 10500 4650 50  0001 C CNN
F 3 "" H 10500 4650 50  0001 C CNN
	1    10500 4650
	1    0    0    -1  
$EndComp
Wire Wire Line
	10500 4650 10500 4750
Wire Wire Line
	7950 3700 7450 3700
Wire Wire Line
	7450 5600 7950 5600
$Comp
L Device:Fuse F1
U 1 1 5F18D2FC
P 1700 1250
F 0 "F1" H 1760 1296 50  0000 L CNN
F 1 "Fuse" H 1760 1205 50  0000 L CNN
F 2 "Fuse:Fuseholder_Cylinder-5x20mm_Stelvio-Kontek_PTF78_Horizontal_Open" V 1630 1250 50  0001 C CNN
F 3 "~" H 1700 1250 50  0001 C CNN
	1    1700 1250
	1    0    0    -1  
$EndComp
Wire Wire Line
	1400 1500 1700 1500
Wire Wire Line
	1700 1500 1700 1400
$Comp
L power:+12V #PWR03
U 1 1 5F1914EA
P 1700 1000
F 0 "#PWR03" H 1700 850 50  0001 C CNN
F 1 "+12V" H 1715 1173 50  0000 C CNN
F 2 "" H 1700 1000 50  0001 C CNN
F 3 "" H 1700 1000 50  0001 C CNN
	1    1700 1000
	1    0    0    -1  
$EndComp
Wire Wire Line
	1700 1100 1700 1000
$Comp
L power:GND #PWR021
U 1 1 5F1BA3D4
P 1300 5100
F 0 "#PWR021" H 1300 4850 50  0001 C CNN
F 1 "GND" H 1305 4927 50  0000 C CNN
F 2 "" H 1300 5100 50  0001 C CNN
F 3 "" H 1300 5100 50  0001 C CNN
	1    1300 5100
	1    0    0    -1  
$EndComp
Wire Wire Line
	950  4400 1300 4400
Wire Wire Line
	1300 4400 1300 5100
Wire Wire Line
	1300 3250 1300 4400
Connection ~ 1300 4400
Wire Wire Line
	950  4500 1950 4500
Wire Wire Line
	950  4600 1850 4600
Wire Wire Line
	950  4700 1750 4700
Wire Wire Line
	950  4800 1650 4800
Wire Wire Line
	4000 3450 4000 3850
Wire Wire Line
	4000 3850 4400 3850
Wire Wire Line
	3900 3550 3900 3950
Wire Wire Line
	3800 3650 3800 4050
Wire Wire Line
	3800 4050 4400 4050
Wire Wire Line
	3050 4500 3050 3750
Wire Wire Line
	3050 3750 4400 3750
Wire Wire Line
	3150 4600 3150 3850
Wire Wire Line
	3150 3850 4000 3850
Connection ~ 4000 3850
Wire Wire Line
	3250 4700 3250 3950
Wire Wire Line
	3250 3950 3900 3950
Connection ~ 3900 3950
Wire Wire Line
	3350 4800 3350 4050
Wire Wire Line
	3350 4050 3800 4050
Connection ~ 3800 4050
Wire Wire Line
	4100 3350 4100 3650
Wire Wire Line
	4100 3650 4400 3650
$Comp
L power:+12V #PWR022
U 1 1 5F2A5516
P 2000 5550
F 0 "#PWR022" H 2000 5400 50  0001 C CNN
F 1 "+12V" H 2015 5723 50  0000 C CNN
F 2 "" H 2000 5550 50  0001 C CNN
F 3 "" H 2000 5550 50  0001 C CNN
	1    2000 5550
	1    0    0    -1  
$EndComp
Wire Wire Line
	2000 5750 1450 5750
$Comp
L power:GND #PWR028
U 1 1 5F2ADB21
P 2000 7250
F 0 "#PWR028" H 2000 7000 50  0001 C CNN
F 1 "GND" H 2005 7077 50  0000 C CNN
F 2 "" H 2000 7250 50  0001 C CNN
F 3 "" H 2000 7250 50  0001 C CNN
	1    2000 7250
	1    0    0    -1  
$EndComp
Wire Wire Line
	2000 5850 1450 5850
$Comp
L Device:R_Small_US R16
U 1 1 5F2B5EE1
P 2450 6550
F 0 "R16" H 2518 6596 50  0000 L CNN
F 1 "1.5k" H 2518 6505 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2450 6550 50  0001 C CNN
F 3 "~" H 2450 6550 50  0001 C CNN
	1    2450 6550
	1    0    0    -1  
$EndComp
Wire Wire Line
	2000 5750 2000 5550
$Comp
L Device:R_Small_US R22
U 1 1 5F2E53B6
P 2450 6950
F 0 "R22" H 2518 6996 50  0000 L CNN
F 1 "2.2k" H 2518 6905 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2450 6950 50  0001 C CNN
F 3 "~" H 2450 6950 50  0001 C CNN
	1    2450 6950
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR030
U 1 1 5F2ECE16
P 2450 7250
F 0 "#PWR030" H 2450 7000 50  0001 C CNN
F 1 "GND" H 2455 7077 50  0000 C CNN
F 2 "" H 2450 7250 50  0001 C CNN
F 3 "" H 2450 7250 50  0001 C CNN
	1    2450 7250
	1    0    0    -1  
$EndComp
Wire Wire Line
	2450 6650 2450 6750
$Comp
L Device:R_Small_US R17
U 1 1 5F2FE497
P 2950 6550
F 0 "R17" H 3018 6596 50  0000 L CNN
F 1 "1.5k" H 3018 6505 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2950 6550 50  0001 C CNN
F 3 "~" H 2950 6550 50  0001 C CNN
	1    2950 6550
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small_US R23
U 1 1 5F2FE49D
P 2950 6950
F 0 "R23" H 3018 6996 50  0000 L CNN
F 1 "2.2k" H 3018 6905 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 2950 6950 50  0001 C CNN
F 3 "~" H 2950 6950 50  0001 C CNN
	1    2950 6950
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR031
U 1 1 5F2FE4A3
P 2950 7250
F 0 "#PWR031" H 2950 7000 50  0001 C CNN
F 1 "GND" H 2955 7077 50  0000 C CNN
F 2 "" H 2950 7250 50  0001 C CNN
F 3 "" H 2950 7250 50  0001 C CNN
	1    2950 7250
	1    0    0    -1  
$EndComp
Wire Wire Line
	2950 6650 2950 6750
Wire Wire Line
	1450 6150 2450 6150
Wire Wire Line
	2450 6150 2450 6450
Wire Wire Line
	2950 6050 2950 6450
Wire Wire Line
	2450 6750 2700 6750
Wire Wire Line
	2700 6750 2700 5100
Wire Wire Line
	2700 5100 3450 5100
Wire Wire Line
	3450 5100 3450 3250
Wire Wire Line
	3450 3250 4200 3250
Wire Wire Line
	4200 3250 4200 3350
Wire Wire Line
	4200 3350 4400 3350
Connection ~ 2450 6750
Wire Wire Line
	2450 6750 2450 6850
Wire Wire Line
	2950 6750 3200 6750
Wire Wire Line
	3200 6750 3200 5200
Wire Wire Line
	3200 5200 3550 5200
Wire Wire Line
	3550 5200 3550 3150
Wire Wire Line
	4300 3150 4300 3250
Wire Wire Line
	4300 3250 4400 3250
Connection ~ 2950 6750
Wire Wire Line
	2950 6750 2950 6850
$Comp
L Transistor_BJT:2N3904 Q4
U 1 1 5F32B841
P 3950 7050
F 0 "Q4" H 4140 7096 50  0000 L CNN
F 1 "2N3904" H 4140 7005 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 4150 6975 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 3950 7050 50  0001 L CNN
	1    3950 7050
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small_US R19
U 1 1 5F342AC7
P 4050 6650
F 0 "R19" H 4118 6696 50  0000 L CNN
F 1 "220" H 4118 6605 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 4050 6650 50  0001 C CNN
F 3 "~" H 4050 6650 50  0001 C CNN
	1    4050 6650
	1    0    0    -1  
$EndComp
Wire Wire Line
	3650 6750 3650 7050
Wire Wire Line
	3650 7050 3750 7050
Wire Wire Line
	4050 6750 4050 6850
Wire Wire Line
	2450 7050 2450 7250
Wire Wire Line
	2950 7050 2950 7250
$Comp
L Transistor_BJT:2N3904 Q5
U 1 1 5F3BFD3A
P 4800 7050
F 0 "Q5" H 4990 7096 50  0000 L CNN
F 1 "2N3904" H 4990 7005 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 5000 6975 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 4800 7050 50  0001 L CNN
	1    4800 7050
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small_US R20
U 1 1 5F3BFD40
P 4500 6650
F 0 "R20" H 4568 6696 50  0000 L CNN
F 1 "2.2k" H 4568 6605 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 4500 6650 50  0001 C CNN
F 3 "~" H 4500 6650 50  0001 C CNN
	1    4500 6650
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small_US R21
U 1 1 5F3BFD46
P 4900 6650
F 0 "R21" H 4968 6696 50  0000 L CNN
F 1 "220" H 4968 6605 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 4900 6650 50  0001 C CNN
F 3 "~" H 4900 6650 50  0001 C CNN
	1    4900 6650
	1    0    0    -1  
$EndComp
Wire Wire Line
	4500 6750 4500 7050
Wire Wire Line
	4500 7050 4600 7050
Wire Wire Line
	4900 6750 4900 6850
$Comp
L power:GND #PWR032
U 1 1 5F3CAA37
P 4050 7250
F 0 "#PWR032" H 4050 7000 50  0001 C CNN
F 1 "GND" H 4055 7077 50  0000 C CNN
F 2 "" H 4050 7250 50  0001 C CNN
F 3 "" H 4050 7250 50  0001 C CNN
	1    4050 7250
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR033
U 1 1 5F3D56A1
P 4900 7250
F 0 "#PWR033" H 4900 7000 50  0001 C CNN
F 1 "GND" H 4905 7077 50  0000 C CNN
F 2 "" H 4900 7250 50  0001 C CNN
F 3 "" H 4900 7250 50  0001 C CNN
	1    4900 7250
	1    0    0    -1  
$EndComp
Wire Wire Line
	3650 6550 3650 4350
Wire Wire Line
	3650 4350 4400 4350
Wire Wire Line
	4500 6550 4500 6050
Wire Wire Line
	4500 6050 3750 6050
Wire Wire Line
	3750 6050 3750 4150
Wire Wire Line
	3750 4150 4400 4150
Wire Wire Line
	1450 6350 4050 6350
Wire Wire Line
	4050 6350 4050 6550
Wire Wire Line
	1450 6250 4900 6250
Wire Wire Line
	4900 6250 4900 6550
$Comp
L Regulator_Linear:LM1117-3.3 U1
U 1 1 5F437F4D
P 3300 1150
F 0 "U1" H 3300 1392 50  0000 C CNN
F 1 "LM1117-3.3" H 3300 1301 50  0000 C CNN
F 2 "Package_TO_SOT_THT:TO-220-3_Vertical" H 3300 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/ds/symlink/lm1117.pdf" H 3300 1150 50  0001 C CNN
	1    3300 1150
	-1   0    0    -1  
$EndComp
Wire Wire Line
	3850 1150 3600 1150
Wire Wire Line
	3000 1150 2750 1150
Wire Wire Line
	2750 1150 2750 1000
Wire Wire Line
	3300 1450 3300 1600
Wire Wire Line
	3300 1600 3850 1600
Connection ~ 3850 1600
Wire Wire Line
	2750 1400 2750 1600
$Comp
L Device:CP1_Small C1
U 1 1 5F486AB9
P 2750 1300
F 0 "C1" H 2841 1346 50  0000 L CNN
F 1 "22µF" H 2841 1255 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.00mm" H 2750 1300 50  0001 C CNN
F 3 "~" H 2750 1300 50  0001 C CNN
	1    2750 1300
	1    0    0    -1  
$EndComp
Wire Wire Line
	2750 1200 2750 1150
Connection ~ 2750 1150
Wire Wire Line
	2750 1600 3300 1600
Connection ~ 3300 1600
$Comp
L power:GND #PWR07
U 1 1 5F4AEF2C
P 3850 1700
F 0 "#PWR07" H 3850 1450 50  0001 C CNN
F 1 "GND" H 3855 1527 50  0000 C CNN
F 2 "" H 3850 1700 50  0001 C CNN
F 3 "" H 3850 1700 50  0001 C CNN
	1    3850 1700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3850 1700 3850 1600
$Comp
L Connector:Screw_Terminal_01x09 J8
U 1 1 5F4CAD98
P 6150 6850
F 0 "J8" V 6275 6846 50  0000 C CNN
F 1 "Screw_Terminal_01x09" V 6366 6846 50  0000 C CNN
F 2 "Javawizard_Common_Footprints:PinHeader_JW_1x09_P5.00mm_Vertical" H 6150 6850 50  0001 C CNN
F 3 "~" H 6150 6850 50  0001 C CNN
	1    6150 6850
	0    1    1    0   
$EndComp
$Comp
L power:+12V #PWR027
U 1 1 5F4CD60C
P 6550 6450
F 0 "#PWR027" H 6550 6300 50  0001 C CNN
F 1 "+12V" H 6565 6623 50  0000 C CNN
F 2 "" H 6550 6450 50  0001 C CNN
F 3 "" H 6550 6450 50  0001 C CNN
	1    6550 6450
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR026
U 1 1 5F4CDDFD
P 6350 6450
F 0 "#PWR026" H 6350 6300 50  0001 C CNN
F 1 "+5V" H 6365 6623 50  0000 C CNN
F 2 "" H 6350 6450 50  0001 C CNN
F 3 "" H 6350 6450 50  0001 C CNN
	1    6350 6450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR029
U 1 1 5F4CEE15
P 5500 6650
F 0 "#PWR029" H 5500 6400 50  0001 C CNN
F 1 "GND" H 5505 6477 50  0000 C CNN
F 2 "" H 5500 6650 50  0001 C CNN
F 3 "" H 5500 6650 50  0001 C CNN
	1    5500 6650
	1    0    0    -1  
$EndComp
Wire Wire Line
	6550 6450 6550 6550
Wire Wire Line
	6450 6650 6450 6550
Wire Wire Line
	6450 6550 6550 6550
Connection ~ 6550 6550
Wire Wire Line
	6550 6550 6550 6650
Wire Wire Line
	6350 6650 6350 6550
Wire Wire Line
	6250 6650 6250 6550
Wire Wire Line
	6250 6550 6350 6550
Connection ~ 6350 6550
Wire Wire Line
	6350 6550 6350 6450
Wire Wire Line
	6150 6650 6150 6550
Wire Wire Line
	6050 6650 6050 6550
Wire Wire Line
	6050 6550 6150 6550
Connection ~ 6150 6550
Wire Wire Line
	6150 6550 6150 6450
Wire Wire Line
	5750 6650 5750 6550
Wire Wire Line
	5750 6550 5500 6550
Wire Wire Line
	5500 6550 5500 6650
Wire Wire Line
	5850 6650 5850 6550
Wire Wire Line
	5850 6550 5750 6550
Connection ~ 5750 6550
Wire Wire Line
	5950 6650 5950 6550
Wire Wire Line
	5950 6550 5850 6550
Connection ~ 5850 6550
$Comp
L Connector_Generic:Conn_01x09 J5
U 1 1 5F163904
P 750 4600
F 0 "J5" H 668 5217 50  0000 C CNN
F 1 "Conn_01x09" H 668 5126 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x09_P2.54mm_Vertical" H 750 4600 50  0001 C CNN
F 3 "~" H 750 4600 50  0001 C CNN
	1    750  4600
	-1   0    0    -1  
$EndComp
Wire Wire Line
	2150 3450 4000 3450
$Comp
L power:+5V #PWR013
U 1 1 5F26A188
P 1100 2800
F 0 "#PWR013" H 1100 2650 50  0001 C CNN
F 1 "+5V" V 1115 2973 50  0000 L BNN
F 2 "" H 1100 2800 50  0001 C CNN
F 3 "" H 1100 2800 50  0001 C CNN
	1    1100 2800
	1    0    0    -1  
$EndComp
Wire Wire Line
	1200 2800 1200 3150
Wire Wire Line
	1100 2800 1100 3050
Wire Wire Line
	1100 3050 1100 4200
Wire Wire Line
	1100 4200 950  4200
Connection ~ 1100 3050
Wire Wire Line
	1200 3150 1200 4300
Connection ~ 1200 3150
Wire Wire Line
	3900 3950 4400 3950
Wire Wire Line
	1950 3650 3800 3650
Wire Wire Line
	1550 4900 950  4900
Wire Wire Line
	950  5000 1450 5000
Wire Wire Line
	6000 3150 6100 3150
Wire Wire Line
	6100 3150 6100 2800
Wire Wire Line
	6100 2800 2750 2800
Wire Wire Line
	2750 2800 2750 3850
Wire Wire Line
	2750 3850 1750 3850
Wire Wire Line
	6000 3250 6200 3250
Wire Wire Line
	6200 3250 6200 2700
Wire Wire Line
	6200 2700 2650 2700
Wire Wire Line
	2650 2700 2650 3750
Wire Wire Line
	2650 3750 1850 3750
Wire Wire Line
	6000 3550 6300 3550
Wire Wire Line
	6300 3550 6300 2600
Wire Wire Line
	6300 2600 2550 2600
Wire Wire Line
	2550 2600 2550 5000
Wire Wire Line
	6000 3650 6400 3650
Wire Wire Line
	6400 3650 6400 2500
Wire Wire Line
	6400 2500 2450 2500
Wire Wire Line
	2450 2500 2450 4900
NoConn ~ 1400 1600
NoConn ~ 4400 3450
NoConn ~ 4400 3550
NoConn ~ 4400 3150
NoConn ~ 4400 4250
NoConn ~ 6000 4250
NoConn ~ 6000 4450
NoConn ~ 6000 4550
NoConn ~ 6000 3850
NoConn ~ 6000 3450
NoConn ~ 6000 3350
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 5F2378DF
P 6000 1000
F 0 "#FLG0101" H 6000 1075 50  0001 C CNN
F 1 "PWR_FLAG" H 6000 1173 50  0000 C CNN
F 2 "" H 6000 1000 50  0001 C CNN
F 3 "~" H 6000 1000 50  0001 C CNN
	1    6000 1000
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 5F238321
P 6400 1000
F 0 "#FLG0102" H 6400 1075 50  0001 C CNN
F 1 "PWR_FLAG" H 6400 1173 50  0000 C CNN
F 2 "" H 6400 1000 50  0001 C CNN
F 3 "~" H 6400 1000 50  0001 C CNN
	1    6400 1000
	1    0    0    -1  
$EndComp
$Comp
L power:+12V #PWR0101
U 1 1 5F238D05
P 6000 1100
F 0 "#PWR0101" H 6000 950 50  0001 C CNN
F 1 "+12V" H 6015 1273 50  0000 C CNN
F 2 "" H 6000 1100 50  0001 C CNN
F 3 "" H 6000 1100 50  0001 C CNN
	1    6000 1100
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 5F239622
P 6400 1100
F 0 "#PWR0102" H 6400 850 50  0001 C CNN
F 1 "GND" H 6405 927 50  0000 C CNN
F 2 "" H 6400 1100 50  0001 C CNN
F 3 "" H 6400 1100 50  0001 C CNN
	1    6400 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	6400 1000 6400 1100
Wire Wire Line
	6000 1000 6000 1100
Text Label 9000 1900 0    50   ~ 0
RELAY1_C
Text Label 8900 650  0    50   ~ 0
RELAY1_NC
Text Label 9100 750  0    50   ~ 0
RELAY1_NO
Text Label 9000 3800 0    50   ~ 0
RELAY2_C
Text Label 8900 2550 0    50   ~ 0
RELAY2_NC
Text Label 9100 2650 0    50   ~ 0
RELAY2_NO
Text Label 9000 5700 0    50   ~ 0
RELAY3_C
Text Label 8900 4450 0    50   ~ 0
RELAY3_NC
Text Label 9100 4550 0    50   ~ 0
RELAY3_NO
Text Label 1500 1500 0    50   ~ 0
12V_BEFORE_FUSE
$Comp
L Connector:Screw_Terminal_01x02 J9
U 1 1 5F13EE5E
P 7000 5800
F 0 "J9" V 6872 5880 50  0000 L CNN
F 1 "Screw_Terminal_01x02" V 6963 5880 50  0000 L CNN
F 2 "Javawizard_Common_Footprints:PinHeader_JW_1x02_P5.00mm_Vertical" H 7000 5800 50  0001 C CNN
F 3 "~" H 7000 5800 50  0001 C CNN
	1    7000 5800
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR0103
U 1 1 5F140007
P 6550 5950
F 0 "#PWR0103" H 6550 5700 50  0001 C CNN
F 1 "GND" H 6555 5777 50  0000 C CNN
F 2 "" H 6550 5950 50  0001 C CNN
F 3 "" H 6550 5950 50  0001 C CNN
	1    6550 5950
	1    0    0    -1  
$EndComp
Wire Wire Line
	6900 5600 6550 5600
Wire Wire Line
	7000 5600 7000 3750
Wire Wire Line
	7000 3750 6000 3750
$Comp
L power:+5V #PWR0104
U 1 1 605868AC
P 6100 5050
F 0 "#PWR0104" H 6100 4900 50  0001 C CNN
F 1 "+5V" H 6115 5223 50  0000 C CNN
F 2 "" H 6100 5050 50  0001 C CNN
F 3 "" H 6100 5050 50  0001 C CNN
	1    6100 5050
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0105
U 1 1 605DA8FD
P 6100 5950
F 0 "#PWR0105" H 6100 5700 50  0001 C CNN
F 1 "GND" H 6105 5777 50  0000 C CNN
F 2 "" H 6100 5950 50  0001 C CNN
F 3 "" H 6100 5950 50  0001 C CNN
	1    6100 5950
	1    0    0    -1  
$EndComp
Wire Wire Line
	6000 4350 6500 4350
$Comp
L Jumper:Jumper_2_Open JP4
U 1 1 60618C40
P 1600 6800
F 0 "JP4" V 1646 6712 50  0000 R CNN
F 1 "Jumper" V 1555 6712 50  0000 R CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 1600 6800 50  0001 C CNN
F 3 "~" H 1600 6800 50  0001 C CNN
	1    1600 6800
	0    -1   -1   0   
$EndComp
Wire Wire Line
	2000 5850 2000 7000
Wire Wire Line
	1600 6600 1600 5950
Wire Wire Line
	1600 5950 1450 5950
Wire Wire Line
	1600 7000 2000 7000
Connection ~ 2000 7000
Wire Wire Line
	2000 7000 2000 7250
Wire Wire Line
	6100 5100 6100 5050
$Comp
L Transistor_BJT:2N3904 Q6
U 1 1 607CCCEB
P 5250 5650
F 0 "Q6" H 5440 5696 50  0000 L CNN
F 1 "2N3904" H 5440 5605 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline_Wide" H 5450 5575 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 5250 5650 50  0001 L CNN
	1    5250 5650
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small_US R25
U 1 1 607CE114
P 5350 5250
F 0 "R25" H 5418 5296 50  0000 L CNN
F 1 "1.5k" H 5418 5205 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 5350 5250 50  0001 C CNN
F 3 "~" H 5350 5250 50  0001 C CNN
	1    5350 5250
	1    0    0    -1  
$EndComp
Wire Wire Line
	6100 5050 5350 5050
Wire Wire Line
	5350 5050 5350 5150
Connection ~ 6100 5050
Wire Wire Line
	5350 5350 5350 5400
Wire Wire Line
	6550 5600 6550 5950
Wire Wire Line
	6100 5700 6100 5900
Wire Wire Line
	5350 5850 5350 5900
Wire Wire Line
	5350 5900 6100 5900
Connection ~ 6100 5900
Wire Wire Line
	6100 5900 6100 5950
Wire Wire Line
	5800 5400 5350 5400
Connection ~ 5350 5400
Wire Wire Line
	5350 5400 5350 5450
$Comp
L Device:R_Small_US R24
U 1 1 60858559
P 4900 5250
F 0 "R24" H 4968 5296 50  0000 L CNN
F 1 "2.2k" H 4968 5205 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 4900 5250 50  0001 C CNN
F 3 "~" H 4900 5250 50  0001 C CNN
	1    4900 5250
	1    0    0    -1  
$EndComp
Wire Wire Line
	4900 5350 4900 5650
Wire Wire Line
	4900 5650 5050 5650
Wire Wire Line
	4900 5150 4900 4750
Wire Wire Line
	4900 4750 6500 4750
Wire Wire Line
	6500 4750 6500 4350
Wire Wire Line
	3550 3150 4300 3150
Wire Wire Line
	2250 3350 4100 3350
Wire Wire Line
	950  3850 1450 3850
Wire Wire Line
	950  3750 1550 3750
Wire Wire Line
	950  3650 1650 3650
Wire Wire Line
	950  3550 1750 3550
Wire Wire Line
	950  3350 1950 3350
Wire Wire Line
	950  3250 1300 3250
Wire Wire Line
	1200 3150 950  3150
Wire Wire Line
	1100 3050 950  3050
Wire Wire Line
	1850 3450 950  3450
Wire Wire Line
	2050 3550 3900 3550
Wire Wire Line
	1200 4300 950  4300
Wire Wire Line
	2250 4500 3050 4500
Wire Wire Line
	2450 4900 1850 4900
Wire Wire Line
	2550 5000 1750 5000
Wire Wire Line
	1950 4800 3350 4800
Wire Wire Line
	2050 4700 3250 4700
Wire Wire Line
	2150 4600 3150 4600
$Comp
L LED:NeoPixel_THT D4
U 1 1 6058485B
P 6100 5400
F 0 "D4" H 6444 5446 50  0000 L CNN
F 1 "NeoPixel_THT" H 6444 5355 50  0000 L CNN
F 2 "LED_THT:LED_D5.0mm-4_RGB_Wide_Pins" H 6150 5100 50  0001 L TNN
F 3 "https://www.adafruit.com/product/1938" H 6200 5025 50  0001 L TNN
	1    6100 5400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR019
U 1 1 5F0E4BC5
P 4000 4750
F 0 "#PWR019" H 4000 4500 50  0001 C CNN
F 1 "GND" H 4005 4577 50  0000 C CNN
F 2 "" H 4000 4750 50  0001 C CNN
F 3 "" H 4000 4750 50  0001 C CNN
	1    4000 4750
	1    0    0    -1  
$EndComp
$Comp
L power:+3.3V #PWR0106
U 1 1 61BDB374
P 2750 1000
F 0 "#PWR0106" H 2750 850 50  0001 C CNN
F 1 "+3.3V" H 2765 1173 50  0000 C CNN
F 2 "" H 2750 1000 50  0001 C CNN
F 3 "" H 2750 1000 50  0001 C CNN
	1    2750 1000
	1    0    0    -1  
$EndComp
$Comp
L power:+3.3V #PWR0107
U 1 1 61BF4D8D
P 1200 2800
F 0 "#PWR0107" H 1200 2650 50  0001 C CNN
F 1 "+3.3V" V 1215 2973 50  0000 L BNN
F 2 "" H 1200 2800 50  0001 C CNN
F 3 "" H 1200 2800 50  0001 C CNN
	1    1200 2800
	1    0    0    -1  
$EndComp
$Comp
L power:+3.3V #PWR0108
U 1 1 61C26764
P 6150 6450
F 0 "#PWR0108" H 6150 6300 50  0001 C CNN
F 1 "+3.3V" H 6165 6623 50  0000 C CNN
F 2 "" H 6150 6450 50  0001 C CNN
F 3 "" H 6150 6450 50  0001 C CNN
	1    6150 6450
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R11
U 1 1 61DE7E44
P 1900 4700
F 0 "R11" V 1850 4550 39  0000 C TNN
F 1 "220" V 1950 4850 39  0000 C CNN
F 2 "" V 1940 4690 50  0001 C CNN
F 3 "~" H 1900 4700 50  0001 C CNN
	1    1900 4700
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R12
U 1 1 61DE7E4E
P 1800 4800
F 0 "R12" V 1750 4650 39  0000 C TNN
F 1 "220" V 1850 4950 39  0000 C CNN
F 2 "" V 1840 4790 50  0001 C CNN
F 3 "~" H 1800 4800 50  0001 C CNN
	1    1800 4800
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R13
U 1 1 61DE7E58
P 1700 4900
F 0 "R13" V 1650 4750 39  0000 C TNN
F 1 "220" V 1750 5050 39  0000 C CNN
F 2 "" V 1740 4890 50  0001 C CNN
F 3 "~" H 1700 4900 50  0001 C CNN
	1    1700 4900
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R14
U 1 1 61DE7E62
P 1600 5000
F 0 "R14" V 1550 4850 39  0000 C TNN
F 1 "220" V 1650 5150 39  0000 C CNN
F 2 "" V 1640 4990 50  0001 C CNN
F 3 "~" H 1600 5000 50  0001 C CNN
	1    1600 5000
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R3
U 1 1 62067C92
P 2000 3450
F 0 "R3" V 1950 3300 39  0000 C TNN
F 1 "220" V 2050 3600 39  0000 C CNN
F 2 "" V 2040 3440 50  0001 C CNN
F 3 "~" H 2000 3450 50  0001 C CNN
	1    2000 3450
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R4
U 1 1 62067C9C
P 1900 3550
F 0 "R4" V 1850 3400 39  0000 C TNN
F 1 "220" V 1950 3700 39  0000 C CNN
F 2 "" V 1940 3540 50  0001 C CNN
F 3 "~" H 1900 3550 50  0001 C CNN
	1    1900 3550
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R5
U 1 1 62067CA6
P 1800 3650
F 0 "R5" V 1750 3500 39  0000 C TNN
F 1 "220" V 1850 3800 39  0000 C CNN
F 2 "" V 1840 3640 50  0001 C CNN
F 3 "~" H 1800 3650 50  0001 C CNN
	1    1800 3650
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R7
U 1 1 62067CB0
P 1700 3750
F 0 "R7" V 1650 3600 39  0000 C TNN
F 1 "220" V 1750 3900 39  0000 C CNN
F 2 "" V 1740 3740 50  0001 C CNN
F 3 "~" H 1700 3750 50  0001 C CNN
	1    1700 3750
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R8
U 1 1 62067CBA
P 1600 3850
F 0 "R8" V 1550 3700 39  0000 C TNN
F 1 "220" V 1650 4000 39  0000 C CNN
F 2 "" V 1640 3840 50  0001 C CNN
F 3 "~" H 1600 3850 50  0001 C CNN
	1    1600 3850
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R2
U 1 1 62067CC4
P 2100 3350
F 0 "R2" V 2050 3200 39  0000 C TNN
F 1 "220" V 2150 3500 39  0000 C CNN
F 2 "" V 2140 3340 50  0001 C CNN
F 3 "~" H 2100 3350 50  0001 C CNN
	1    2100 3350
	0    1    1    0   
$EndComp
$Comp
L Connector_Generic:Conn_01x09 J3
U 1 1 5F11D769
P 750 3450
F 0 "J3" H 668 4067 50  0000 C CNN
F 1 "Conn_01x09" H 668 3976 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x09_P2.54mm_Vertical" H 750 3450 50  0001 C CNN
F 3 "~" H 750 3450 50  0001 C CNN
	1    750  3450
	-1   0    0    -1  
$EndComp
$Comp
L power:+5V #PWR020
U 1 1 5F0E673A
P 4400 4550
F 0 "#PWR020" H 4400 4400 50  0001 C CNN
F 1 "+5V" V 4350 4850 50  0000 R TNN
F 2 "" H 4400 4550 50  0001 C CNN
F 3 "" H 4400 4550 50  0001 C CNN
	1    4400 4550
	0    -1   -1   0   
$EndComp
$Comp
L Device:R_US R10
U 1 1 61DE7E3A
P 2000 4600
F 0 "R10" V 1950 4450 39  0000 C TNN
F 1 "220" V 2050 4750 39  0000 C CNN
F 2 "" V 2040 4590 50  0001 C CNN
F 3 "~" H 2000 4600 50  0001 C CNN
	1    2000 4600
	0    1    1    0   
$EndComp
$Comp
L Device:R_Small_US R18
U 1 1 5F32CFFF
P 3650 6650
F 0 "R18" H 3718 6696 50  0000 L CNN
F 1 "2.2k" H 3718 6605 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" H 3650 6650 50  0001 C CNN
F 3 "~" H 3650 6650 50  0001 C CNN
	1    3650 6650
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R9
U 1 1 61DE7E6C
P 2100 4500
F 0 "R9" V 2050 4350 39  0000 C TNN
F 1 "220" V 2150 4650 39  0000 C CNN
F 2 "" V 2140 4490 50  0001 C CNN
F 3 "~" H 2100 4500 50  0001 C CNN
	1    2100 4500
	0    1    1    0   
$EndComp
NoConn ~ 6400 5400
Text Notes 950  3350 0    20   ~ 0
U3-6\nCS
Text Notes 950  3450 0    20   ~ 0
U3-8\nSCK
Text Notes 950  3550 0    20   ~ 0
U3-9\nMOSI
Text Notes 950  3650 0    20   ~ 0
U3-10\nMISO
Text Notes 950  3750 0    20   ~ 0
U3-29\nLED
Text Notes 950  3850 0    20   ~ 0
U3-30\nBeeper
Text Notes 950  3250 0    20   ~ 0
GND
Text Notes 950  3150 0    20   ~ 0
+3.3v
Text Notes 950  3050 0    20   ~ 0
+5v
Text Notes 950  4500 0    20   ~ 0
U3-7\nCS
Text Notes 950  4600 0    20   ~ 0
U3-8\nSCK
Text Notes 950  4700 0    20   ~ 0
U3-9\nMOSI
Text Notes 950  4800 0    20   ~ 0
U3-10\nMISO
Text Notes 950  4900 0    20   ~ 0
U3-25\nLED
Text Notes 950  5000 0    20   ~ 0
U3-26\nBeeper
Text Notes 950  4400 0    20   ~ 0
GND
Text Notes 950  4300 0    20   ~ 0
+3.3v
Text Notes 950  4200 0    20   ~ 0
+5v
$Comp
L Connector:Screw_Terminal_01x07 J7
U 1 1 5F2A191F
P 1250 6050
F 0 "J7" H 1168 5525 50  0000 C CNN
F 1 "Screw_Terminal_01x06" H 1168 5616 50  0000 C CNN
F 2 "Javawizard_Common_Footprints:PinHeader_JW_1x07_P5.00mm_Vertical" H 1250 6050 50  0001 C CNN
F 3 "~" H 1250 6050 50  0001 C CNN
	1    1250 6050
	-1   0    0    1   
$EndComp
Wire Wire Line
	1450 6050 2950 6050
$Comp
L heimdall_insideboard-rescue:ESP32_Dev_Board_30Pin-Javawizard_Common_Schematic_Symbols-heimdall_insideboard-rescue U3
U 1 1 60F8483A
P 5200 3000
F 0 "U3" H 5200 3115 50  0000 C CNN
F 1 "ESP32_Dev_Board_30Pin" H 5200 3024 50  0000 C CNN
F 2 "" H 4650 3000 50  0001 C CNN
F 3 "" H 4650 3000 50  0001 C CNN
	1    5200 3000
	1    0    0    -1  
$EndComp
$EndSCHEMATC
