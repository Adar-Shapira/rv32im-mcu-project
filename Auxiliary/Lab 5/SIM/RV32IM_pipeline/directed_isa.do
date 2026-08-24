# Directed regressions for ISA defects fixed in the pipelined core.
# Run after compiling the design into work.
onerror {quit -code 1}
vsim -t ns work.tb_rv32im_pipeline
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

proc expect_hex {signal expected label} {
    set actual [string tolower [examine -radix hexadecimal $signal]]
    set expected [string tolower $expected]
    if {$actual ne $expected} {
        echo "FAIL: $label expected $expected, got $actual"
        quit -code 1
    }
    echo "PASS: $label = $actual"
}

# CONTROL must distinguish ANDI from ORI.
force -freeze /tb_rv32im_pipeline/CORE/CTL/instruction_i 32'h00007013 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/CTL/ALUOp_ctrl_o 07 ANDI_decode
force -freeze /tb_rv32im_pipeline/CORE/CTL/instruction_i 32'h00006013 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/CTL/ALUOp_ctrl_o 08 ORI_decode
noforce /tb_rv32im_pipeline/CORE/CTL/instruction_i

# Immediate selection must cover loads, LUI, and AUIPC.
force -freeze /tb_rv32im_pipeline/CORE/ID/instruction_i 32'h0040a103 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/ID/SignExt_w 00000004 LW_immediate
force -freeze /tb_rv32im_pipeline/CORE/ID/instruction_i 32'h123450b7 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/ID/SignExt_w 12345000 LUI_immediate
expect_hex /tb_rv32im_pipeline/CORE/CTL/UpperIm_ctrl_o 2 LUI_upper_select
force -freeze /tb_rv32im_pipeline/CORE/ID/instruction_i 32'h12345097 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/ID/SignExt_w 12345000 AUIPC_immediate
expect_hex /tb_rv32im_pipeline/CORE/CTL/UpperIm_ctrl_o 1 AUIPC_upper_select
noforce /tb_rv32im_pipeline/CORE/ID/instruction_i

# Drive the EX ALU directly: no forwarding and register operands on both inputs.
force -freeze /tb_rv32im_pipeline/CORE/EXE/UpperIm_ctrl_i 2'h0 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/ALUSrc_ctrl_i 1'b0 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/forward_a_i 2'h0 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/forward_b_i 2'h0 0

# Unsigned 0x80000000 < 1 is false; 1 < 0x80000000 is true.
force -freeze /tb_rv32im_pipeline/CORE/EXE/ALUOp_ctrl_i 5'h0a 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data1_i 32'h80000000 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data2_i 32'h00000001 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/EXE/alu_res_r 00000000 SLTU_high_bit
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data1_i 32'h00000001 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data2_i 32'h80000000 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/EXE/alu_res_r 00000001 SLTU_reverse

# Arithmetic right shift must replicate the sign bit through every barrel stage.
force -freeze /tb_rv32im_pipeline/CORE/EXE/ALUOp_ctrl_i 5'h03 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data1_i 32'h80000000 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data2_i 32'h00000004 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/EXE/alu_res_r f8000000 SRA_sign_extension

# Branch/JAL target adder must retain the complete PC-width immediate slice.
force -freeze /tb_rv32im_pipeline/CORE/EXE/pc_i 13'h0000 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/sign_extend_i 32'h00000400 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/EXE/addr_gen_w 0800 BRANCH_plus_2048

# Figure 7 split multiplier: stage 1 creates four 8x8 products in EX,
# and stage 2 combines the EX/MEM values in MEM.
force -freeze /tb_rv32im_pipeline/CORE/EXE/ALUOp_ctrl_i 5'h0c 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data1_i 32'h00000102 0
force -freeze /tb_rv32im_pipeline/CORE/EXE/read_data2_i 32'h00000304 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/EXE/mul_p0_w 0008 MUL_stage1_P0
expect_hex /tb_rv32im_pipeline/CORE/EXE/mul_p1_w 0006 MUL_stage1_P1
expect_hex /tb_rv32im_pipeline/CORE/EXE/mul_p2_w 0004 MUL_stage1_P2
expect_hex /tb_rv32im_pipeline/CORE/EXE/mul_p3_w 0003 MUL_stage1_P3

force -freeze /tb_rv32im_pipeline/CORE/MEM/mul_p0_i 16'h0008 0
force -freeze /tb_rv32im_pipeline/CORE/MEM/mul_p1_i 16'h0006 0
force -freeze /tb_rv32im_pipeline/CORE/MEM/mul_p2_i 16'h0004 0
force -freeze /tb_rv32im_pipeline/CORE/MEM/mul_p3_i 16'h0003 0
force -freeze /tb_rv32im_pipeline/CORE/MEM/Mul_ctrl_i 1'b1 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/MEM/mul_res_w 00030a08 MUL_stage2_result
expect_hex /tb_rv32im_pipeline/CORE/MEM/mem_forward_data_o 00030a08 MUL_MEM_forwarding

# Release the direct MEM forces and clock the same MUL through EX/MEM and
# MEM/WB to verify the stage boundary and write-back integration.
noforce /tb_rv32im_pipeline/CORE/MEM/mul_p0_i
noforce /tb_rv32im_pipeline/CORE/MEM/mul_p1_i
noforce /tb_rv32im_pipeline/CORE/MEM/mul_p2_i
noforce /tb_rv32im_pipeline/CORE/MEM/mul_p3_i
noforce /tb_rv32im_pipeline/CORE/MEM/Mul_ctrl_i
force -freeze /tb_rv32im_pipeline/rst_i 1'b0 0
run 90 ns
expect_hex /tb_rv32im_pipeline/CORE/EXE/ex_mem_Mul_q 1 MUL_EX_MEM_control
expect_hex /tb_rv32im_pipeline/CORE/MEM/mem_result_w 00030a08 MUL_EX_MEM_to_MEM
run 100 ns
expect_hex /tb_rv32im_pipeline/CORE/wb_alu_res_w 00030a08 MUL_MEM_WB_result

# JALR target must clear address bit zero.
force -freeze /tb_rv32im_pipeline/CORE/mem_Jalr_w 1'b1 0
force -freeze /tb_rv32im_pipeline/CORE/mem_alu_res_w 32'h00000003 0
run 1 ns
expect_hex /tb_rv32im_pipeline/CORE/redirect_addr_w 0002 JALR_lsb_clear

echo "PASS: all directed ISA regressions"
quit -f
