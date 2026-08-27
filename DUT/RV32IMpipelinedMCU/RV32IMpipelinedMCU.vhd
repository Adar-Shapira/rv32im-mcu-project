--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — RV32IM-based MCU, five-stage pipeline (bonus 10%)
--
-- RV32IMpipelinedMCU — board-facing structural top (Phase 11 slice 1).
--
-- MCU shell transcribed from DUT/RV32IMscMCU/RV32IMscMCU.vhd (clock tree,
-- address decoder, bidirectional data bus, GPIO, Basic Timer, interrupt
-- controller). The CPU is RV32IM_PIPE_CORE instead of RV32IM_CORE.
-- UART (Phase 12) is not attached.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;


ENTITY RV32IMpipelinedMCU IS
	generic(
		RST_ACTIVE_LOW		: boolean	:= TRUE;
		GEN_DEBUG_PORTS		: boolean	:= TRUE;
		GEN_RESET_ON_LOCK	: boolean	:= TRUE;
		GEN_GPO_READBACK	: boolean	:= TRUE;
		GEN_INPUT_SYNC		: boolean	:= FALSE;
		KEY_ACTIVE_LOW		: boolean	:= TRUE;
		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16;
		STCNT_WIDTH			: integer	:= 16;
		FHCNT_WIDTH			: integer	:= 16;
		BP_ADDR_WIDTH		: integer	:= 8
	);
	PORT(
		clk_i				:IN		STD_LOGIC;
		rst_i				:IN		STD_LOGIC;
		BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

		SW_i				:IN		STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
		KEY_i				:IN		STD_LOGIC_VECTOR(3 DOWNTO 1) := (OTHERS => '1');
		GPIO				:INOUT	STD_LOGIC_VECTOR(35 DOWNTO 0) := (OTHERS => 'Z');
		CAPIN1_i			:IN		STD_LOGIC := '0';
		CAPIN2_i			:IN		STD_LOGIC := '0';
		PWM_o				:OUT	STD_LOGIC;

		LEDR_o				:OUT	STD_LOGIC_VECTOR(9 DOWNTO 0);
		HEX0_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);

		-- USART -- Phase 12B. Pin names and locations from the course's own
		-- Terasic table, Auxiliary/Lab4/Auxiliary/DE2_115_pin_assignments.csv:
		-- UART_RXD = PIN_G12 (input), UART_TXD = PIN_G9 (output), 3.3-V LVTTL.
		-- RXD defaults to the idle '1' so every pre-12B testbench elaborates.
		UART_RXD_i			:IN		STD_LOGIC := '1';
		UART_TXD_o			:OUT	STD_LOGIC;

		IFpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		IFinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		IDpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		IDinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		EXpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		EXinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		MEMpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		MEMinstruction_o	:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		WBpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		WBinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		STRIGGER_o			:OUT	STD_LOGIC;
		CLKCNT_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
		STCNT_o				:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
		FHCNT_o				:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);

		MemWrite_ctrl_o		:OUT	STD_LOGIC;
		alu_res_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		dtcm_cs_o			:OUT	STD_LOGIC;
		unmapped_o			:OUT	STD_LOGIC;
		dtcm_wren_o			:OUT	STD_LOGIC
	);
END RV32IMpipelinedMCU;
--============================================================================
ARCHITECTURE structure OF RV32IMpipelinedMCU IS

	SIGNAL rst_w				: STD_LOGIC;
	SIGNAL sys_rst_w			: STD_LOGIC;
	SIGNAL bpaddr_w				: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);

	SIGNAL IFpc_w, IDpc_w, EXpc_w, MEMpc_w, WBpc_w
								: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL IFinst_w, IDinst_w, EXinst_w, MEMinst_w, WBinst_w
								: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL STRIGGER_w			: STD_LOGIC;
	SIGNAL CLKCNT_w				: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL STCNT_w				: STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
	SIGNAL FHCNT_w				: STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);

	SIGNAL dbus_addr_w			: STD_LOGIC_VECTOR(DATA_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dbus_wdata_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dbus_MemRead_w		: STD_LOGIC;
	SIGNAL dbus_MemWrite_w		: STD_LOGIC;
	SIGNAL dbus_rdata_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_cs_w			: STD_LOGIC;
	SIGNAL unmapped_w			: STD_LOGIC;
	SIGNAL dtcm_wren_w			: STD_LOGIC;
	SIGNAL sfr_cs_w				: STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);

	SIGNAL mclk_w				: STD_LOGIC;
	SIGNAL smclk_w				: STD_LOGIC;
	SIGNAL accelclk_w			: STD_LOGIC;
	SIGNAL pll_locked_w			: STD_LOGIC;
	SIGNAL pclk_w				: STD_LOGIC;

	SIGNAL lane0_w				: STD_LOGIC;
	SIGNAL lane1_w				: STD_LOGIC;
	SIGNAL lane2_w				: STD_LOGIC;
	SIGNAL gpo_cs_w				: STD_LOGIC;
	SIGNAL timer_cs_w			: STD_LOGIC;
	SIGNAL intc_cs_w			: STD_LOGIC;
	SIGNAL uart_cs_w			: STD_LOGIC;	-- Phase 12B
	SIGNAL sfr_rd_impl_w		: STD_LOGIC;

	-- Phase 12B -- the USART's read-backs, its three interrupt sources and the
	-- two software-side clears of rules b/c.
	SIGNAL uctl_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL rxbuf_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL txbuf_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL uart_rx_ev_w			: STD_LOGIC;
	SIGNAL uart_rxerr_ev_w		: STD_LOGIC;
	SIGNAL uart_tx_ev_w			: STD_LOGIC;
	SIGNAL uart_rx_clr_w		: STD_LOGIC;
	SIGNAL uart_tx_clr_w		: STD_LOGIC;

	SIGNAL btctl1_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL btctl2_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL btcmpr0_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL btcmpr1_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL btcapr_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL bt_ifg_set_w			: STD_LOGIC;

	SIGNAL intc_ie_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL intc_ifg_rd_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL intc_type_rd_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL type_push_w			: STD_LOGIC;
	SIGNAL type_capt_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL intr_w				: STD_LOGIC;
	SIGNAL inta_w				: STD_LOGIC;
	SIGNAL gie_w				: STD_LOGIC;

	type hex_byte_array_t is array (0 TO 5) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	type hex_seg_array_t  is array (0 TO 5) of STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL ledr_q				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL hex_q				: hex_byte_array_t;
	SIGNAL hex_seg_w			: hex_seg_array_t;
	SIGNAL pwm_w				: STD_LOGIC;
	SIGNAL capin1_w				: STD_LOGIC;
	SIGNAL capin2_w				: STD_LOGIC;

	-- Indices match DUT/RV32IMscMCU/RV32IMscMCU.vhd:383-414.
	CONSTANT RD_SW		: integer := 0;
	CONSTANT RD_LEDR	: integer := 1;
	CONSTANT RD_HEX0	: integer := 2;
	CONSTANT RD_HEX1	: integer := 3;
	CONSTANT RD_HEX2	: integer := 4;
	CONSTANT RD_HEX3	: integer := 5;
	CONSTANT RD_HEX4	: integer := 6;
	CONSTANT RD_HEX5	: integer := 7;
	CONSTANT RD_PB		: integer := 8;
	CONSTANT RD_BTCTL1	: integer := 9;
	CONSTANT RD_BTCTL2	: integer := 10;
	CONSTANT RD_IE			: integer := 11;
	CONSTANT RD_IFG			: integer := 12;
	CONSTANT RD_TYPE		: integer := 13;
	CONSTANT RD_TYPEPUSH	: integer := 14;
	-- Phase 12B: the USART's three byte registers, word 6, lanes 0/1/2
	CONSTANT RD_UCTL	: integer := 15;	-- 0x2018  byte, lane0
	CONSTANT RD_RXBUF	: integer := 16;	-- 0x2019  byte, lane1 (read has a side effect)
	CONSTANT RD_TXBUF	: integer := 17;	-- 0x201A  byte, lane2
	CONSTANT NRD_BYTE	: integer := 18;
	CONSTANT RD_BTCMPR0	: integer := 18;
	CONSTANT RD_BTCMPR1	: integer := 19;
	CONSTANT RD_BTCAPR	: integer := 20;
	CONSTANT NRD		: integer := 21;

	type rd_byte_array_t is array (0 TO NRD-1) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	type rd_word_array_t is array (0 TO NRD-1) of STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	CONSTANT RD_NONE	: STD_LOGIC_VECTOR(NRD-1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL rd_en_w				: STD_LOGIC_VECTOR(NRD-1 DOWNTO 0);
	SIGNAL rd_byte_w			: rd_byte_array_t;
	SIGNAL rd_word_w			: rd_word_array_t;
	SIGNAL term_en_w			: STD_LOGIC;
	SIGNAL rdbk_w				: STD_LOGIC;
	SIGNAL data_bus_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	CONSTANT ZEROS_BUS			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL alu_obs_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL sw_sync_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL key_pressed_w		: STD_LOGIC_VECTOR(3 DOWNTO 1);
	SIGNAL portpb_w				: STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
	RSTCOND:
	if (RST_ACTIVE_LOW) generate
		rst_w	<= not rst_i;
	else generate
		rst_w	<= rst_i;
	end generate;

	CLKTREE : clock_tree
	generic map(
		MODELSIM			=> MODELSIM
	)
	PORT MAP(
		clk_i		=> clk_i,
		rst_i		=> rst_w,
		mclk_o		=> mclk_w,
		smclk_o		=> smclk_w,
		accelclk_o	=> accelclk_w,
		locked_o	=> pll_locked_w
	);

	RSTLOCK:
	if (GEN_RESET_ON_LOCK) generate
		sys_rst_w <= rst_w OR (NOT pll_locked_w);
	else generate
		sys_rst_w <= rst_w;
	end generate RSTLOCK;

	BPIN:
	if (GEN_DEBUG_PORTS) generate
		bpaddr_w <= BPADDR_i;
	else generate
		bpaddr_w <= (others => '0');
	end generate BPIN;

	CORE : RV32IM_PIPE_CORE
	generic map(
		WORD_GRANULARITY	=> WORD_GRANULARITY,
		MODELSIM			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH,
		STCNT_WIDTH			=> STCNT_WIDTH,
		FHCNT_WIDTH			=> FHCNT_WIDTH,
		BP_ADDR_WIDTH		=> BP_ADDR_WIDTH
	)
	PORT MAP(
		rst_i				=> sys_rst_w,
		clk_i				=> mclk_w,
		divclk_i			=> accelclk_w,
		intr_i				=> intr_w,
		inta_o				=> inta_w,
		gie_o				=> gie_w,
		dbus_addr_o			=> dbus_addr_w,
		dbus_wdata_o		=> dbus_wdata_w,
		dbus_MemRead_o		=> dbus_MemRead_w,
		dbus_MemWrite_o		=> dbus_MemWrite_w,
		dtcm_cs_i			=> dtcm_cs_w,
		dbus_rdata_i		=> dbus_rdata_w,
		dtcm_wren_o			=> dtcm_wren_w,
		BPADDR_i			=> bpaddr_w,
		CLKCNT_o			=> CLKCNT_w,
		IFpc_o				=> IFpc_w,
		IFinstruction_o		=> IFinst_w,
		IDpc_o				=> IDpc_w,
		IDinstruction_o		=> IDinst_w,
		EXpc_o				=> EXpc_w,
		EXinstruction_o		=> EXinst_w,
		MEMpc_o				=> MEMpc_w,
		MEMinstruction_o	=> MEMinst_w,
		WBpc_o				=> WBpc_w,
		WBinstruction_o		=> WBinst_w,
		STRIGGER_o			=> STRIGGER_w,
		FHCNT_o				=> FHCNT_w,
		STCNT_o				=> STCNT_w
	);

	DEC : addr_decoder
	PORT MAP (
		addr_i				=> dbus_addr_w,
		dtcm_cs_o			=> dtcm_cs_w,
		sfr_cs_o			=> sfr_cs_w,
		unmapped_o			=> unmapped_w
	);

	BP_CPU : BidirPin
	generic map( width => DATA_BUS_WIDTH )
	PORT MAP (
		Dout	=> dbus_wdata_w,
		en		=> dbus_MemWrite_w,
		Din		=> open,
		IOpin	=> data_bus_w
	);

	dbus_rdata_w <= data_bus_w;

	RDBK:
	if (GEN_GPO_READBACK) generate
		rdbk_w <= '1';
	else generate
		rdbk_w <= '0';
	end generate;

	SWSYNC:
	if (GEN_INPUT_SYNC) generate
		SW_SYNC : sync
		generic map(
			DATA_WIDTH	=> 8,
			STAGES		=> 2,
			GEN_SRC_REG	=> FALSE
		)
		PORT MAP (
			src_clk_i	=> pclk_w,
			dst_clk_i	=> pclk_w,
			rst_i		=> sys_rst_w,
			d_i			=> SW_i(7 DOWNTO 0),
			q_o			=> sw_sync_w
		);
	else generate
		sw_sync_w <= SW_i(7 DOWNTO 0);
	end generate;

	KEYCOND:
	if (KEY_ACTIVE_LOW) generate
		key_pressed_w <= NOT KEY_i;
	else generate
		key_pressed_w <= KEY_i;
	end generate;

	portpb_w(0) <= key_pressed_w(1);
	portpb_w(1) <= key_pressed_w(2);
	portpb_w(2) <= key_pressed_w(3);
	portpb_w(7 DOWNTO 3) <= (OTHERS => '0');

	rd_en_w(RD_SW)   <= sfr_cs_w(CS_SW)    AND dbus_MemRead_w AND lane0_w;
	rd_en_w(RD_LEDR) <= sfr_cs_w(CS_LEDR)  AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX0) <= sfr_cs_w(CS_HEX01) AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX1) <= sfr_cs_w(CS_HEX01) AND dbus_MemRead_w AND lane1_w AND rdbk_w;
	rd_en_w(RD_HEX2) <= sfr_cs_w(CS_HEX23) AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX3) <= sfr_cs_w(CS_HEX23) AND dbus_MemRead_w AND lane1_w AND rdbk_w;
	rd_en_w(RD_HEX4) <= sfr_cs_w(CS_HEX45) AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX5) <= sfr_cs_w(CS_HEX45) AND dbus_MemRead_w AND lane1_w AND rdbk_w;
	rd_en_w(RD_PB)   <= sfr_cs_w(CS_PB)    AND dbus_MemRead_w AND lane0_w;
	rd_en_w(RD_BTCTL1)  <= sfr_cs_w(CS_BTCTL)   AND dbus_MemRead_w AND lane0_w;
	rd_en_w(RD_BTCTL2)  <= sfr_cs_w(CS_BTCTL)   AND dbus_MemRead_w AND lane1_w;
	rd_en_w(RD_BTCMPR0) <= sfr_cs_w(CS_BTCMPR0) AND dbus_MemRead_w;
	rd_en_w(RD_BTCMPR1) <= sfr_cs_w(CS_BTCMPR1) AND dbus_MemRead_w;
	rd_en_w(RD_BTCAPR)  <= sfr_cs_w(CS_BTCAPR)  AND dbus_MemRead_w;
	rd_en_w(RD_IE)       <= sfr_cs_w(CS_INTC) AND dbus_MemRead_w AND lane0_w;
	rd_en_w(RD_IFG)      <= sfr_cs_w(CS_INTC) AND dbus_MemRead_w AND lane1_w;
	rd_en_w(RD_TYPE)     <= sfr_cs_w(CS_INTC) AND dbus_MemRead_w AND lane2_w;
	rd_en_w(RD_TYPEPUSH) <= type_push_w;
	rd_en_w(RD_UCTL)  <= sfr_cs_w(CS_UART) AND dbus_MemRead_w AND lane0_w;
	rd_en_w(RD_RXBUF) <= sfr_cs_w(CS_UART) AND dbus_MemRead_w AND lane1_w;
	rd_en_w(RD_TXBUF) <= sfr_cs_w(CS_UART) AND dbus_MemRead_w AND lane2_w;

	rd_byte_w(RD_SW)   <= sw_sync_w;
	rd_byte_w(RD_LEDR) <= ledr_q;
	rd_byte_w(RD_HEX0) <= hex_q(0);
	rd_byte_w(RD_HEX1) <= hex_q(1);
	rd_byte_w(RD_HEX2) <= hex_q(2);
	rd_byte_w(RD_HEX3) <= hex_q(3);
	rd_byte_w(RD_HEX4) <= hex_q(4);
	rd_byte_w(RD_HEX5) <= hex_q(5);
	rd_byte_w(RD_PB)   <= portpb_w;
	rd_byte_w(RD_BTCTL1) <= btctl1_rd_w;
	rd_byte_w(RD_BTCTL2) <= btctl2_rd_w;
	rd_byte_w(RD_IE)       <= intc_ie_rd_w;
	rd_byte_w(RD_IFG)      <= intc_ifg_rd_w;
	rd_byte_w(RD_TYPE)     <= intc_type_rd_w;
	rd_byte_w(RD_TYPEPUSH) <= type_capt_w;
	rd_byte_w(RD_UCTL)  <= uctl_rd_w;
	rd_byte_w(RD_RXBUF) <= rxbuf_rd_w;
	rd_byte_w(RD_TXBUF) <= txbuf_rd_w;

	WEXT:
	for i in 0 to NRD_BYTE-1 generate
		rd_word_w(i) <= ZEROS_BUS(DATA_BUS_WIDTH-1 DOWNTO 8) & rd_byte_w(i);
	end generate;

	rd_word_w(RD_BTCMPR0) <= btcmpr0_rd_w;
	rd_word_w(RD_BTCMPR1) <= btcmpr1_rd_w;
	rd_word_w(RD_BTCAPR)  <= btcapr_rd_w;

	term_en_w <= '1' WHEN (rd_en_w = RD_NONE and dbus_MemWrite_w = '0') ELSE '0';

	RDGEN:
	for i in 0 to NRD-1 generate
		BP : BidirPin
		generic map( width => DATA_BUS_WIDTH )
		PORT MAP (
			Dout	=> rd_word_w(i),
			en		=> rd_en_w(i),
			Din		=> open,
			IOpin	=> data_bus_w
		);
	end generate;

	BP_TERM : BidirPin
	generic map( width => DATA_BUS_WIDTH )
	PORT MAP (
		Dout	=> ZEROS_BUS,
		en		=> term_en_w,
		Din		=> open,
		IOpin	=> data_bus_w
	);

	gpo_cs_w <=	sfr_cs_w(CS_LEDR)  OR sfr_cs_w(CS_HEX01) OR
				sfr_cs_w(CS_HEX23) OR sfr_cs_w(CS_HEX45);

	timer_cs_w <= sfr_cs_w(CS_BTCTL)   OR sfr_cs_w(CS_BTCMPR0) OR
				  sfr_cs_w(CS_BTCMPR1) OR sfr_cs_w(CS_BTCAPR);

	intc_cs_w <= sfr_cs_w(CS_INTC);
	uart_cs_w <= sfr_cs_w(CS_UART);		-- Phase 12B: word 6, the last one

	sfr_rd_impl_w <= sfr_cs_w(CS_SW) OR sfr_cs_w(CS_PB) OR (gpo_cs_w AND rdbk_w)
					 OR timer_cs_w OR intc_cs_w OR uart_cs_w;

	SFRSTUB:
	if (MODELSIM = 1) generate
		sfr_stub_notice : process(clk_i)
			variable told_rd_v : boolean := FALSE;
			variable told_wr_v : boolean := FALSE;
		begin
			if rising_edge(clk_i) then
				if dbus_MemRead_w = '1' and dtcm_cs_w = '0' and sfr_rd_impl_w = '0'
				   and not told_rd_v then
					told_rd_v := TRUE;
					report "RV32IMpipelinedMCU: SFR READ of a word with no reader. " &
						   "Since Phase 12B every mapped word answers, so this needs " &
						   "GEN_GPO_READBACK => FALSE. Once per run."
						severity note;
				end if;
				if dbus_MemWrite_w = '1' and dtcm_cs_w = '0' and gpo_cs_w = '0'
				   and timer_cs_w = '0' and intc_cs_w = '0' and uart_cs_w = '0'
				   and not told_wr_v then
					told_wr_v := TRUE;
					report "RV32IMpipelinedMCU: SFR WRITE discarded. Since Phase 12B " &
						   "the only read-only words left are PORT_SW and PORT_PB. " &
						   "Once per run."
						severity note;
				end if;
			end if;
		end process sfr_stub_notice;
	end generate;

	pclk_w <= smclk_w;

	lane0_w <= (NOT dbus_addr_w(1)) AND (NOT dbus_addr_w(0));
	lane1_w <= (NOT dbus_addr_w(1)) AND      dbus_addr_w(0);
	lane2_w <=      dbus_addr_w(1)  AND (NOT dbus_addr_w(0));

	P_LEDR : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i		=> pclk_w,
		rst_i		=> sys_rst_w,
		cs_i		=> sfr_cs_w(CS_LEDR),
		MemWrite_i	=> dbus_MemWrite_w,
		lane_en_i	=> lane0_w,
		data_i		=> data_bus_w(7 DOWNTO 0),
		q_o			=> ledr_q
	);
	LEDR_o(7 DOWNTO 0) <= ledr_q;
	LEDR_o(9 DOWNTO 8) <= "00";

	P_HEX0 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX01), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(0)
	);
	P_HEX1 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX01), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(1)
	);
	P_HEX2 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX23), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(2)
	);
	P_HEX3 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX23), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(3)
	);
	P_HEX4 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX45), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(4)
	);
	P_HEX5 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX45), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(5)
	);

	SEGGEN:
	for i in 0 to 5 generate
		SEG : hex_decoder
		PORT MAP (
			bin => hex_q(i)(3 DOWNTO 0),
			seg => hex_seg_w(i)
		);
	end generate;

	HEX0_o <= hex_seg_w(0);
	HEX1_o <= hex_seg_w(1);
	HEX2_o <= hex_seg_w(2);
	HEX3_o <= hex_seg_w(3);
	HEX4_o <= hex_seg_w(4);
	HEX5_o <= hex_seg_w(5);

	TIMER : basic_timer
	generic map( DATA_WIDTH => DATA_BUS_WIDTH )
	PORT MAP (
		clk_i		=> pclk_w,
		rst_i		=> sys_rst_w,
		ctl_cs_i	=> sfr_cs_w(CS_BTCTL),
		cmpr0_cs_i	=> sfr_cs_w(CS_BTCMPR0),
		cmpr1_cs_i	=> sfr_cs_w(CS_BTCMPR1),
		MemWrite_i	=> dbus_MemWrite_w,
		lane0_i		=> lane0_w,
		lane1_i		=> lane1_w,
		data_i		=> data_bus_w,
		capin1_i	=> capin1_w,
		capin2_i	=> capin2_w,
		pwm_o		=> pwm_w,
		btifg_set_o	=> bt_ifg_set_w,
		btctl1_o	=> btctl1_rd_w,
		btctl2_o	=> btctl2_rd_w,
		btcmpr0_o	=> btcmpr0_rd_w,
		btcmpr1_o	=> btcmpr1_rd_w,
		btcapr_o	=> btcapr_rd_w,
		btcnt_o		=> open
	);

	GPIO <= (9 => pwm_w, OTHERS => 'Z');
	PWM_o <= pwm_w;
	FPGA_CAPIN:
	if (MODELSIM = 0) generate
		capin1_w <= GPIO(8);
		capin2_w <= GPIO(10);
	end generate FPGA_CAPIN;
	SIM_CAPIN:
	if (MODELSIM /= 0) generate
		capin1_w <= CAPIN1_i;
		capin2_w <= CAPIN2_i;
	end generate SIM_CAPIN;

	--=======================================
	-- USART -- Phase 12B, identical wiring to the single-cycle tree
	--=======================================
	-- CLK_HZ is passed explicitly: UART_CORE turns it into the baud divider at
	-- ELABORATION and asserts the resulting error, so a wrong value here is a
	-- compile error rather than a dead serial link on the bench.
	UART : uart_periph
	generic map(
		DATA_WIDTH	=> DATA_BUS_WIDTH,
		CLK_HZ		=> 20000000				-- SMCLK, F8/F11
	)
	PORT MAP (
		clk_i		=> pclk_w,
		rst_i		=> sys_rst_w,
		cs_i		=> sfr_cs_w(CS_UART),
		MemWrite_i	=> dbus_MemWrite_w,
		MemRead_i	=> dbus_MemRead_w,		-- RXBUF's read side effect (REQ p12)
		lane0_i		=> lane0_w,				-- 0x2018 UCTL
		lane1_i		=> lane1_w,				-- 0x2019 RXBUF
		lane2_i		=> lane2_w,				-- 0x201A TXBUF
		data_i		=> data_bus_w,
		rxd_i		=> UART_RXD_i,			-- PIN_G12 (Terasic CSV)
		txd_o		=> UART_TXD_o,			-- PIN_G9
		rx_ev_o		=> uart_rx_ev_w,
		rxerr_ev_o	=> uart_rxerr_ev_w,
		tx_ev_o		=> uart_tx_ev_w,
		rx_clr_o	=> uart_rx_clr_w,
		tx_clr_o	=> uart_tx_clr_w,
		uctl_o		=> uctl_rd_w,
		rxbuf_o		=> rxbuf_rd_w,
		txbuf_o		=> txbuf_rd_w
	);

	INTC : interrupt_ctrl
	generic map( DATA_WIDTH => DATA_BUS_WIDTH )
	PORT MAP (
		clk_i			=> pclk_w,
		rst_i			=> sys_rst_w,
		cs_i			=> sfr_cs_w(CS_INTC),
		MemWrite_i		=> dbus_MemWrite_w,
		lane0_i			=> lane0_w,
		lane1_i			=> lane1_w,
		data_i			=> data_bus_w,
		bt_ifg_set_i	=> bt_ifg_set_w,
		key_pressed_i	=> key_pressed_w,
		rxerr_ev_i		=> uart_rxerr_ev_w,
		rx_ev_i			=> uart_rx_ev_w,
		tx_ev_i			=> uart_tx_ev_w,
		rx_clr_i		=> uart_rx_clr_w,
		tx_clr_i		=> uart_tx_clr_w,
		gie_i			=> gie_w,
		inta_i			=> inta_w,
		intr_o			=> intr_w,
		type_push_o		=> type_push_w,
		type_capt_o		=> type_capt_w,
		ie_o			=> intc_ie_rd_w,
		ifg_o			=> intc_ifg_rd_w,
		type_o			=> intc_type_rd_w
	);

	alu_obs_w <= ZEROS_BUS(DATA_BUS_WIDTH-1 DOWNTO DATA_ADDR_WIDTH) & dbus_addr_w;

	DBGPORTS:
	if (GEN_DEBUG_PORTS) generate
		IFpc_o				<= IFpc_w;
		IFinstruction_o		<= IFinst_w;
		IDpc_o				<= IDpc_w;
		IDinstruction_o		<= IDinst_w;
		EXpc_o				<= EXpc_w;
		EXinstruction_o		<= EXinst_w;
		MEMpc_o				<= MEMpc_w;
		MEMinstruction_o	<= MEMinst_w;
		WBpc_o				<= WBpc_w;
		WBinstruction_o		<= WBinst_w;
		STRIGGER_o			<= STRIGGER_w;
		CLKCNT_o			<= CLKCNT_w;
		STCNT_o				<= STCNT_w;
		FHCNT_o				<= FHCNT_w;
		MemWrite_ctrl_o		<= dbus_MemWrite_w;
		alu_res_o			<= alu_obs_w;
		read_data2_o		<= dbus_wdata_w;
		dtcm_cs_o			<= dtcm_cs_w;
		unmapped_o			<= unmapped_w;
		dtcm_wren_o			<= dtcm_wren_w;
	else generate
		IFpc_o				<= (others => '0');
		IFinstruction_o		<= (others => '0');
		IDpc_o				<= (others => '0');
		IDinstruction_o		<= (others => '0');
		EXpc_o				<= (others => '0');
		EXinstruction_o		<= (others => '0');
		MEMpc_o				<= (others => '0');
		MEMinstruction_o	<= (others => '0');
		WBpc_o				<= (others => '0');
		WBinstruction_o		<= (others => '0');
		STRIGGER_o			<= '0';
		CLKCNT_o			<= (others => '0');
		STCNT_o				<= (others => '0');
		FHCNT_o				<= (others => '0');
		MemWrite_ctrl_o		<= '0';
		alu_res_o			<= (others => '0');
		read_data2_o		<= (others => '0');
		dtcm_cs_o			<= '0';
		unmapped_o			<= '0';
		dtcm_wren_o			<= '0';
	end generate DBGPORTS;

END structure;
