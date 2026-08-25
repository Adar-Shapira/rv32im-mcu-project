--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 9A: the Interrupt Controller, leaf-tested
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_intc.do   .. after compile.do. ZERO SETUP: no memory
--   images, no G_ISA_REPAIR setting, nothing to stage.
--
-- WHAT THIS PROVES
--   INTERRUPT_CTRL.vhd alone: raw request latches behind the MASKED view
--   (irq AND eint = IFGx -- the p13 structure, the falsified-A6
--   correction), the A22 comeback and the test1 init pattern that hides
--   it, W0C software writes, the p14 priority encoder and INTR both
--   reading the VIEW, the INTA handshake with frozen TYPE capture, the
--   a-vs-d clearing split (BT auto-clears at service, KEYs only by
--   software), and KEY request events on the RELEASE edge only (DOC/03
--   section C). The CPU-side protocol (GIE in gp[0], the two entry
--   cycles, tp, reti) is Phase 9B, and the bus wiring (CS_INTC, lanes,
--   BidirPin readers) is Phase 9C -- neither is touched here; sources and
--   handshake are driven directly.
--
-- WHY THE FIRST RUN SHOULD PASS
--   tools/model_interrupt_ctrl.py executes the RTL's per-edge semantics
--   through these same phases: 0 failures, and twelve faithful mutations
--   (set gated by IE, raw readback, write-1-sets, inverted priority, INTR
--   ignoring GIE, auto-clear hitting the KEYs, no BT auto-clear, the
--   press edge instead of the release, live TYPE instead of frozen, a
--   level-set key latch, INTR summing raw latches, TYPE encoding raw
--   latches) are ALL caught, each by the phase built to catch it.
--
-- EXPECTED VALUES -- every constant below was produced by the model, not
-- by hand. KEY presses drive the PRESSED level; the flag must appear only
-- at the RELEASE.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_interrupt_ctrl IS
END tb_interrupt_ctrl;


ARCHITECTURE test OF tb_interrupt_ctrl IS

	constant CLK_PERIOD	: time := 100 ns;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	-- bus write side
	SIGNAL cs		: STD_LOGIC := '0';
	SIGNAL wr		: STD_LOGIC := '0';
	SIGNAL lane0	: STD_LOGIC := '0';
	SIGNAL lane1	: STD_LOGIC := '0';
	SIGNAL wdata	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

	-- sources
	SIGNAL bt_set	: STD_LOGIC := '0';
	SIGNAL keys	 	: STD_LOGIC_VECTOR(3 DOWNTO 1) := "000";	-- pressed levels

	-- handshake
	SIGNAL gie		: STD_LOGIC := '0';
	SIGNAL inta		: STD_LOGIC := '1';
	SIGNAL intr		: STD_LOGIC;
	SIGNAL push		: STD_LOGIC;
	SIGNAL capt		: STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- read-back
	SIGNAL ie_rd	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ifg_rd	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL type_rd	: STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
	--=======================================================================
	DUT : interrupt_ctrl
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		cs_i			=> cs,
		MemWrite_i		=> wr,
		lane0_i			=> lane0,
		lane1_i			=> lane1,
		data_i			=> wdata,
		bt_ifg_set_i	=> bt_set,
		key_pressed_i	=> keys,
		-- rxerr_ev_i / rx_ev_i / tx_ev_i left at their '0' defaults: UART
		-- sources arrive in Phase 12
		gie_i			=> gie,
		inta_i			=> inta,
		intr_o			=> intr,
		type_push_o		=> push,
		type_capt_o		=> capt,
		ie_o			=> ie_rd,
		ifg_o			=> ifg_rd,
		type_o			=> type_rd
	);

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	--=======================================================================
	stim : process
		variable p, f : natural := 0;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		-- one-edge bus write, falling-edge aligned (tb_basic_timer's idiom)
		procedure bus_write(constant ln : IN NATURAL;
							constant v  : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin
			wait until falling_edge(clk);
			cs <= '1';
			if ln = 0 then lane0 <= '1'; else lane1 <= '1'; end if;
			wdata <= x"000000" & v;
			wr    <= '1';
			wait until falling_edge(clk);		-- one rising edge in between
			cs <= '0'; lane0 <= '0'; lane1 <= '0'; wr <= '0';
		end procedure bus_write;

		procedure wr_ie (constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin bus_write(0, v); end procedure;

		procedure wr_ifg(constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin bus_write(1, v); end procedure;

		procedure settle(constant n : IN NATURAL) is
		begin
			for i in 1 to n loop wait until falling_edge(clk); end loop;
		end procedure settle;

		-- a full press-and-release on the pressed-level inputs; the request
		-- must fire at the RELEASE (DOC/03 section C)
		procedure press_release(constant k1, k2, k3 : IN STD_LOGIC) is
		begin
			wait until falling_edge(clk);
			keys <= k3 & k2 & k1;
			settle(4);
			keys <= "000";
			settle(5);							-- 2 sync flops + hist + latch
		end procedure press_release;

		-- one-cycle event pulse on bt_set, falling-edge aligned
		procedure bt_pulse is
		begin
			wait until falling_edge(clk);
			bt_set <= '1';
			wait until falling_edge(clk);
			bt_set <= '0';
		end procedure bt_pulse;

		-- the accept cycle: INTA low across exactly one rising edge (REQ p15).
		-- with_bt fires the BT event in the SAME cycle -- the P7h freeze case.
		procedure inta_pulse(constant with_bt : IN BOOLEAN := FALSE) is
		begin
			wait until falling_edge(clk);
			inta <= '0';
			if with_bt then bt_set <= '1'; end if;
			wait until falling_edge(clk);
			inta <= '1'; bt_set <= '0';
			-- returns MID protocol-Cycle-1: push/capt are valid right now
		end procedure inta_pulse;

	begin
		-- ---- P0 reset ------------------------------------------------------
		rst <= '1';
		settle(3);
		rst <= '0';
		settle(2);
		chk(ie_rd = x"00" and ifg_rd = x"00" and type_rd = x"00" and intr = '0',
			"P0 not clear after reset");

		-- ---- P1 IE write / read-back, bits 7:6 dropped -----------------------
		wr_ie(x"FF"); settle(1);
		chk(ie_rd = x"3F", "P1a IE after writing 0xFF: got 0x" &
			to_hstring(ie_rd) & ", expected 0x3F (bits 7:6 must drop)");
		wr_ie(x"38"); settle(1);
		chk(ie_rd = x"38", "P1b IE=0x38 read-back");

		-- ---- P2 raw latch, masked view -- the falsified-A6 correction --------
		wr_ie(x"00");
		press_release('1', '0', '0');			-- full press+release with IE=0
		chk(ifg_rd = x"00", "P2a IFG=0x" & to_hstring(ifg_rd) &
			": reads the RAW latch; Hanan's answer says the READ is masked");
		wr_ie(x"08"); settle(1);				-- enable over the latched request
		chk(ifg_rd = x"08", "P2b IFG=0x" & to_hstring(ifg_rd) &
			" != 0x08: the raw latch must REMEMBER the masked request "
			& "(A22 comeback; the p13 flop has no IE gate)");
		chk(intr = '0', "P2c INTR high with GIE=0");
		gie <= '1'; settle(1);
		chk(intr = '1', "P2d INTR low with KEY1IFG pending and GIE=1");
		gie <= '0';
		wr_ifg(x"00"); settle(1);

		-- ---- P3 the benchmark init pattern kills masked requests -------------
		wr_ie(x"00");
		press_release('1', '0', '0');			-- request latches invisibly
		wr_ifg(x"00");							-- test1's init: IFG=0 while IE=0
		wr_ie(x"08");							-- ...and only then enable
		settle(4);
		chk(ifg_rd = x"00", "P3 IFG=0x" & to_hstring(ifg_rd) &
			": the IFG=0 store while masked did not clear the RAW latch; "
			& "test1's init order relies on exactly that");

		-- ---- P4 software W0C -------------------------------------------------
		wr_ie(x"18");							-- KEY1IE + KEY2IE
		press_release('1', '1', '0');
		chk(ifg_rd = x"18", "P4a IFG=0x" & to_hstring(ifg_rd) &
			" != 0x18 after both key releases");
		wr_ifg(x"F7"); settle(1);				-- KEY1IFG_MASK's low byte
		chk(ifg_rd = x"10", "P4b IFG=0x" & to_hstring(ifg_rd) &
			" != 0x10 after the benchmark ISR clear idiom (W0C)");
		wr_ifg(x"FF"); settle(1);
		chk(ifg_rd = x"10", "P4c IFG=0x" & to_hstring(ifg_rd) &
			": a write-1 SET a flag; A24 says software cannot set");
		wr_ifg(x"00"); settle(1);

		-- ---- P5 priority / TYPE, from the VIEW --------------------------------
		wr_ie(x"18");							-- keys 1+2 enabled; BT NOT enabled
		bt_pulse;								-- BT latches RAW, stays masked
		press_release('0', '1', '0');			-- KEY2 visible
		chk(ifg_rd = x"10", "P5a IFG=0x" & to_hstring(ifg_rd) &
			" != 0x10 (KEY2 visible, BT masked)");
		chk(type_rd = x"18", "P5a TYPE=0x" & to_hstring(type_rd) &
			" != 0x18: a MASKED BT request must not win priority "
			& "(TYPE reads the view, not the raw latch)");
		wr_ie(x"1C"); settle(1);				-- enable BTIE: BT reappears...
		chk(ifg_rd = x"14", "P5b IFG=0x" & to_hstring(ifg_rd) &
			" != 0x14 (BT + KEY2)");
		chk(type_rd = x"10", "P5b TYPE=0x" & to_hstring(type_rd) &
			" != 0x10; BT outranks KEY2 (p14 priority column)");
		wr_ifg(x"FB"); settle(1);				-- clear BT only
		chk(type_rd = x"18", "P5c TYPE=0x" & to_hstring(type_rd) &
			" != 0x18 after clearing BT");
		wr_ie(x"3C");							-- open KEY3IE before the 3-key case
		press_release('1', '0', '1');			-- KEY1 + KEY3 join
		chk(ifg_rd = x"38", "P5d IFG=0x" & to_hstring(ifg_rd) &
			" != 0x38 (all three keys)");
		chk(type_rd = x"14", "P5d TYPE=0x" & to_hstring(type_rd) &
			" != 0x14; KEY1 outranks KEY2 and KEY3");
		wr_ifg(x"00"); settle(1);

		-- ---- P6 INTR gating: GIE, and the mask ---------------------------------
		chk(ifg_rd = x"00" and intr = '0', "P6a not idle before the gating check");
		wr_ie(x"00");
		bt_pulse; settle(1);					-- raw-pending, fully masked
		gie <= '1'; settle(1);
		chk(intr = '0', "P6b INTR high on a MASKED request; the p13 OR tree "
			& "sums the IFGx products, not the raw latches");
		gie <= '0';
		wr_ie(x"04"); settle(1);				-- unmask: BT reappears
		chk(intr = '0', "P6c INTR high with GIE=0");
		gie <= '1'; settle(1);
		chk(intr = '1', "P6d INTR low with BTIFG visible and GIE=1");

		-- ---- P7 the INTA handshake ----------------------------------------------
		wr_ie(x"0C");							-- BT (still pending) + KEY1
		press_release('1', '0', '0');
		chk(ifg_rd = x"0C", "P7a IFG=0x" & to_hstring(ifg_rd) &
			" != 0x0C (BT + KEY1) before the handshake");
		inta_pulse;								-- accept; now mid Cycle 1
		chk(push = '1', "P7b no TYPE push in the cycle after INTA");
		chk(capt = x"10", "P7b pushed TYPE=0x" & to_hstring(capt) &
			" != 0x10 (BT was the highest-priority pending)");
		chk(ifg_rd = x"08", "P7c IFG=0x" & to_hstring(ifg_rd) &
			" != 0x08; BT must auto-clear at service (rule a) and KEY1 survive");
		settle(1);
		chk(push = '0', "P7d the push did not self-clear after one cycle");
		inta_pulse;								-- service KEY1 now
		chk(capt = x"14", "P7e pushed TYPE=0x" & to_hstring(capt) &
			" != 0x14 (KEY1)");
		chk(ifg_rd = x"08", "P7f KEY1IFG auto-cleared at service; rule d says "
			& "the KEYs are cleared manually by software");
		wr_ifg(x"F7"); settle(1);				-- the ISR's manual clear
		chk(ifg_rd = x"00" and intr = '0',
			"P7g not idle after the manual KEY1 clear (GIE is still 1)");
		gie <= '0';

		-- ---- P7h capture is FROZEN at the accept edge -----------------------------
		wr_ie(x"1C");
		press_release('0', '1', '0');
		chk(ifg_rd = x"10", "P7h setup: KEY2 not pending alone");
		inta_pulse(with_bt => TRUE);			-- BT fires IN the accept cycle
		chk(capt = x"18", "P7h pushed TYPE=0x" & to_hstring(capt) &
			" != 0x18: TYPE must freeze at the accept edge, not track the "
			& "BT flag that latched one edge later");
		chk(ifg_rd = x"14", "P7h IFG=0x" & to_hstring(ifg_rd) &
			" != 0x14: KEY2 must survive (rule d) and the simultaneous BT "
			& "event must not be lost");
		wr_ifg(x"00"); settle(1);

		-- ---- P8 the event is the RELEASE, and it is an edge -------------------------
		wr_ie(x"08");
		wait until falling_edge(clk);
		keys <= "001";							-- press KEY1 and HOLD
		settle(20);
		chk(ifg_rd = x"00", "P8a IFG=0x" & to_hstring(ifg_rd) &
			": the flag set on the PRESS. DOC/03 section C: the request "
			& "event is the RELEASE");
		keys <= "000"; settle(6);				-- release
		chk(ifg_rd = x"08", "P8b the release did not set the flag");
		wr_ifg(x"00");
		settle(10);
		chk(ifg_rd = x"00", "P8c IFG=0x" & to_hstring(ifg_rd) &
			": re-set with no new event; the latch must be edge-set");
		press_release('1', '0', '0');			-- a full second press+release
		chk(ifg_rd = x"08", "P8d a second press+release did not set");
		wr_ifg(x"00"); settle(1);

		-- ---- P9 the sync source: masked = invisible but remembered ------------------
		wr_ie(x"00");
		bt_pulse; settle(1);
		chk(ifg_rd = x"00", "P9a BTIFG visible with BTIE=0; the read must be "
			& "the masked view");
		wr_ie(x"04"); settle(1);
		chk(ifg_rd = x"04", "P9b the masked BT request was not remembered (A22)");

		-- ---- verdict -------------------------------------------------------------
		report "" severity note;
		report "========= INTERRUPT CTRL (Phase 9A) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - raw latches behind the masked view, A22 " &
				"comeback, the test1 init pattern, W0C, view-based priority " &
				"and INTR, the frozen TYPE capture, the a-vs-d clearing " &
				"split, and KEY events on the RELEASE only." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "=====================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process stim;

END test;
