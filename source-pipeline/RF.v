module RF(
    input         clk,
    input         rst,
    input         RFWr,
    input  [4:0]  A1, A2, A3,
    input  [31:0] WD,
    output [31:0] RD1, RD2,
    input  [4:0]  reg_sel,
    output [31:0] reg_data
    );

    reg [31:0] rf[31:0];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 1; i < 32; i = i + 1)
                rf[i] <= 32'b0;
        end else if (RFWr && (A3 != 5'd0)) begin
            rf[A3] <= WD;
        end
    end

    assign RD1 = (A1 == 5'd0) ? 32'b0 :
                 (RFWr && (A3 == A1) && (A3 != 5'd0)) ? WD : rf[A1];
    assign RD2 = (A2 == 5'd0) ? 32'b0 :
                 (RFWr && (A3 == A2) && (A3 != 5'd0)) ? WD : rf[A2];
    assign reg_data = (reg_sel == 5'd0) ? 32'b0 : rf[reg_sel];
endmodule
