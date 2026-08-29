# uart_menu.s -- clause 8 UART menu firmware (FPGA / PuTTY)
#
# Companion: uart_menu.c is the same application written as readable C.
# Hex is assembled from THIS file (tools/gen_uart_menu.py / uart_menu_asm.py).
#
# `li` is expanded as addi+slli (li32), NOT lui: lui writes 0 on this core
# (G-322). Unconditional jumps are `beq zero, zero, L` for the same reason
# the Python generator used that encoding -- `j` would be jal, a different
# instruction. reti is `jalr zero, 0(tp)` = 0x00020067.
#
# MMIO names come from the course io_map.s (UTCL spelling of UCTL).
# Item 1 counts on PORT_LEDR, not LEDG: clause 4/5 have no PORT_LEDG (R2).
#
.include "io_map.s"

# DTCM variable block at VBASE. Words 0..7 are the interrupt vector table.
.eqv VBASE          0x20
.eqv V_MODE         0
.eqv V_VALUE        4
.eqv V_TICK         8
.eqv V_CMD          12
.eqv V_KEYMSG       16
.eqv V_SENDPTR      20
.eqv V_HALFSEC      24
.eqv V_KEYARM       28
.eqv V_HALFSEC_ADDR 0x38
.eqv S_MENU         0x40
.eqv S_NEGEV        0x400

.eqv MASK_BUSY      0x80
.eqv UCTL_RUN       0x08          # 115200 8N1, no parity, not SWRST
.eqv BT_HOLD_CLR    0x24          # BTHOLD | BTCLR
.eqv IE_RX_BT_KEY1  0x0D          # RXIE | BTIE | KEY1IE
.eqv KEY1IFG_MASK   0xF7          # IFG and-mask, KEY1IFG in bit 3

# RARS addi immediates must be integers, not code labels. These are the
# byte addresses of ISR_RX / ISR_BT / ISR_KEY1 below (all fit in 12 bits).
# tools/gen_uart_menu.py refuses to emit hex if the labels move.
.eqv ISR_RX_A       0x22C
.eqv ISR_BT_A       0x238
.eqv ISR_KEY1_A     0x244

# RARS does not support .ifndef/.else, and .eqv cannot be redefined, so
# there is one HALFSEC: the board period. menusim/ is the same image with
# this word patched to 1999 by tools/gen_uart_menu.py (not by a second .eqv).
.eqv HALFSEC        9999999       # 0.5 s at SMCLK = 20 MHz, BTSSEL = 00

#--------------------------------------------------------------
# Code -- ITCM, byte address 0
#--------------------------------------------------------------
.text
    li      a0, UTCL
    li      a1, RXBUF
    li      a2, TXBUF
    li      a3, IE
    li      a4, IFG
    li      a5, PORT_LEDR
    li      a6, BTCTL1
    li      a7, BTCMPR0
    addi    s0, zero, VBASE
    addi    s1, zero, S_MENU
    addi    s2, zero, S_NEGEV
    addi    s6, zero, 0xFF
    addi    t6, zero, MASK_BUSY

    addi    t0, zero, UCTL_RUN
    sw      t0, 0(a0)

    sw      zero, 0(a3)
    sw      zero, 0(a4)

    addi    t0, zero, ISR_RX_A
    sw      t0, 8(zero)
    addi    t0, zero, ISR_BT_A
    sw      t0, 16(zero)
    addi    t0, zero, ISR_KEY1_A
    sw      t0, 20(zero)

    addi    t0, zero, BT_HOLD_CLR
    sw      t0, 0(a6)
    lw      t0, V_HALFSEC(s0)
    sw      t0, 0(a7)
    sw      zero, 0(a6)

    sw      zero, V_MODE(s0)
    sw      zero, V_VALUE(s0)
    sw      zero, V_TICK(s0)
    sw      zero, V_CMD(s0)
    sw      zero, V_KEYMSG(s0)
    sw      zero, V_KEYARM(s0)
    sw      s1, V_SENDPTR(s0)

    addi    t0, zero, IE_RX_BT_KEY1
    sw      t0, 0(a3)
    addi    gp, zero, 1

LOOP:
    lw      t0, V_CMD(s0)
    beq     t0, zero, L_TICK
    sw      zero, V_CMD(s0)
    addi    t1, zero, 0x31
    beq     t0, t1, C1
    addi    t1, zero, 0x32
    beq     t0, t1, C2
    addi    t1, zero, 0x33
    beq     t0, t1, C3
    addi    t1, zero, 0x34
    beq     t0, t1, C4
    addi    t1, zero, 0x35
    beq     t0, t1, C5
    beq     zero, zero, L_TICK

C1:
    addi    t1, zero, 1
    sw      t1, V_MODE(s0)
    sw      zero, V_VALUE(s0)
    beq     zero, zero, L_TICK

C2:
    addi    t1, zero, 2
    sw      t1, V_MODE(s0)
    addi    t1, zero, 0xFF
    sw      t1, V_VALUE(s0)
    beq     zero, zero, L_TICK

C3:
    sw      zero, V_MODE(s0)
    sw      zero, V_VALUE(s0)
    sw      zero, 0(a5)
    beq     zero, zero, L_TICK

C4:
    addi    t1, zero, 1
    sw      t1, V_KEYARM(s0)
    beq     zero, zero, L_TICK

C5:
    sw      s1, V_SENDPTR(s0)

L_TICK:
    lw      t0, V_TICK(s0)
    beq     t0, zero, L_KEY
    sw      zero, V_TICK(s0)
    lw      t1, V_MODE(s0)
    beq     t1, zero, L_KEY
    lw      t2, V_VALUE(s0)
    sw      t2, 0(a5)
    addi    t0, zero, 1
    beq     t1, t0, T_UP
    addi    t2, t2, -1
    beq     zero, zero, T_STORE
T_UP:
    addi    t2, t2, 1
T_STORE:
    and     t2, t2, s6
    sw      t2, V_VALUE(s0)

L_KEY:
    lw      t0, V_KEYMSG(s0)
    beq     t0, zero, L_SEND
    sw      zero, V_KEYMSG(s0)
    sw      s2, V_SENDPTR(s0)

L_SEND:
    lw      t0, V_SENDPTR(s0)
    beq     t0, zero, LOOP
    lw      t1, 0(a0)
    and     t1, t1, t6
    bne     t1, zero, LOOP
    lw      t2, 0(t0)
    beq     t2, zero, S_DONE
    sw      t2, 0(a2)
    addi    t0, t0, 4
    sw      t0, V_SENDPTR(s0)
    beq     zero, zero, LOOP
S_DONE:
    sw      zero, V_SENDPTR(s0)
    beq     zero, zero, LOOP

# ISRs touch only t3/t4 plus the read-only address registers (no stack).
ISR_RX:
    lw      t3, 0(a1)
    sw      t3, V_CMD(s0)
    jalr    zero, 0(tp)

ISR_BT:
    addi    t3, zero, 1
    sw      t3, V_TICK(s0)
    jalr    zero, 0(tp)

ISR_KEY1:
    lw      t3, V_KEYARM(s0)
    beq     t3, zero, K_CLR
    addi    t3, zero, 1
    sw      t3, V_KEYMSG(s0)
K_CLR:
    lw      t3, 0(a4)
    addi    t4, zero, KEY1IFG_MASK
    and     t3, t3, t4
    sw      t3, 0(a4)
    jalr    zero, 0(tp)

#--------------------------------------------------------------
# Data -- DTCM. Vector table words 0..7 are written at run time.
# Characters are stored ONE PER WORD (the loads are lw, not lb).
# RARS has no .org / .stringw; .space is the course equivalent
# (Lab 5 man_compiled test1.s). Assume the data image starts at 0.
#--------------------------------------------------------------
.data
    .space  0x38                  # 0x00..0x37: vectors + vars, zeros
    .word   HALFSEC               # 0x38 V_HALFSEC
    .space  4                     # 0x3C V_KEYARM

    # 0x40 menu, 203 characters + NUL, one ASCII value per word
    .word 0x0D, 0x0A, 0x4D, 0x65, 0x6E, 0x75, 0x0D, 0x0A, 0x31, 0x2E
    .word 0x20, 0x43, 0x6F, 0x75, 0x6E, 0x74, 0x20, 0x66, 0x72, 0x6F
    .word 0x6D, 0x20, 0x30, 0x78, 0x30, 0x30, 0x20, 0x6F, 0x6E, 0x74
    .word 0x6F, 0x20, 0x4C, 0x45, 0x44, 0x52, 0x20, 0x77, 0x69, 0x74
    .word 0x68, 0x20, 0x64, 0x65, 0x6C, 0x61, 0x79, 0x20, 0x7E, 0x30
    .word 0x2E, 0x35, 0x73, 0x65, 0x63, 0x0D, 0x0A, 0x32, 0x2E, 0x20
    .word 0x43, 0x6F, 0x75, 0x6E, 0x74, 0x20, 0x64, 0x6F, 0x77, 0x6E
    .word 0x20, 0x66, 0x72, 0x6F, 0x6D, 0x20, 0x30, 0x78, 0x46, 0x46
    .word 0x20, 0x6F, 0x6E, 0x74, 0x6F, 0x20, 0x4C, 0x45, 0x44, 0x52
    .word 0x20, 0x77, 0x69, 0x74, 0x68, 0x20, 0x64, 0x65, 0x6C, 0x61
    .word 0x79, 0x20, 0x7E, 0x30, 0x2E, 0x35, 0x73, 0x65, 0x63, 0x0D
    .word 0x0A, 0x33, 0x2E, 0x20, 0x43, 0x6C, 0x65, 0x61, 0x72, 0x20
    .word 0x61, 0x6C, 0x6C, 0x20, 0x4C, 0x45, 0x44, 0x73, 0x0D, 0x0A
    .word 0x34, 0x2E, 0x20, 0x4F, 0x6E, 0x20, 0x65, 0x61, 0x63, 0x68
    .word 0x20, 0x4B, 0x45, 0x59, 0x31, 0x20, 0x70, 0x72, 0x65, 0x73
    .word 0x73, 0x65, 0x64, 0x2C, 0x20, 0x73, 0x65, 0x6E, 0x64, 0x20
    .word 0x74, 0x68, 0x65, 0x20, 0x6D, 0x65, 0x73, 0x73, 0x61, 0x67
    .word 0x65, 0x20, 0x49, 0x20, 0x6C, 0x6F, 0x76, 0x65, 0x20, 0x6D
    .word 0x79, 0x20, 0x4E, 0x65, 0x67, 0x65, 0x76, 0x0D, 0x0A, 0x35
    .word 0x2E, 0x20, 0x53, 0x68, 0x6F, 0x77, 0x20, 0x4D, 0x65, 0x6E
    .word 0x75, 0x0D, 0x0A, 0x00

    .space  0x90                  # pad to 0x400

    # 0x400 "I love my Negev\r\n"
    .word 0x49, 0x20, 0x6C, 0x6F, 0x76, 0x65, 0x20, 0x6D, 0x79, 0x20
    .word 0x4E, 0x65, 0x67, 0x65, 0x76, 0x0D, 0x0A, 0x00

