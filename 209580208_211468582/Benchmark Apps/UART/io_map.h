/* MEMORY Mapped I/O addresses -- same map as io_map.s
 * Reference: Auxiliary/Benchmark Apps/GPIO/test0/asm-code/io_map.s
 * UTCL is the course spelling of UCTL at 0x2018.
 */
#ifndef UART_MENU_IO_MAP_H
#define UART_MENU_IO_MAP_H

#define PORT_LEDR 0x2000

#define PORT_HEX0 0x2004
#define PORT_HEX1 0x2005
#define PORT_HEX2 0x2008
#define PORT_HEX3 0x2009
#define PORT_HEX4 0x200C
#define PORT_HEX5 0x200D

#define PORT_SW   0x2010
#define PORT_PB   0x2014

#define UTCL      0x2018
#define RXBUF     0x2019
#define TXBUF     0x201A

#define BTCTL1    0x201C
#define BTCTL2    0x201D
#define BTCMPR0   0x2020
#define BTCMPR1   0x2024
#define BTCAPR    0x2028

#define IE        0x202C
#define IFG       0x202D
#define TYPE      0x202E

#endif
