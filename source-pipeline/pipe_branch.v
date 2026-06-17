module pipe_branch(
    input         valid,
    input         branch,
    input         jal,
    input         jalr,
    input  [2:0]  funct3,
    input  [31:0] src_a,
    input  [31:0] src_b,
    input  [31:0] pc,
    input  [31:0] imm,
    output reg    branch_ok,
    output        take_branch,
    output [31:0] branch_target,
    output [31:0] pc4_result
    );

    always @(*) begin
        case (funct3)
        3'b000: branch_ok = (src_a == src_b);
        3'b001: branch_ok = (src_a != src_b);
        3'b100: branch_ok = ($signed(src_a) < $signed(src_b));
        3'b101: branch_ok = ($signed(src_a) >= $signed(src_b));
        3'b110: branch_ok = (src_a < src_b);
        3'b111: branch_ok = (src_a >= src_b);
        default: branch_ok = 1'b0;
        endcase
    end

    assign take_branch = valid && ((branch && branch_ok) || jal || jalr);
    assign branch_target = jalr ? ((src_a + imm) & 32'hffff_fffe) : (pc + imm);
    assign pc4_result = pc + 32'd4;
endmodule
