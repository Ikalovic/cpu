`ifndef PIPE_DEFS_V
`define PIPE_DEFS_V

`define PIPE_WB_ALU 2'b00
`define PIPE_WB_MEM 2'b01

`define PIPE_ALU_ADD  5'd0
`define PIPE_ALU_SUB  5'd1
`define PIPE_ALU_SLT  5'd2
`define PIPE_ALU_SLTU 5'd3
`define PIPE_ALU_XOR  5'd4
`define PIPE_ALU_OR   5'd5
`define PIPE_ALU_AND  5'd6
`define PIPE_ALU_SLL  5'd7
`define PIPE_ALU_SRL  5'd8
`define PIPE_ALU_SRA  5'd9
`define PIPE_ALU_LUI  5'd10

`endif
