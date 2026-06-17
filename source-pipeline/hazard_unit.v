module hazard_unit(
    input  [4:0] id_rs1,
    input  [4:0] id_rs2,
    input        id_uses_rs2,
    input  [4:0] idex_rs1,
    input  [4:0] idex_rs2,
    input  [4:0] idex_rd,
    input        idex_mem_read,
    input  [4:0] exmem_rd,
    input        exmem_reg_write,
    input        exmem_mem_read,
    input  [4:0] memwb_rd,
    input        memwb_reg_write,
    input        ex_take_branch,
    output       pc_write,
    output       ifid_write,
    output       idex_flush,
    output       ifid_flush,
    output [1:0] forward_a,
    output [1:0] forward_b
    );

    wire load_use_hazard;

    assign load_use_hazard =
        idex_mem_read &&
        (idex_rd != 5'd0) &&
        ((idex_rd == id_rs1) || (id_uses_rs2 && (idex_rd == id_rs2)));

    assign pc_write   = ~load_use_hazard;
    assign ifid_write = ~load_use_hazard;
    assign idex_flush = load_use_hazard | ex_take_branch;
    assign ifid_flush = ex_take_branch;

    assign forward_a =
        (exmem_reg_write && !exmem_mem_read && (exmem_rd != 5'd0) && (exmem_rd == idex_rs1)) ? 2'b10 :
        (memwb_reg_write && (memwb_rd != 5'd0) && (memwb_rd == idex_rs1)) ? 2'b01 :
        2'b00;

    assign forward_b =
        (exmem_reg_write && !exmem_mem_read && (exmem_rd != 5'd0) && (exmem_rd == idex_rs2)) ? 2'b10 :
        (memwb_reg_write && (memwb_rd != 5'd0) && (memwb_rd == idex_rs2)) ? 2'b01 :
        2'b00;
endmodule
