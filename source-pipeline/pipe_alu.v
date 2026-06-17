`include "pipe_defs.v"

module pipe_alu(
    input  [31:0] a,
    input  [31:0] b,
    input  [4:0]  alu_op,
    output reg [31:0] result
    );

    always @(*) begin
        case (alu_op)
        `PIPE_ALU_ADD:  result = a + b;
        `PIPE_ALU_SUB:  result = a - b;
        `PIPE_ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        `PIPE_ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
        `PIPE_ALU_XOR:  result = a ^ b;
        `PIPE_ALU_OR:   result = a | b;
        `PIPE_ALU_AND:  result = a & b;
        `PIPE_ALU_SLL:  result = a << b[4:0];
        `PIPE_ALU_SRL:  result = a >> b[4:0];
        `PIPE_ALU_SRA:  result = $signed(a) >>> b[4:0];
        `PIPE_ALU_LUI:  result = b;
        default:        result = 32'b0;
        endcase
    end
endmodule
