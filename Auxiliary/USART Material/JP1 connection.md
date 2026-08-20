




DE10-Standard
## User Manual
## 26
www.terasic.com
## March 20, 2018


Figure 3-19 Connections between the GPIO header and Cyclone V SoC FPGA

## Table 3-11
Pin Assignment of Expansion Headers

Signal Name FPGA Pin No. Description I/O Standard
GPIO[0] PIN_W15 GPIO Connection 0[0] 3.3V
GPIO[1] PIN_AK2 GPIO Connection 0[1] 3.3V
GPIO[2] PIN_Y16 GPIO Connection 0[2] 3.3V
GPIO[3] PIN_AK3 GPIO Connection 0[3] 3.3V
GPIO[4] PIN_AJ1 GPIO Connection 0[4] 3.3V
GPIO[5] PIN_AJ2 GPIO Connection 0[5] 3.3V
GPIO[6] PIN_AH2 GPIO Connection 0[6] 3.3V
GPIO[7] PIN_AH3 GPIO Connection 0[7] 3.3V
GPIO[8] PIN_AH4 GPIO Connection 0[8] 3.3V
GPIO[9] PIN_AH5 GPIO Connection 0[9] 3.3V
GPIO[10] PIN_AG1 GPIO Connection 0[10] 3.3V
GPIO[11] PIN_AG2 GPIO Connection 0[11] 3.3V
GPIO[12] PIN_AG3 GPIO Connection 0[12] 3.3V
GPIO[13] PIN_AG5 GPIO Connection 0[13] 3.3V
GPIO[14] PIN_AG6 GPIO Connection 0[14] 3.3V
GPIO[15] PIN_AG7 GPIO Connection 0[15] 3.3V
GPIO[16] PIN_AG8 GPIO Connection 0[16] 3.3V
GPIO[17] PIN_AF4 GPIO Connection 0[17] 3.3V
GPIO[18] PIN_AF5 GPIO Connection 0[18] 3.3V
GPIO[19] PIN_AF6 GPIO Connection 0[19] 3.3V
GPIO[20] PIN_AF8 GPIO Connection 0[20] 3.3V
GPIO[21] PIN_AF9 GPIO Connection 0[21] 3.3V
GPIO[22] PIN_AF10 GPIO Connection 0[22] 3.3V
GPIO[23] PIN_AE7 GPIO Connection 0[23] 3.3V
GPIO[24] PIN_AE9 GPIO Connection 0[24] 3.3V
GPIO[25] PIN_AE11 GPIO Connection 0[25] 3.3V
GPIO[26] PIN_AE12 GPIO Connection 0[26] 3.3V
GPIO[27] PIN_AD7 GPIO Connection 0[27] 3.3V




DE10-Standard
## User Manual
## 27
www.terasic.com
## March 20, 2018

GPIO[28]PIN_AD9GPIO Connection 0[28]3.3V
GPIO[29] PIN_AD10 GPIO Connection 0[29] 3.3V
GPIO[30] PIN_AD11 GPIO Connection 0[30] 3.3V
GPIO[31] PIN_AD12 GPIO Connection 0[31] 3.3V
GPIO[32] PIN_AC9 GPIO Connection 0[32] 3.3V
GPIO[33] PIN_AC12 GPIO Connection 0[33] 3.3V
GPIO[34] PIN_AB12 GPIO Connection 0[34] 3.3V
GPIO[35] PIN_AA12 GPIO Connection 0[35] 3.3V
3.6.4 HSMC Connector
The board contains a  High Speed Mezzanine Card (HSMC) interface to  provide a mechanism for
extending the peripheral-set of an FPGA host board by means of add-on daughter cards, which can
-speed  device  interface  support.
The HSMC interface support JTAG, clock outputs and inputs, high-speed serial I/O (transceivers),
and  single-ended  or  differential  signaling.  Signals  on  the  HSMC  port  is  shown  in Figure  3-20.
Table 3-12 shows the maximum power consumption of the daughter card that connects to HSMC
port.



Figure 3-20 HSMC Signal Bank Diagram



