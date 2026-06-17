`include "pipe_defs.v"

module PipelineCPU(
    input             clk,
    input             reset,
    input      [31:0] inst_in,
    input      [31:0] Data_in,

    output            mem_w,
    output     [31:0] PC_out,
    output     [31:0] Addr_out,
    output     [31:0] Data_out,

    input      [4:0]  reg_sel,
    output     [31:0] reg_data
    );

    reg [31:0] pc;

    // IF/ID 流水线寄存器：保存取到的指令和取指 PC。
    reg        ifid_valid;
    reg [31:0] ifid_pc;
    reg [31:0] ifid_inst;

    // ID/EX 流水线寄存器：保存译码后的源操作数、立即数、目的寄存器和控制信号。
    reg        idex_valid;
    reg [31:0] idex_pc;
    reg [31:0] idex_rd1;
    reg [31:0] idex_rd2;
    reg [31:0] idex_imm;
    reg [4:0]  idex_rs1;
    reg [4:0]  idex_rs2;
    reg [4:0]  idex_rd;
    reg [6:0]  idex_op;
    reg [2:0]  idex_funct3;
    reg [4:0]  idex_alu_op;
    reg        idex_reg_write;
    reg        idex_mem_read;
    reg        idex_mem_write;
    reg        idex_alu_src;
    reg [1:0]  idex_wb_sel;
    reg        idex_branch;
    reg        idex_jal;
    reg        idex_jalr;

    // EX/MEM 流水线寄存器：保存 ALU 结果、store 写数据和访存/写回控制信号。
    reg        exmem_valid;
    reg [31:0] exmem_alu_result;
    reg [31:0] exmem_store_data;
    reg [4:0]  exmem_rd;
    reg        exmem_reg_write;
    reg        exmem_mem_read;
    reg        exmem_mem_write;
    reg [1:0]  exmem_wb_sel;

    // MEM/WB 流水线寄存器：保存内存读数或 ALU 结果，供 WB 阶段写回。
    reg        memwb_valid;
    reg [31:0] memwb_alu_result;
    reg [31:0] memwb_mem_data;
    reg [4:0]  memwb_rd;
    reg        memwb_reg_write;
    reg [1:0]  memwb_wb_sel;

    wire [31:0] wb_data =
        (memwb_wb_sel == `PIPE_WB_MEM) ? memwb_mem_data : memwb_alu_result;

    wire [31:0] rf_rd1;
    wire [31:0] rf_rd2;

    RF U_RF(
        .clk(clk),
        .rst(reset),
        .RFWr(memwb_valid && memwb_reg_write),
        .A1(ifid_inst[19:15]),
        .A2(ifid_inst[24:20]),
        .A3(memwb_rd),
        .WD(wb_data),
        .RD1(rf_rd1),
        .RD2(rf_rd2),
        .reg_sel(reg_sel),
        .reg_data(reg_data)
    );

    wire [6:0] id_op;
    wire [6:0] id_funct7;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [4:0] id_rd;
    wire [31:0] id_imm;
    wire [4:0]  id_alu_op;
    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_alu_src;
    wire [1:0]  id_wb_sel;
    wire        id_branch;
    wire        id_jal;
    wire        id_jalr;
    wire        id_uses_rs2;

    pipe_decode U_DECODE(
        .inst(ifid_inst),
        .op(id_op),
        .funct7(id_funct7),
        .funct3(id_funct3),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),
        .imm(id_imm),
        .alu_op(id_alu_op),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .alu_src(id_alu_src),
        .wb_sel(id_wb_sel),
        .branch(id_branch),
        .jal(id_jal),
        .jalr(id_jalr),
        .uses_rs2(id_uses_rs2)
    );

    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire       pc_write;
    wire       ifid_write;
    wire       idex_flush;
    wire       ifid_flush;

    reg [31:0] alu_in_a;
    reg [31:0] rs2_forwarded;
    wire [31:0] alu_in_b = idex_alu_src ? idex_imm : rs2_forwarded;
    wire [31:0] alu_result;
    wire        branch_ok;

    always @(*) begin
        // ALU 输入选择：优先使用 hazard_unit 给出的转发数据。
        case (forward_a)
        2'b10: alu_in_a = exmem_alu_result;
        2'b01: alu_in_a = wb_data;
        default: alu_in_a = idex_rd1;
        endcase

        case (forward_b)
        2'b10: rs2_forwarded = exmem_alu_result;
        2'b01: rs2_forwarded = wb_data;
        default: rs2_forwarded = idex_rd2;
        endcase
    end

    pipe_alu U_ALU(
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_op(idex_alu_op),
        .result(alu_result)
    );

    wire ex_take_branch;
    wire [31:0] ex_branch_target;
    wire [31:0] ex_pc4_result;
    wire [31:0] ex_result = (idex_jal || idex_jalr) ? ex_pc4_result : alu_result;

    pipe_branch U_BRANCH(
        .valid(idex_valid),
        .branch(idex_branch),
        .jal(idex_jal),
        .jalr(idex_jalr),
        .funct3(idex_funct3),
        .src_a(alu_in_a),
        .src_b(rs2_forwarded),
        .pc(idex_pc),
        .imm(idex_imm),
        .branch_ok(branch_ok),
        .take_branch(ex_take_branch),
        .branch_target(ex_branch_target),
        .pc4_result(ex_pc4_result)
    );

    hazard_unit U_HAZARD(
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_uses_rs2(id_uses_rs2),
        .idex_rs1(idex_rs1),
        .idex_rs2(idex_rs2),
        .idex_rd(idex_rd),
        .idex_mem_read(idex_mem_read),
        .exmem_rd(exmem_rd),
        .exmem_reg_write(exmem_valid && exmem_reg_write),
        .exmem_mem_read(exmem_mem_read),
        .memwb_rd(memwb_rd),
        .memwb_reg_write(memwb_valid && memwb_reg_write),
        .ex_take_branch(ex_take_branch),
        .pc_write(pc_write),
        .ifid_write(ifid_write),
        .idex_flush(idex_flush),
        .ifid_flush(ifid_flush),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    assign PC_out   = pc;
    assign mem_w    = exmem_valid && exmem_mem_write;
    assign Addr_out = exmem_alu_result;
    assign Data_out = exmem_store_data;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;

            ifid_valid <= 1'b0;
            ifid_pc <= 32'b0;
            ifid_inst <= 32'b0;

            idex_valid <= 1'b0;
            idex_pc <= 32'b0;
            idex_rd1 <= 32'b0;
            idex_rd2 <= 32'b0;
            idex_imm <= 32'b0;
            idex_rs1 <= 5'b0;
            idex_rs2 <= 5'b0;
            idex_rd <= 5'b0;
            idex_op <= 7'b0;
            idex_funct3 <= 3'b0;
            idex_alu_op <= `PIPE_ALU_ADD;
            idex_reg_write <= 1'b0;
            idex_mem_read <= 1'b0;
            idex_mem_write <= 1'b0;
            idex_alu_src <= 1'b0;
            idex_wb_sel <= `PIPE_WB_ALU;
            idex_branch <= 1'b0;
            idex_jal <= 1'b0;
            idex_jalr <= 1'b0;

            exmem_valid <= 1'b0;
            exmem_alu_result <= 32'b0;
            exmem_store_data <= 32'b0;
            exmem_rd <= 5'b0;
            exmem_reg_write <= 1'b0;
            exmem_mem_read <= 1'b0;
            exmem_mem_write <= 1'b0;
            exmem_wb_sel <= `PIPE_WB_ALU;

            memwb_valid <= 1'b0;
            memwb_alu_result <= 32'b0;
            memwb_mem_data <= 32'b0;
            memwb_rd <= 5'b0;
            memwb_reg_write <= 1'b0;
            memwb_wb_sel <= `PIPE_WB_ALU;
        end else begin
            memwb_valid <= exmem_valid;
            memwb_alu_result <= exmem_alu_result;
            memwb_mem_data <= Data_in;
            memwb_rd <= exmem_rd;
            memwb_reg_write <= exmem_reg_write;
            memwb_wb_sel <= exmem_wb_sel;

            exmem_valid <= idex_valid;
            exmem_alu_result <= ex_result;
            exmem_store_data <= rs2_forwarded;
            exmem_rd <= idex_rd;
            exmem_reg_write <= idex_reg_write;
            exmem_mem_read <= idex_mem_read;
            exmem_mem_write <= idex_mem_write;
            exmem_wb_sel <= idex_wb_sel;

            if (idex_flush) begin
                idex_valid <= 1'b0;
                idex_pc <= 32'b0;
                idex_rd1 <= 32'b0;
                idex_rd2 <= 32'b0;
                idex_imm <= 32'b0;
                idex_rs1 <= 5'b0;
                idex_rs2 <= 5'b0;
                idex_rd <= 5'b0;
                idex_op <= 7'b0;
                idex_funct3 <= 3'b0;
                idex_alu_op <= `PIPE_ALU_ADD;
                idex_reg_write <= 1'b0;
                idex_mem_read <= 1'b0;
                idex_mem_write <= 1'b0;
                idex_alu_src <= 1'b0;
                idex_wb_sel <= `PIPE_WB_ALU;
                idex_branch <= 1'b0;
                idex_jal <= 1'b0;
                idex_jalr <= 1'b0;
            end else begin
                idex_valid <= ifid_valid;
                idex_pc <= ifid_pc;
                idex_rd1 <= rf_rd1;
                idex_rd2 <= rf_rd2;
                idex_imm <= id_imm;
                idex_rs1 <= id_rs1;
                idex_rs2 <= id_rs2;
                idex_rd <= id_rd;
                idex_op <= id_op;
                idex_funct3 <= id_funct3;
                idex_alu_op <= id_alu_op;
                idex_reg_write <= id_reg_write;
                idex_mem_read <= id_mem_read;
                idex_mem_write <= id_mem_write;
                idex_alu_src <= id_alu_src;
                idex_wb_sel <= id_wb_sel;
                idex_branch <= id_branch;
                idex_jal <= id_jal;
                idex_jalr <= id_jalr;
            end

            if (ex_take_branch) begin
                pc <= ex_branch_target;
            end else if (pc_write) begin
                pc <= pc + 32'd4;
            end

            if (ifid_flush) begin
                ifid_valid <= 1'b0;
                ifid_pc <= 32'b0;
                ifid_inst <= 32'b0;
            end else if (ifid_write) begin
                ifid_valid <= 1'b1;
                ifid_pc <= pc;
                ifid_inst <= inst_in;
            end
        end
    end
endmodule
