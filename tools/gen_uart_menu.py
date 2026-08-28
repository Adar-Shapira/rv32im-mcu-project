#!/usr/bin/env python3
"""Generate the clause 8 UART menu firmware -- Phase 12C.

WHAT CLAUSE 8 ASKS FOR, verbatim from the definition (page 12, transcribed in
Auxiliary/Final Project 2026 definition.md:436-452)

    Using serial communication support application of PC side (like
    Hyper-Terminal, Tera-Term, puTTY, etc) and a suitable application for the
    MCU side that supports the next menu (transmitted from MCU to PC):

        Menu
        1. Count from 0x00 onto LEDG with delay ~0.5sec
        2. Count down from 0xFF onto LEDR with delay ~0.5sec
        3. Clear all LEDs
        4. On each KEY1 pressed, send the message "I love my Negev"
        5. Show Menu

ITEM 1 SAYS LEDG. THAT IS A REAL CONFLICT, AND NOT THE ONE THE PLAN RECORDED.
    The plan said LEDG does not exist on the DE2-115. It does: the course's own
    Terasic table lists NINE green LEDs with pins --
    Auxiliary/Lab4/Auxiliary/DE2_115_pin_assignments.csv, LEDG[8..0] on
    PIN_E21/E22/E25/E24/H21/G20/G22/G21/F17, 2.5 V. That claim is corrected.

    The conflict is one level up. Clause 4's I/O list is "Board 10 red LEDs
    (LEDR9-LEDR0) used as Output interface" -- green LEDs are not in the
    declared interface. And clause 5's GPIO table has exactly ONE LED
    register, PORT_LEDR at 0x2000 driving LEDR7-LEDR0. So there is no
    memory-mapped path to LEDG anywhere in the specification: software cannot
    reach those nine pins, whatever the board has. Clause 8 item 1 is the only
    place in the whole document where the string LEDG appears.

    DESIGN DECISION, recorded as R2 in DOC/05: item 1 counts up on PORT_LEDR,
    the same register item 2 counts down on, and the transmitted menu text
    says LEDR so that what the operator reads matches what the LEDs do. The
    alternative -- inventing a PORT_LEDG register, or wiring LEDG to the
    PORT_LEDR byte -- would be adding hardware the specification does not
    ask for, which is exactly what the project rules forbid.

WHAT THIS PROGRAM IS
    An interrupt-driven menu server, 154 instructions, using every peripheral
    the project has: the USART (RX interrupt for commands, TXBUF for the text),
    the Basic Timer (EQU0 as the ~0.5 s tick), PORT_LEDR, KEY1 through the
    interrupt controller, and the two-cycle interrupt entry with reti.

    Structure -- three tiny ISRs and one polling main loop:
      ISR_RX     reads RXBUF (which is also how RXIFG clears, rule b) and
                 leaves the character in V_CMD
      ISR_BT     sets V_TICK. BTIFG auto-clears at service (rule a)
      ISR_KEY1   sets V_KEYMSG if item 4 has been selected, then clears
                 KEY1IFG with the benchmark's own and-mask store, because
                 rule d says the KEYs are cleared manually by software
      main       dispatches V_CMD, advances the LED count on V_TICK, and
                 pushes ONE character per pass from V_SENDPTR whenever the
                 transmitter is not BUSY

    REGISTER DISCIPLINE, because there is no stack and no context save: the
    ISRs touch only t3/t4 and read-only address registers; main uses only
    t0/t1/t2 and the s-registers. An interrupt can therefore land between any
    two instructions of main without corrupting it. (test1's supplied ISRs
    rely on the same convention informally; here it is stated.)

    There is no echo of the received character and no prompt: clause 8 asks
    for the menu to be transmitted and for the five behaviours, nothing else.

TWO IMAGES, ONE PROGRAM
    The ITCM is IDENTICAL for the board and for simulation -- byte-identical,
    and this generator asserts that. What differs is a single DTCM word,
    V_HALFSEC, which the program loads into BTCMPR0 at startup:

        menu/     BTCMPR0 = 9,999,999  -> 10,000,000 SMCLK ticks = 0.5 s at
                  SMCLK = 20 MHz with BTSSEL = 00 (divide by 1). Cross-check:
                  the supplied benchmarks use SEC_PERIOD = 0x01312D00 =
                  20,000,000 for one second at the same setting.
        menusim/  BTCMPR0 = 1,999       -> a tick every 2000 cycles, so a
                  ModelSim run sees the LED sequence in a few thousand cycles
                  instead of ten million.

    A shortened *program* would have meant simulating something other than
    what runs on the board. One data word is the smallest possible difference,
    and it is the one the specification itself parameterises.

USAGE
    python3 tools/gen_uart_menu.py
        Assembles UART/uart_menu.s (the hex source) and writes:
          SIM/RV32IMscMCU/menu/{ITCM.hex,DTCM.hex}       (board, 0.5 s)
          SIM/RV32IMscMCU/menusim/{ITCM.hex,DTCM.hex}    (simulation)
          SIM/RV32IMscMCU/menu/listing.txt
        uart_menu.c is the readable C description of the same program; it is
        not assembled into the hex.
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gen_isa_test import ihex, M32                          # noqa: E402
from model_uart import UartPeriph, divider                  # noqa: E402
from model_interrupt_ctrl import Intc                       # noqa: E402
from model_basic_timer import Timer                         # noqa: E402
from uart_menu_asm import assemble_file, encode_itcm, RETI_WORD  # noqa: E402

FW = ROOT / "UART"

# ── MMIO ─────────────────────────────────────────────────────────────────────
UCTL_A, RXBUF_A, TXBUF_A = 0x2018, 0x2019, 0x201A
IE_A, IFG_A = 0x202C, 0x202D
LEDR_A = 0x2000
BTCTL1_A, BTCMPR0_A = 0x201C, 0x2020

# ── DTCM layout, byte addresses ──────────────────────────────────────────────
# words 0..7 are REQ p14's vector table and cannot be used for anything else
VBASE = 0x020           # the variable block, addressed as offsets off s0
V_MODE, V_VALUE, V_TICK, V_CMD, V_KEYMSG, V_SENDPTR, V_HALFSEC, V_KEYARM = \
    0, 4, 8, 12, 16, 20, 24, 28
S_MENU = 0x040          # the menu text, one character per word, 0-terminated
S_NEGEV = 0x400         # "I love my Negev", same encoding

# ── the two strings ──────────────────────────────────────────────────────────
# Clause 8's own text. Item 1's LEDG reads LEDR, per the decision above; the
# curly quotes around the message are dropped because a serial terminal wants
# 7-bit ASCII and nothing in clause 8 depends on them.
MENU = (
    "\r\n"
    "Menu\r\n"
    "1. Count from 0x00 onto LEDR with delay ~0.5sec\r\n"
    "2. Count down from 0xFF onto LEDR with delay ~0.5sec\r\n"
    "3. Clear all LEDs\r\n"
    "4. On each KEY1 pressed, send the message I love my Negev\r\n"
    "5. Show Menu\r\n"
)
NEGEV = "I love my Negev\r\n"

HALFSEC_BOARD = 9_999_999      # 0.5 s at SMCLK = 20 MHz, BTSSEL = 00
HALFSEC_SIM = 1_999            # a tick every 2000 cycles

CLK_HZ = 20_000_000
BAUD_HIGH = 115200

MASK_BUSY = 0x80


# ── the program ──────────────────────────────────────────────────────────────
def load_program(sim):
    """Assemble uart_menu.s. Returns (prog, byte_labels, dtcm, strings).

    uart_menu.c is the readable C description of the same program; hex comes
    only from the .s (li is expanded with li32, not lui).
    """
    return assemble_file(FW / "uart_menu.s", sim=sim)


def build():
    """Returns (instructions, labels) from the firmware sources."""
    prog, labels, _, _ = load_program(sim=False)
    return prog, labels


def dtcm_image(halfsec):
    """The data image: vector table (written by the program), the variable
    block, and the two strings one character per word."""
    mem = [0] * 1024
    mem[(VBASE + V_HALFSEC) // 4] = halfsec
    for i, ch in enumerate(MENU):
        mem[S_MENU // 4 + i] = ord(ch)
    mem[S_MENU // 4 + len(MENU)] = 0
    for i, ch in enumerate(NEGEV):
        mem[S_NEGEV // 4 + i] = ord(ch)
    mem[S_NEGEV // 4 + len(NEGEV)] = 0
    assert S_MENU // 4 + len(MENU) + 1 <= S_NEGEV // 4, "the menu text overruns"
    assert S_NEGEV // 4 + len(NEGEV) + 1 <= 1024, "the message overruns the DTCM"
    return mem


# ── the second derivation ────────────────────────────────────────────────────
def interpret(prog, labels, halfsec, trace=False):
    """Run the program against the three vetted models with a scripted PC.

    Returns (transmitted_bytes, ledr_writes, cycles).

    The serial engine is emulated at TRANSACTION level and with a SHORT frame,
    deliberately: nothing checked here depends on the frame length, and the
    real bit timing is measured by tb_uart.vhd against the real engine. What
    this reproduces is the byte STREAM and the LED SEQUENCE -- which is exactly
    what tb_uart_menu.vhd checks.
    """
    FRAME = 40                    # cycles per emulated character, see above
    regs, dtcm = {}, {}
    for i, v in enumerate(dtcm_image(halfsec)):
        if v:
            dtcm[i * 4] = v

    uart, intc, tmr = UartPeriph(), Intc(), Timer()

    tx_out = []                   # what the MCU transmitted, in order
    ledr = []                     # every write to PORT_LEDR, in order
    rx_queue = []                 # characters the PC has sent, not yet delivered
    eng = {"tx_left": 0, "tx_byte": 0, "rx_left": 0, "rx_byte": 0}
    key_on = [None, None]

    cyc = 0
    pc, steps = 0, 0

    def rget(r):
        return regs.get(r, 0)

    def rset(r, v):
        if r != "zero":
            regs[r] = v & M32

    def keys_now():
        if key_on[0] is not None and key_on[0] <= cyc < key_on[1]:
            return (1, 0, 0)
        return (0, 0, 0)

    def eng_view():
        return dict(din_rdy=0 if eng["tx_left"] > 0 else 1,
                    rx_busy=1 if eng["rx_left"] > 0 else 0,
                    dout_vld=1 if eng["rx_left"] == 1 else 0,
                    dout=eng["rx_byte"])

    def busy_now():
        e = eng_view()
        return 1 if (e["rx_busy"] or not e["din_rdy"] or uart.txbuf_vld) else 0

    def tick(wr_u=None, rd_u=None, wr_i=None, wr_t=None, inta=1):
        nonlocal cyc
        e = eng_view()
        u = uart.edge(wr=wr_u, rd=rd_u, dout_vld=e["dout_vld"], dout=e["dout"],
                      rx_busy=e["rx_busy"], din_rdy=e["din_rdy"])
        bt = tmr.edge(wr=wr_t)
        intc.edge(wr=wr_i, bt=bt, keys=keys_now(), gie=rget("gp") & 1, inta=inta,
                  rx=u["rx_ev"], rxerr=u["rxerr_ev"], tx=u["tx_ev"],
                  rx_clr=u["rx_clr"], tx_clr=u["tx_clr"])
        if u["tx_ev"]:
            eng["tx_left"] = FRAME
            eng["tx_byte"] = u["txbuf"]
            tx_out.append(u["txbuf"])
        elif eng["tx_left"] > 0:
            eng["tx_left"] -= 1
        if eng["rx_left"] > 0:
            eng["rx_left"] -= 1
        elif rx_queue:
            eng["rx_byte"] = rx_queue.pop(0)
            eng["rx_left"] = FRAME
        cyc += 1

    def mmio_read(a):
        if a == UCTL_A:  return uart.uctl_read(busy_now())
        if a == RXBUF_A: return uart.rxbuf
        if a == TXBUF_A: return uart.txbuf
        if a == IE_A:    return intc.ie
        if a == IFG_A:   return intc.view()
        raise AssertionError(f"unexpected MMIO read {a:#x}")

    def mmio_wr(a, v):
        """-> (uart, intc, timer) write tuples for this edge"""
        if a == UCTL_A:    return ("uctl", v), None, None
        if a == TXBUF_A:   return ("txbuf", v), None, None
        if a == IE_A:      return None, ("ie", v), None
        if a == IFG_A:     return None, ("ifg", v), None
        if a == BTCTL1_A:  return None, None, ("ctl", 0, v)
        if a == BTCMPR0_A: return None, None, ("cmpr0", 0, v)
        if a == LEDR_A:
            ledr.append(v & 0xFF)
            return None, None, None
        raise AssertionError(f"unexpected MMIO write {a:#x}")

    # the scripted PC, advanced by a small state machine on the collected output
    script = {"stage": 0, "mark": 0, "wait_until": 0}

    def pc_step():
        """One step of the scenario. Mirrors tb_uart_menu.vhd exactly."""
        s = script["stage"]
        if s == 0:                                   # the startup menu
            if len(tx_out) >= len(MENU):
                rx_queue.append(ord("2"))
                script["stage"] = 1
                script["mark"] = len(ledr)
        elif s == 1:                                 # count down: 4 values
            if 0xFF in ledr[script["mark"]:]:
                i = ledr.index(0xFF, script["mark"])
                if len(ledr) >= i + 4:
                    rx_queue.append(ord("1"))
                    script["stage"] = 2
                    script["mark"] = len(ledr)
        elif s == 2:                                 # count up: 4 values
            if 0x00 in ledr[script["mark"]:]:
                i = ledr.index(0x00, script["mark"])
                if len(ledr) >= i + 4:
                    rx_queue.append(ord("3"))
                    script["stage"] = 3
                    script["wait_until"] = cyc + 4 * (halfsec + 1)
        elif s == 3:                                 # clear, then let it settle
            if cyc >= script["wait_until"]:
                rx_queue.append(ord("4"))
                script["stage"] = 4
                script["wait_until"] = cyc + 2000
                script["mark"] = len(tx_out)
        elif s == 4:                                 # arm, then press KEY1
            if cyc >= script["wait_until"]:
                key_on[0], key_on[1] = cyc + 2, cyc + 10
                script["stage"] = 5
        elif s == 5:                                 # the message
            if len(tx_out) - script["mark"] >= len(NEGEV):
                rx_queue.append(ord("5"))
                script["stage"] = 6
                script["mark"] = len(tx_out)
        elif s == 6:                                 # the menu again
            if len(tx_out) - script["mark"] >= len(MENU):
                script["stage"] = 7
        return script["stage"]

    while steps < 4_000_000:
        steps += 1
        if pc_step() == 7:
            return tx_out, ledr, cyc

        if intc.view() != 0 and (rget("gp") & 1) == 1:
            tick(inta=0)
            tick()
            tick()
            rset("gp", rget("gp") & ~1)
            rset("tp", pc)
            pc = dtcm.get(intc.type_capt, 0)
            continue

        ins = prog[pc // 4]
        mn = ins[0]
        wr_u = wr_i = wr_t = rd_u = None

        if (mn == "jalr" and ins[1] == "zero" and ins[2] == 0 and ins[3] == "tp") or \
           (mn == "RAW" and ins[1] == RETI_WORD):
            rset("gp", rget("gp") | 1)
            pc = rget("tp")
            tick()
            continue
        if mn == "addi":
            _, rd, rs, imm = ins
            rset(rd, rget(rs) + imm)
        elif mn == "slli":
            _, rd, rs, sh = ins
            rset(rd, rget(rs) << sh)
        elif mn == "and":
            _, rd, ra, rb = ins
            rset(rd, rget(ra) & rget(rb))
        elif mn == "lw":
            _, rd, off, rs = ins
            a = (rget(rs) + off) & M32
            if a >= 0x2000:
                rset(rd, mmio_read(a))
                if a == RXBUF_A:
                    rd_u = "rxbuf"
            else:
                rset(rd, dtcm.get(a, 0))
        elif mn == "sw":
            _, rs2, off, rs1 = ins
            a, v = (rget(rs1) + off) & M32, rget(rs2)
            if a >= 0x2000:
                wr_u, wr_i, wr_t = mmio_wr(a, v)
            else:
                dtcm[a] = v
        elif mn in ("beq", "bne"):
            _, ra, rb, off = ins
            taken = (rget(ra) == rget(rb)) if mn == "beq" else \
                    (rget(ra) != rget(rb))
            if taken:
                pc += off
                tick(wr_u=wr_u, rd_u=rd_u, wr_i=wr_i, wr_t=wr_t)
                continue
        else:
            raise AssertionError(f"instruction outside the subset: {ins}")
        pc += 4
        tick(wr_u=wr_u, rd_u=rd_u, wr_i=wr_i, wr_t=wr_t)
    raise AssertionError("the scenario never completed")


def vhdl_string(s):
    """Render a python string as a VHDL string literal with escapes spelled
    out, so the testbench constant is readable and CR/LF are unambiguous."""
    parts, run = [], ""
    for ch in s:
        if ch == "\r":
            if run:
                parts.append(f'"{run}"')
                run = ""
            parts.append("CR")
        elif ch == "\n":
            if run:
                parts.append(f'"{run}"')
                run = ""
            parts.append("LF")
        else:
            run += ch
    if run:
        parts.append(f'"{run}"')
    return " & ".join(parts)


def main():
    prog, labels, dtcm_board, strs = load_program(sim=False)
    prog_sim, labels_sim, dtcm_sim, _ = load_program(sim=True)
    if labels["ISR_RX"] != 0x22C or labels["ISR_BT"] != 0x238 or \
       labels["ISR_KEY1"] != 0x244:
        sys.exit("ISR labels moved; update ISR_RX_A / ISR_BT_A / ISR_KEY1_A "
                 f"in UART/uart_menu.s (got RX={labels['ISR_RX']:#x} "
                 f"BT={labels['ISR_BT']:#x} KEY1={labels['ISR_KEY1']:#x})")
    if strs["MENU"] != MENU or strs["NEGEV"] != NEGEV:
        sys.exit("firmware MENU/NEGEV strings do not match the generator contract")
    if dtcm_board != dtcm_image(HALFSEC_BOARD):
        sys.exit("assembled board DTCM does not match dtcm_image(HALFSEC_BOARD)")
    if dtcm_sim != dtcm_image(HALFSEC_SIM):
        sys.exit("assembled sim DTCM does not match dtcm_image(HALFSEC_SIM)")

    words = encode_itcm(prog)
    itcm = ihex(words)
    dtcm_board_hex = ihex(dtcm_board)
    dtcm_sim_hex = ihex(dtcm_sim)

    out_board = ROOT / "SIM" / "RV32IMscMCU" / "menu"
    out_sim = ROOT / "SIM" / "RV32IMscMCU" / "menusim"
    gold = {
        "menu/ITCM": out_board / "ITCM.hex",
        "menu/DTCM": out_board / "DTCM.hex",
        "menusim/ITCM": out_sim / "ITCM.hex",
        "menusim/DTCM": out_sim / "DTCM.hex",
    }
    want = {
        "menu/ITCM": itcm,
        "menu/DTCM": dtcm_board_hex,
        "menusim/ITCM": itcm,
        "menusim/DTCM": dtcm_sim_hex,
    }
    mismatch = [n for n, p in gold.items()
                if p.exists() and p.read_text(encoding="utf-8") != want[n]]
    if mismatch:
        sys.exit("assembled images differ from the committed hex: " +
                 ", ".join(mismatch))

    for d in (out_board, out_sim):
        d.mkdir(parents=True, exist_ok=True)
    (out_board / "ITCM.hex").write_text(itcm)
    (out_sim / "ITCM.hex").write_text(itcm)
    (out_board / "DTCM.hex").write_text(dtcm_board_hex)
    (out_sim / "DTCM.hex").write_text(dtcm_sim_hex)

    # the claim in the header, enforced
    assert (out_board / "ITCM.hex").read_bytes() == \
           (out_sim / "ITCM.hex").read_bytes(), \
        "the board and simulation ITCMs must be byte-identical"

    tx, ledr, cycles = interpret(prog, labels, HALFSEC_SIM)

    # ---- the stream the scenario must produce, checked here ----------------
    expected = MENU + NEGEV + MENU
    got = "".join(chr(b) for b in tx)
    if got != expected:
        # show the first divergence rather than two walls of text
        for i, (a, b) in enumerate(zip(got, expected)):
            if a != b:
                sys.exit(f"CROSS-CHECK FAILED: transmitted byte {i} is "
                         f"{a!r}, expected {b!r}\n  got      {got[:i+20]!r}\n"
                         f"  expected {expected[:i+20]!r}")
        sys.exit(f"CROSS-CHECK FAILED: transmitted {len(got)} bytes, expected "
                 f"{len(expected)}\n  got {got!r}")

    # the LED sequences, located the way the testbench locates them
    i_ff = ledr.index(0xFF)
    down = ledr[i_ff:i_ff + 4]
    i_00 = ledr.index(0x00, i_ff + 4)
    up = ledr[i_00:i_00 + 4]
    if down != [0xFF, 0xFE, 0xFD, 0xFC]:
        sys.exit(f"CROSS-CHECK FAILED: count-down produced {down}")
    if up != [0x00, 0x01, 0x02, 0x03]:
        sys.exit(f"CROSS-CHECK FAILED: count-up produced {up}")
    if ledr[-1] != 0x00:
        sys.exit(f"CROSS-CHECK FAILED: item 3 left PORT_LEDR at {ledr[-1]:#04x}")

    lines = [
        "Clause 8 UART menu firmware -- UART/uart_menu.s",
        "(uart_menu.c is the readable C description; hex is assembled from the .s)",
        f"{len(prog)} instructions. ONE program, TWO data images: the ITCMs are",
        "byte-identical and only the V_HALFSEC word differs.",
        "",
        f"  menu/     BTCMPR0 = {HALFSEC_BOARD:,} -> 0.5 s at SMCLK = 20 MHz",
        f"  menusim/  BTCMPR0 = {HALFSEC_SIM:,} -> a tick every "
        f"{HALFSEC_SIM+1} cycles",
        "",
        "  Item 1 counts on PORT_LEDR, not LEDG: clause 4's interface is the ten",
        "  RED LEDs and clause 5's table has exactly one LED register. The board",
        "  does have LEDG[8:0] (Terasic CSV) but no register reaches it. R2.",
        "",
        "Handlers (byte addresses, written into the vector table by the program):",
        f"  ISR_RX   = {labels['ISR_RX']:#06x}  -> DTCM word 2 (TYPE 08h)",
        f"  ISR_BT   = {labels['ISR_BT']:#06x}  -> DTCM word 4 (TYPE 10h)",
        f"  ISR_KEY1 = {labels['ISR_KEY1']:#06x}  -> DTCM word 5 (TYPE 14h)",
        "",
        "DTCM layout, byte addresses:",
        f"  {VBASE + V_MODE:#06x} V_MODE      {VBASE + V_VALUE:#06x} V_VALUE",
        f"  {VBASE + V_TICK:#06x} V_TICK      {VBASE + V_CMD:#06x} V_CMD",
        f"  {VBASE + V_KEYMSG:#06x} V_KEYMSG    {VBASE + V_SENDPTR:#06x} V_SENDPTR",
        f"  {VBASE + V_HALFSEC:#06x} V_HALFSEC   {VBASE + V_KEYARM:#06x} V_KEYARM",
        f"  {S_MENU:#06x} the menu, {len(MENU)} characters, one per word",
        f"  {S_NEGEV:#06x} the message, {len(NEGEV)} characters",
        "",
        "THE SCENARIO, which tb_uart_menu.vhd reproduces with real serial timing:",
        "  1. collect the startup menu           -> send '2'",
        "  2. four LED values from 0xFF          -> send '1'",
        "  3. four LED values from 0x00          -> send '3'",
        "  4. LEDs cleared and the count stops   -> send '4'",
        "  5. press and RELEASE KEY1             -> collect the message",
        "  6. send '5'                           -> collect the menu again",
        "",
        f"Expected transmitted stream: {len(expected)} characters = "
        f"MENU({len(MENU)}) + MESSAGE({len(NEGEV)}) + MENU({len(MENU)}).",
        f"Expected LED sequences: {[hex(v) for v in down]} then "
        f"{[hex(v) for v in up]}, then 0x00 and no further writes.",
        f"The interpreter completes the scenario in {cycles} emulated cycles",
        "(with a shortened frame time; the RTL run is longer because a real",
        f"8N1 frame at 115200 is 10*16*{divider(CLK_HZ, BAUD_HIGH)} = "
        f"{10*16*divider(CLK_HZ, BAUD_HIGH)} cycles).",
        "",
        "THE TESTBENCH'S CONSTANTS, generated so they cannot drift from the",
        "DTCM image they are compared against:",
        "",
        f"  constant MENU_TXT  : string := {vhdl_string(MENU)};",
        f"  constant NEGEV_TXT : string := {vhdl_string(NEGEV)};",
    ]
    (out_board / "listing.txt").write_text("\n".join(lines) + "\n")

    # ---- the drift guard --------------------------------------------------
    # The testbench compares what it decoded against two string constants.
    # Those constants and the DTCM image are two copies of the same text, and
    # this project has already been bitten once by two lists with one edited
    # (5d540c0). So the generator READS THE TESTBENCH BACK and fails if the
    # lines it would have written are not there verbatim.
    want = [f"\tconstant MENU_TXT  : string := {vhdl_string(MENU)};",
            f"\tconstant NEGEV_TXT : string := {vhdl_string(NEGEV)};"]
    # BOTH copies: clause 10 gives each design its own TB directory, so the
    # menu test exists twice and there are three copies of this text in all.
    checked = 0
    for tree in ("RV32IMscMCU", "RV32IMpipelinedMCU"):
        tb = ROOT / "TB" / tree / "tb_uart_menu.vhd"
        if not tb.exists():
            print(f"  TB/{tree}/tb_uart_menu.vhd not present yet; "
                  f"its constants are:")
            for w in want:
                print(w)
            continue
        missing = [w for w in want if w not in tb.read_text()]
        if missing:
            sys.exit(f"DRIFT: TB/{tree}/tb_uart_menu.vhd does not carry the "
                     "text this generator puts in the DTCM image. Replace the "
                     "two lines between the GENERATED markers with:\n\n" +
                     "\n".join(want) + "\n")
        checked += 1
    if checked:
        print(f"  {checked} testbench(es) carry exactly these two strings")

    print(f"  assembled {FW / 'uart_menu.s'}")
    print(f"  {len(prog)} instructions, ITCM identical in both image sets")
    print(f"  menu {len(MENU)} chars, message {len(NEGEV)} chars, "
          f"stream {len(expected)} chars reproduced exactly")
    print(f"  LEDs: {[hex(v) for v in down]} then {[hex(v) for v in up]} then 0x00")
    print(f"  ISR_RX={labels['ISR_RX']:#x} ISR_BT={labels['ISR_BT']:#x} "
          f"ISR_KEY1={labels['ISR_KEY1']:#x}")
    print(f"  scenario complete in {cycles} emulated cycles")
    print(f"  wrote {out_board}/ and {out_sim}/")


if __name__ == "__main__":
    main()
