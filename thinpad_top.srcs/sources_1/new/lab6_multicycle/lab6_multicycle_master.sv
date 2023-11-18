`default_nettype none
`include "macro.svh"

module lab6_multicycle_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // // PC 的初始值
    // input wire [31:0] pc_init_i;

    // 连接 ALU 模块的信号
    output reg [31:0] alu_operand1_o,
    output reg [31:0] alu_operand2_o,
    output reg [3:0]  alu_op_o,
    input  reg [31:0] alu_result_i,

    // 连接寄存器堆模块的信号
    output reg  [4:0]  rf_raddr_a_o,
    input  wire [31:0] rf_rdata_a_i,
    output reg  [4:0]  rf_raddr_b_o,
    input  wire [31:0] rf_rdata_b_i,
    output reg  [4:0]  rf_waddr_o,
    output reg  [31:0] rf_wdata_o,
    output reg  rf_we_o,

    // 连接 imm_gen 模块的信号
    output reg [31:0] imm_gen_inst_o,
    output reg [2:0]  imm_gen_type_o,
    input  wire [31:0] imm_gen_i,

    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

  typedef enum logic [2:0] { 
    STATE_IF = 0,
    STATE_ID = 1,
    STATE_EXE = 2,
    STATE_MEM = 3,
    STATE_WB = 4
  } state_t;

  state_t state;
  reg [31:0] pc_reg;
  reg [31:0] pc_now_reg;
  reg [31:0] inst_reg;
  reg [31:0] operand1_reg, operand2_reg;
  reg [31:0] rf_writeback_reg;
  reg [31:0] sram_raddr_reg;
  reg [31:0] sram_waddr_reg;
  reg [31:0] sram_wdata_reg;
  reg [31:0] imm_reg;
  reg [31:0] store_reg;
  wire [1:0] rsel_shift;
  wire [1:0] wsel_shift;
  wire [31:0] rdata_shift;
  wire [31:0] wdata_shift;

  assign rsel_shift = sram_raddr_reg[1:0];
  assign wsel_shift = sram_waddr_reg[1:0];
  assign rdata_shift = sram_raddr_reg[1:0] << 3;
  assign wdata_shift = sram_waddr_reg[1:0] << 3;

  always_comb begin
    // 设置默认值
    alu_operand1_o = 32'h0000_0000;
    alu_operand2_o = 32'h0000_0000;
    alu_op_o = 4'b0000;

    rf_raddr_a_o = 5'b00000;
    rf_raddr_b_o = 5'b00000;
    rf_waddr_o = 5'b00000;
    rf_wdata_o = 32'h0000_0000;
    rf_we_o = 1'b0;

    imm_gen_inst_o = 32'h0000_0000;
    imm_gen_type_o = 3'b000;

    wb_cyc_o = 1'b0;
    wb_stb_o = 1'b0;
    wb_adr_o = 32'h1000_0005;
    wb_dat_o = 32'h0000_0000;
    wb_sel_o = 4'b0000;
    wb_we_o = 1'b0;
    
    case (state) 
      STATE_IF: begin
        alu_operand1_o = pc_reg;
        alu_operand2_o = 32'h0000_0004;
        alu_op_o = `ALU_ADD;

        wb_cyc_o = 1'b1;
        wb_stb_o = 1'b1;
        wb_adr_o = pc_reg;
        wb_sel_o = 4'b1111;
        wb_we_o = 1'b0;
      end

      STATE_ID: begin
        rf_raddr_a_o = `RS1;
        rf_raddr_b_o = `RS2;
        rf_we_o = 1'b0;

        imm_gen_inst_o = inst_reg;
        if (`IS_ITYPE || `IS_LOAD) begin
          imm_gen_type_o = `TYPE_I;
        end else if (`IS_STYPE) begin
          imm_gen_type_o = `TYPE_S;
        end else if (`IS_BTYPE) begin
          imm_gen_type_o = `TYPE_B;
        end else if (`IS_LUI) begin
          imm_gen_type_o = `TYPE_U;
        end else begin
          imm_gen_type_o = 3'b000;
        end

        wb_cyc_o = 1'b0;
        wb_stb_o = 1'b0;
      end

      STATE_EXE: begin
        alu_operand1_o = operand1_reg;
        alu_operand2_o = operand2_reg;
        if (`IS_ADDI || `IS_ADD || `IS_LB || `IS_SB || `IS_SW) begin
          alu_op_o = `ALU_ADD;
        end else if (`IS_ANDI) begin
          alu_op_o = `ALU_AND;
        end else begin
          alu_op_o = 4'b0000;
        end
      end

      STATE_MEM: begin
        if (`IS_LB) begin
          wb_cyc_o = 1'b1;
          wb_stb_o = 1'b1;
          wb_adr_o = sram_raddr_reg;
          wb_sel_o = 4'b0001 << rsel_shift;
          wb_we_o = 1'b0;
        end else if (`IS_SB || `IS_SW) begin
          wb_cyc_o = 1'b1;
          wb_stb_o = 1'b1;
          wb_adr_o = sram_waddr_reg;
          wb_dat_o = sram_wdata_reg << wdata_shift;
          wb_sel_o = (`IS_SB ? 4'b0001 : 4'b0011) << wsel_shift;
          wb_we_o = 1'b1;
        end else begin
          wb_cyc_o = 1'b0;
          wb_stb_o = 1'b0;
        end
      end

      STATE_WB: begin
        if (`IS_ADDI || `IS_ADD || `IS_ANDI || `IS_LB || `IS_LUI) begin
          rf_wdata_o = rf_writeback_reg;
          rf_waddr_o = `RD;
          rf_we_o = 1'b1;

          wb_cyc_o = 1'b0;
          wb_stb_o = 1'b0;
        end else begin // sb, sw, beq 不需要写回
          rf_we_o = 1'b0;

          wb_cyc_o = 1'b0;
          wb_stb_o = 1'b0;
        end
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
        state <= STATE_IF;
        pc_reg <= `PC_INIT;
        pc_now_reg <= `PC_INIT + 32'h0000_0004;
        inst_reg <= 32'h0000_0000;
        operand1_reg <= 32'h0000_0000;
        operand2_reg <= 32'h0000_0000;
        rf_writeback_reg <= 32'h0000_0000;
        sram_raddr_reg <= 32'h0000_0000;
        sram_waddr_reg <= 32'h0000_0000;
        sram_wdata_reg <= 32'h0000_0000;
    end else begin
      case (state)
        STATE_IF: begin
          inst_reg <= wb_dat_i;
          pc_now_reg <= pc_reg;

          if (wb_ack_i) begin
            pc_reg <= alu_result_i;
            state <= STATE_ID;
          end
        end

        STATE_ID: begin
          if (`IS_ADDI || `IS_ANDI || `IS_LB) begin
            operand1_reg <= rf_rdata_a_i;
            operand2_reg <= imm_gen_i;
            state <= STATE_EXE;
          end else if (`IS_SB || `IS_SW) begin
            operand1_reg <= rf_rdata_a_i;
            operand2_reg <= imm_gen_i;
            store_reg <= rf_rdata_b_i;
            state <= STATE_EXE;
          end else if (`IS_ADD) begin
            operand1_reg <= rf_rdata_a_i;
            operand2_reg <= rf_rdata_b_i;
            state <= STATE_EXE;
          end else if (`IS_BEQ) begin
            operand1_reg <= rf_rdata_a_i;
            operand2_reg <= rf_rdata_b_i;
            imm_reg <= imm_gen_i;
            state <= STATE_EXE;
          end else if (`IS_LUI) begin
            rf_writeback_reg <= imm_gen_i;
            state <= STATE_WB;
          end
        end

        STATE_EXE: begin
          if (`IS_ADDI || `IS_ADD || `IS_ANDI) begin
            rf_writeback_reg <= alu_result_i;
            state <= STATE_WB;
          end else if (`IS_LB) begin
            sram_raddr_reg <= alu_result_i;
            state <= STATE_MEM;
          end else if (`IS_SB || `IS_SW) begin
            sram_waddr_reg <= alu_result_i;
            sram_wdata_reg <= `IS_SB ? store_reg & 32'h0000_00FF : store_reg & 32'h0000_FFFF;
            state <= STATE_MEM;
          end else if (`IS_BEQ) begin
            if (operand1_reg == operand2_reg) begin
              pc_reg <= pc_now_reg + $signed(imm_reg);
            end
            state <= STATE_IF;
          end
        end

        STATE_MEM: begin
          if (`IS_LB && wb_ack_i == 1'b1) begin
            if (wb_ack_i == 1'b1) begin
              rf_writeback_reg <= wb_dat_i >> rdata_shift;
              state <= STATE_WB;
            end
          end else begin // sb, sw
            if (wb_ack_i == 1'b1) begin
              state <= STATE_WB;
            end
          end
        end

        STATE_WB: begin
          state <= STATE_IF;
        end

        default: begin
          state <= STATE_IF;
          pc_reg <= `PC_INIT;
        end
      endcase
    end
  end

endmodule
