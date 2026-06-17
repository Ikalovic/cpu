`include "pipe_defs.v"

module pipe_decode(
    input  [31:0] inst,
    output [6:0]  op,
    output [6:0]  funct7,
    output [2:0]  funct3,
    output [4:0]  rs1,
    output [4:0]  rs2,
    output [4:0]  rd,
    output reg [31:0] imm,
    output reg [4:0]  alu_op,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,
    output reg [1:0]  wb_sel,
    output reg        branch,
    output reg        jal,
    output reg        jalr,
    output reg        uses_rs2
    );

    wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] imm_u = {inst[31:12], 12'b0};
    wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

    assign op     = inst[6:0];
    assign funct7 = inst[31:25];
    assign funct3 = inst[14:12];
    assign rs1    = inst[19:15];
    assign rs2    = inst[24:20];
    assign rd     = inst[11:7];

    always @(*) begin
        imm        = imm_i;
        alu_op     = `PIPE_ALU_ADD;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        wb_sel     = `PIPE_WB_ALU;
        branch     = 1'b0;
        jal        = 1'b0;
        jalr       = 1'b0;
        uses_rs2   = 1'b0;

        case (op)
        7'b0110111: begin
            imm       = imm_u;
            alu_op    = `PIPE_ALU_LUI;
            alu_src   = 1'b1;
            reg_write = 1'b1;
        end
        7'b0110011: begin
            reg_write = 1'b1;
            uses_rs2  = 1'b1;
            case ({funct7, funct3})
            {7'b0000000, 3'b000}: alu_op = `PIPE_ALU_ADD;
            {7'b0100000, 3'b000}: alu_op = `PIPE_ALU_SUB;
            {7'b0000000, 3'b010}: alu_op = `PIPE_ALU_SLT;
            {7'b0000000, 3'b011}: alu_op = `PIPE_ALU_SLTU;
            {7'b0000000, 3'b100}: alu_op = `PIPE_ALU_XOR;
            {7'b0000000, 3'b110}: alu_op = `PIPE_ALU_OR;
            {7'b0000000, 3'b111}: alu_op = `PIPE_ALU_AND;
            {7'b0000000, 3'b001}: alu_op = `PIPE_ALU_SLL;
            {7'b0000000, 3'b101}: alu_op = `PIPE_ALU_SRL;
            {7'b0100000, 3'b101}: alu_op = `PIPE_ALU_SRA;
            default: reg_write = 1'b0;
            endcase
        end
        7'b0010011: begin
            imm       = imm_i;
            alu_src   = 1'b1;
            reg_write = 1'b1;
            case (funct3)
            3'b000: alu_op = `PIPE_ALU_ADD;
            3'b010: alu_op = `PIPE_ALU_SLT;
            3'b011: alu_op = `PIPE_ALU_SLTU;
            3'b100: alu_op = `PIPE_ALU_XOR;
            3'b110: alu_op = `PIPE_ALU_OR;
            3'b111: alu_op = `PIPE_ALU_AND;
            3'b001: alu_op = `PIPE_ALU_SLL;
            3'b101: alu_op = (funct7 == 7'b0100000) ? `PIPE_ALU_SRA : `PIPE_ALU_SRL;
            default: reg_write = 1'b0;
            endcase
        end
        7'b0000011: begin
            imm       = imm_i;
            alu_src   = 1'b1;
            alu_op    = `PIPE_ALU_ADD;
            mem_read  = 1'b1;
            reg_write = 1'b1;
            wb_sel    = `PIPE_WB_MEM;
        end
        7'b0100011: begin
            imm       = imm_s;
            alu_src   = 1'b1;
            alu_op    = `PIPE_ALU_ADD;
            mem_write = 1'b1;
            uses_rs2  = 1'b1;
        end
        7'b1100011: begin
            imm      = imm_b;
            branch   = 1'b1;
            uses_rs2 = 1'b1;
        end
        7'b1101111: begin
            imm       = imm_j;
            jal       = 1'b1;
            reg_write = 1'b1;
        end
        7'b1100111: begin
            imm       = imm_i;
            jalr      = 1'b1;
            alu_src   = 1'b1;
            reg_write = 1'b1;
        end
        default: begin
        end
        endcase
    end
endmodule
