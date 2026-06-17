`timescale 1ns/1ns

module pipecomp_tb();
  reg clk;
  reg rstn;
  reg [4:0] reg_sel;
  wire [31:0] reg_data;

  integer errors;
  integer i;

  pipecomp dut(.clk(clk), .rstn(rstn), .reg_sel(reg_sel), .reg_data(reg_data));

  initial begin
    $readmemh("rv32_sid_sort_sim.dat", dut.U_imem.RAM, 0, 54);
    for (i = 0; i < 128; i = i + 1) begin
      dut.U_DM.dmem[i] = 32'h0000_0000;
    end

    clk = 1'b1;
    rstn = 1'b1;
    reg_sel = 5'd0;
    errors = 0;
    #10;
    rstn = 1'b0;
  end

  always begin
    #5 clk = ~clk;
  end

  initial begin
    $dumpfile("pipe_cpu_sid_sort.vcd");
    $dumpvars(0, pipecomp_tb);

    #8000;

    if (dut.U_DM.dmem[96] !== 32'h5487_3530) begin
      $display("[FAIL] mem[0x180] expected original sid 0x54873530, got %h", dut.U_DM.dmem[96]);
      errors = errors + 1;
    end
    if (dut.U_DM.dmem[97] !== 32'h0334_5578) begin
      $display("[FAIL] mem[0x184] expected sorted sid 0x03345578, got %h", dut.U_DM.dmem[97]);
      errors = errors + 1;
    end
    if (dut.U_PIPECPU.U_RF.rf[1] !== 32'hffff_0004) begin
      $display("[FAIL] x1 expected 0xffff0004, got %h", dut.U_PIPECPU.U_RF.rf[1]);
      errors = errors + 1;
    end
    if (dut.U_PIPECPU.U_RF.rf[2] !== 32'hffff_000c) begin
      $display("[FAIL] x2 expected 0xffff000c, got %h", dut.U_PIPECPU.U_RF.rf[2]);
      errors = errors + 1;
    end
    if (dut.U_PIPECPU.U_RF.rf[5] !== 32'h0000_0100) begin
      $display("[FAIL] x5 expected 0x00000100, got %h", dut.U_PIPECPU.U_RF.rf[5]);
      errors = errors + 1;
    end

    $display("[RESULT] original_sid=%h", dut.U_DM.dmem[96]);
    $display("[RESULT] sorted_sid=%h", dut.U_DM.dmem[97]);

    if (errors == 0)
      $display("[PASS] lab-6 pipeline sid sorting simulation passed.");
    else
      $display("[FAIL] lab-6 pipeline sid sorting simulation failed with %0d error(s).", errors);

    #20;
    $finish;
  end
endmodule
