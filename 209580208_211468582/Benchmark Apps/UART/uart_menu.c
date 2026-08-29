/*
 * uart_menu.c -- clause 8 UART menu (MCU side, in C)
 *
 * What this program is
 *   The FPGA talks to a PC terminal (PuTTY, Tera Term, HyperTerminal) at
 *   115200 8N1. At startup it prints the menu below, then reacts to keys
 *   '1'..'5' and to KEY1. That is exactly clause 8 of
 *   Auxiliary/Final Project 2026 definition.md.
 *
 *       Menu
 *       1. Count from 0x00 onto LEDR with delay ~0.5sec
 *       2. Count down from 0xFF onto LEDR with delay ~0.5sec
 *       3. Clear all LEDs
 *       4. On each KEY1 pressed, send the message I love my Negev
 *       5. Show Menu
 *
 *   Item 1 in the spec says LEDG. There is no PORT_LEDG in clause 5's
 *   GPIO map, so this program counts on PORT_LEDR (R2) and the text it
 *   transmits says LEDR so the operator sees what the board does.
 *
 * How it is structured
 *   Interrupt-driven, one polling loop:
 *     ISR_RX    -- a received byte (RXBUF read also clears RXIFG)
 *     ISR_BT    -- Basic Timer EQU0 tick (~0.5 s). BTIFG auto-clears.
 *     ISR_KEY1  -- KEY1; KEY1IFG is cleared in software (rule d)
 *     main      -- dispatch the command, step the LED count, send one
 *                  UART character per pass when the transmitter is free
 *
 * This file vs uart_menu.s
 *   This is the readable C form of the application. The ITCM/DTCM images
 *   on the board are assembled from uart_menu.s (tools/gen_uart_menu.py).
 *   gcc is not used for that image: lui is broken on this core (G-322),
 *   and the ISRs have no stack -- they may only use t3/t4.
 *
 * MMIO names: Auxiliary/Benchmark Apps/GPIO/test0/asm-code/io_map.s
 * (UTCL is the course spelling of UCTL at 0x2018).
 */

#include "io_map.h"

#define REG(addr) (*(volatile unsigned int *)(addr))

/* UCTL: bit 3 selects 115200 (else 9600). 0x08 = 115200, 8N1, running. */
#define UCTL_115200_8N1  0x08
#define UCTL_BUSY        0x80   /* TX or RX in progress */

/* BTCTL1: hold + clear before loading BTCMPR0, then 0 = run, /1, EQU0. */
#define BTCTL1_HOLD_CLR  0x24

/* IE: RXIE | BTIE | KEY1IE. TX interrupts are not used. */
#define IE_RX_BT_KEY1    0x0D

/* KEY1IFG is bit 3 of IFG. The supplied interrupt benchmarks clear it
 * with a read-modify-write AND mask, not by writing 1 to IFG. */
#define KEY1IFG_MASK     0xF7

#ifndef UART_MENU_SIM
#define HALFSEC 9999999u   /* 10,000,000 SMCLK ticks = 0.5 s at 20 MHz */
#else
#define HALFSEC 1999u      /* ModelSim: a tick every 2000 cycles */
#endif

/*
 * DTCM map (byte addresses), matching uart_menu.s:
 *
 *   0x00..0x1F  interrupt vector table (requirement p.14). Filled at
 *               runtime: word 2 = ISR_RX (TYPE 08h), word 4 = ISR_BT
 *               (TYPE 10h), word 5 = ISR_KEY1 (TYPE 14h).
 *   0x20        variables below
 *   0x38        halfsec -- the ONLY word that differs board vs sim
 *   0x40        menu text. In the .s image: one ASCII character per
 *               word, because the transmitter uses lw, not lb.
 *   0x400       "I love my Negev\r\n", same encoding
 */
struct vars {
	unsigned int mode;     /* 0 = idle, 1 = count up, 2 = count down */
	unsigned int value;    /* 8-bit count shown on PORT_LEDR */
	unsigned int tick;     /* 1 when ISR_BT has fired */
	unsigned int cmd;      /* last UART character, or 0 */
	unsigned int keymsg;   /* 1 when KEY1 arrived and item 4 is armed */
	const char  *sendptr;  /* next character to TX, or 0 if idle */
	unsigned int halfsec;  /* loaded into BTCMPR0 at startup */
	unsigned int keyarm;   /* 1 after the operator presses '4' */
};

#define VARS ((volatile struct vars *)0x20)

const char MENU[] =
	"\r\n"
	"Menu\r\n"
	"1. Count from 0x00 onto LEDR with delay ~0.5sec\r\n"
	"2. Count down from 0xFF onto LEDR with delay ~0.5sec\r\n"
	"3. Clear all LEDs\r\n"
	"4. On each KEY1 pressed, send the message I love my Negev\r\n"
	"5. Show Menu\r\n";

const char NEGEV[] = "I love my Negev\r\n";

/* ---- interrupt handlers ------------------------------------------------- */
/* In uart_menu.s these end with jalr zero, 0(tp) (reti) and do not use the
 * stack. Addresses of these handlers are stored in the vector table.     */

void isr_rx(void)
{
	/* Reading RXBUF returns the byte and clears RXIFG (rule b). */
	VARS->cmd = REG(RXBUF);
}

void isr_bt(void)
{
	/* BTIFG is cleared by the interrupt controller when it is serviced. */
	VARS->tick = 1;
}

void isr_key1(void)
{
	if (VARS->keyarm)
		VARS->keymsg = 1;
	REG(IFG) = REG(IFG) & KEY1IFG_MASK;   /* software clear, rule d */
}

/* ---- main --------------------------------------------------------------- */

int main(void)
{
	VARS->mode   = 0;
	VARS->value  = 0;
	VARS->tick   = 0;
	VARS->cmd    = 0;
	VARS->keymsg = 0;
	VARS->keyarm = 0;
	VARS->halfsec = HALFSEC;
	VARS->sendptr = MENU;                 /* print the menu at startup */

	REG(IE)  = 0;
	REG(IFG) = 0;

	REG(UTCL) = UCTL_115200_8N1;

	/* Vector table: DTCM word N is the handler for TYPE = 4*N. */
	*(volatile unsigned int *)0x08 = (unsigned int)isr_rx;    /* TYPE 08h */
	*(volatile unsigned int *)0x10 = (unsigned int)isr_bt;    /* TYPE 10h */
	*(volatile unsigned int *)0x14 = (unsigned int)isr_key1;  /* TYPE 14h */

	REG(BTCTL1)  = BTCTL1_HOLD_CLR;
	REG(BTCMPR0) = VARS->halfsec;
	REG(BTCTL1)  = 0;                     /* run, SMCLK/1, interrupt on EQU0 */

	REG(IE) = IE_RX_BT_KEY1;
	/* EINT: on this MCU GIE is gp[0]. uart_menu.s does  addi gp, zero, 1 */

	for (;;) {
		unsigned int cmd = VARS->cmd;
		if (cmd) {
			VARS->cmd = 0;
			if (cmd == '1') {             /* count up from 0x00 */
				VARS->mode  = 1;
				VARS->value = 0;
			} else if (cmd == '2') {      /* count down from 0xFF */
				VARS->mode  = 2;
				VARS->value = 0xFF;
			} else if (cmd == '3') {      /* clear LEDs and stop */
				VARS->mode  = 0;
				VARS->value = 0;
				REG(PORT_LEDR) = 0;
			} else if (cmd == '4') {      /* arm KEY1 -> Negev message */
				VARS->keyarm = 1;
			} else if (cmd == '5') {      /* print the menu again */
				VARS->sendptr = MENU;
			}
			/* any other character is ignored (no echo, no prompt) */
		}

		if (VARS->tick) {
			VARS->tick = 0;
			if (VARS->mode != 0) {
				REG(PORT_LEDR) = VARS->value;
				if (VARS->mode == 1)
					VARS->value = (VARS->value + 1) & 0xFF;
				else
					VARS->value = (VARS->value - 1) & 0xFF;
			}
		}

		if (VARS->keymsg) {
			VARS->keymsg  = 0;
			VARS->sendptr = NEGEV;
		}

		if (VARS->sendptr) {
			if ((REG(UTCL) & UCTL_BUSY) == 0) {
				unsigned int ch = (unsigned char)*VARS->sendptr;
				if (ch == 0) {
					VARS->sendptr = 0;
				} else {
					REG(TXBUF) = ch;
					VARS->sendptr++;
				}
			}
		}
	}
}
