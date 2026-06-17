`include "ctrl_encode_def.v"

module MCCPU(
    input             clk,
    input             reset,    // 高电平复位
    input      [31:0] inst_in,  // 当前 PC 从指令存储器读出的指令
    input      [31:0] Data_in,  // 数据存储器读出的数据

    output            mem_w,    // 数据存储器写使能，只在 S_MEM_WR 状态有效
    output     [31:0] PC_out,   // 当前取指地址
    output     [31:0] Addr_out, // 数据存储器访问地址
    output     [31:0] Data_out, // 数据存储器写入数据

    input      [4:0]  reg_sel,  // 调试端口：选择观察的寄存器
    output     [31:0] reg_data  // 调试端口：输出选中寄存器的值
    );

    // 多周期 CPU 将一条指令拆成多个状态执行，避免单个周期承担全部组合逻辑。
    localparam S_FETCH  = 3'd0;
    localparam S_DECODE = 3'd1;
    localparam S_EXEC   = 3'd2;
    localparam S_MEM_RD = 3'd3;
    localparam S_MEM_WR = 3'd4;
    localparam S_WB     = 3'd5;

    reg [2:0]  state;       // 当前状态
    reg [31:0] pc;          // PC 寄存器
    reg [31:0] ir;          // 指令寄存器，保存本条指令供后续周期使用
    reg [31:0] aluout_reg;  // ALU/跳转返回地址等执行结果暂存
    reg [31:0] addr_reg;    // 访存地址暂存，供 MEM_RD/MEM_WR 使用
    reg [31:0] wdata_reg;   // sw 写内存数据暂存
    reg [31:0] mdr;         // Memory Data Register，保存 lw 从内存读出的值
    reg [31:0] wd_reg;      // 写回寄存器堆的数据
    reg [4:0]  rd_reg;      // 写回目的寄存器编号
    reg        rf_we_reg;   // 写回阶段的寄存器写使能

    // 所有译码字段都从 ir 取，保证一条指令在多个周期内保持稳定。
    wire [6:0] op     = ir[6:0];
    wire [6:0] funct7 = ir[31:25];
    wire [2:0] funct3 = ir[14:12];
    wire [4:0] rs1    = ir[19:15];
    wire [4:0] rs2    = ir[24:20];
    wire [4:0] rd     = ir[11:7];

    wire [31:0] rd1;
    wire [31:0] rd2;

    // 多周期版本直接在 CPU 内部完成各类立即数扩展。
    wire [31:0] imm_i = {{20{ir[31]}}, ir[31:20]};
    wire [31:0] imm_s = {{20{ir[31]}}, ir[31:25], ir[11:7]};
    wire [31:0] imm_b = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
    wire [31:0] imm_u = {ir[31:12], 12'b0};
    wire [31:0] imm_j = {{11{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};

    // 对外连接：PC 送指令存储器，addr/data/mem_w 送数据存储器。
    assign PC_out   = pc;
    assign Addr_out = addr_reg;
    assign Data_out = wdata_reg;
    assign mem_w    = (state == S_MEM_WR);

    // 寄存器堆仍然是双读单写结构；只有 S_WB 状态会拉高 rf_we_reg。
    RF U_RF(
        .clk(clk),
        .rst(reset),
        .RFWr(rf_we_reg),
        .A1(rs1),
        .A2(rs2),
        .A3(rd_reg),
        .WD(wd_reg),
        .RD1(rd1),
        .RD2(rd2),
        .reg_sel(reg_sel),
        .reg_data(reg_data)
    );

    function [31:0] rtype_result;
        input [31:0] a;
        input [31:0] b;
        input [6:0]  f7;
        input [2:0]  f3;
        begin
            // R 型指令的运算由 funct7 + funct3 共同决定。
            // final 中的 slt/sltu 在这里返回 0/1；移位指令只使用 b[4:0]。
            case ({f7, f3})
            {7'b0000000, 3'b000}: rtype_result = a + b;
            {7'b0100000, 3'b000}: rtype_result = a - b;
            {7'b0000000, 3'b010}: rtype_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            {7'b0000000, 3'b011}: rtype_result = (a < b) ? 32'd1 : 32'd0;
            {7'b0000000, 3'b100}: rtype_result = a ^ b;
            {7'b0000000, 3'b110}: rtype_result = a | b;
            {7'b0000000, 3'b111}: rtype_result = a & b;
            {7'b0000000, 3'b001}: rtype_result = a << b[4:0];
            {7'b0000000, 3'b101}: rtype_result = a >> b[4:0];
            {7'b0100000, 3'b101}: rtype_result = $signed(a) >>> b[4:0];
            default:              rtype_result = 32'b0;
            endcase
        end
    endfunction

    function [31:0] itype_result;
        input [31:0] a;
        input [31:0] imm;
        input [6:0]  f7;
        input [2:0]  f3;
        begin
            // I 型算术逻辑指令使用 rs1 与符号扩展立即数运算。
            // addi/andi/ori/xori/slti/sltiu/slli/srli/srai 都走本函数。
            // srli 与 srai 都是 funct3=101，通过 funct7 区分是否保留符号位。
            case (f3)
            3'b000: itype_result = a + imm;
            3'b010: itype_result = ($signed(a) < $signed(imm)) ? 32'd1 : 32'd0;
            3'b011: itype_result = (a < imm) ? 32'd1 : 32'd0;
            3'b100: itype_result = a ^ imm;
            3'b110: itype_result = a | imm;
            3'b111: itype_result = a & imm;
            3'b001: itype_result = (f7 == 7'b0000000) ? (a << imm[4:0]) : 32'b0;
            3'b101: itype_result = (f7 == 7'b0100000) ? ($signed(a) >>> imm[4:0]) : (a >> imm[4:0]);
            default: itype_result = 32'b0;
            endcase
        end
    endfunction

    function branch_taken;
        input [31:0] a;
        input [31:0] b;
        input [2:0]  f3;
        begin
            // 分支指令只需要判断条件并更新 PC，不需要写回寄存器。
            // beq/bne 使用相等关系，blt/bge 使用有符号比较，bltu/bgeu 使用无符号比较。
            case (f3)
            3'b000: branch_taken = (a == b);
            3'b001: branch_taken = (a != b);
            3'b100: branch_taken = ($signed(a) < $signed(b));
            3'b101: branch_taken = ($signed(a) >= $signed(b));
            3'b110: branch_taken = (a < b);
            3'b111: branch_taken = (a >= b);
            default: branch_taken = 1'b0;
            endcase
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 复位清空所有跨周期寄存器，状态机回到取指状态。
            state      <= S_FETCH;
            pc         <= 32'h0000_0000;
            ir         <= 32'b0;
            aluout_reg <= 32'b0;
            addr_reg   <= 32'b0;
            wdata_reg  <= 32'b0;
            mdr        <= 32'b0;
            wd_reg     <= 32'b0;
            rd_reg     <= 5'b0;
            rf_we_reg  <= 1'b0;
        end else begin
            // 写寄存器只允许在 S_WB 拉高一个周期，因此每拍先默认清 0。
            rf_we_reg <= 1'b0;

            case (state)
            S_FETCH: begin
                // 取指阶段：把当前指令保存到 ir，同时 PC 先顺序加 4。
                // 如果后续发现是 branch/jal，会在 EXEC 阶段修正 PC。
                ir    <= inst_in;
                pc    <= pc + 32'd4;
                state <= S_DECODE;
            end

            S_DECODE: begin
                // 译码阶段目前不做额外寄存，只留出一个周期让寄存器堆读数稳定。
                state <= S_EXEC;
            end

            S_EXEC: begin
                // 执行阶段根据 opcode 决定后续状态：写回、访存或直接回取指。
                rd_reg <= rd;
                case (op)
                7'b0110011: begin // R-type
                    // R 型：两个源操作数来自寄存器堆，结果进入 aluout_reg 等待写回。
                    aluout_reg <= rtype_result(rd1, rd2, funct7, funct3);
                    state <= S_WB;
                end
                7'b0010011: begin // I-type arithmetic
                    // I 型算术逻辑：rs1 与立即数运算，结果写回 rd。
                    // 本状态只计算结果，真正写入寄存器在 S_WB 完成。
                    aluout_reg <= itype_result(rd1, imm_i, funct7, funct3);
                    state <= S_WB;
                end
                7'b0110111: begin // lui
                    // lui：U 型立即数直接作为写回结果。
                    aluout_reg <= imm_u;
                    state <= S_WB;
                end
                7'b0000011: begin // lw
                    // lw：先计算访存地址，下一状态读内存。
                    addr_reg <= rd1 + imm_i;
                    state <= S_MEM_RD;
                end
                7'b0100011: begin // sw
                    // sw：计算地址并锁存写数据，下一状态执行内存写。
                    addr_reg  <= rd1 + imm_s;
                    wdata_reg <= rd2;
                    state <= S_MEM_WR;
                end
                7'b1100011: begin // branch
                    // FETCH 阶段已经 pc+4，因此分支目标用 (pc-4)+imm_b。
                    // 分支指令不进入 S_WB；条件成立时直接修正 PC，然后回到 S_FETCH。
                    if (branch_taken(rd1, rd2, funct3))
                        pc <= (pc - 32'd4) + imm_b;
                    state <= S_FETCH;
                end
                7'b1101111: begin // jal
                    // jal 返回地址为取指后已经更新的 pc，即原 PC+4。
                    // 目标地址从当前指令地址计算，所以使用 (pc-4)+imm_j。
                    aluout_reg <= pc;
                    pc <= (pc - 32'd4) + imm_j;
                    state <= S_WB;
                end
                7'b1100111: begin // jalr
                    // jalr 目标地址由 rs1+imm_i 产生，并按规范清零最低位。
                    // 返回地址仍写入 aluout_reg，若 rd 为 x0，寄存器堆会自动忽略写入。
                    aluout_reg <= pc;
                    pc <= (rd1 + imm_i) & 32'hffff_fffe;
                    state <= S_WB;
                end
                default: begin
                    state <= S_FETCH;
                end
                endcase
            end

            S_MEM_RD: begin
                // 数据存储器组合读出的值锁存到 mdr，下一状态再写回寄存器。
                mdr <= Data_in;
                state <= S_WB;
            end

            S_MEM_WR: begin
                // mem_w 在本状态为 1，数据存储器在该时钟沿完成写入。
                state <= S_FETCH;
            end

            S_WB: begin
                // 写回阶段：lw 写回 mdr，其他需要写回的指令写回 aluout_reg。
                wd_reg <= (op == 7'b0000011) ? mdr : aluout_reg;
                rf_we_reg <= 1'b1;
                state <= S_FETCH;
            end

            default: begin
                state <= S_FETCH;
            end
            endcase
        end
    end

endmodule
