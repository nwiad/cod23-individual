module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加需要的控制信号，例如按键开关？
    input wire [ADDR_WIDTH-1:0] dip_sw_i,

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

  // TODO: 实现实验 5 的内存+串口 Master
  typedef enum logic [3:0] { 
    IDLE = 0,
    READ_WAIT_ACTION = 1,
    READ_WAIT_CHECK = 2,
    READ_DATA_ACTION = 3,
    READ_DATA_DONE = 4,
    WRITE_SRAM_ACTION = 5,
    WRITE_SRAM_DONE = 6,
    WRITE_WAIT_ACTION = 7,
    WRITE_WAIT_CHECK = 8,
    WRITE_DATA_ACTION = 9,
    WRITE_DATA_DONE = 10
  } state_t;
  state_t state;
  reg [ADDR_WIDTH-1:0] addr;
  reg [DATA_WIDTH-1:0] data;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      addr <= dip_sw_i & 32'hFFFF_FFFC;
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_adr_o <= 32'h1000_0005;
      wb_dat_o <= 32'h0000_0000;
      wb_sel_o <= 4'b0000;
      wb_we_o <= 1'b0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          wb_cyc_o <= 1'b1;
          wb_stb_o <= 1'b1;
          wb_adr_o <= 32'h1000_0005;
          // 不关心wb_dat_o
          wb_sel_o <= 4'b0010; // 左移1位
          wb_we_o <= 1'b0;
          state <= READ_WAIT_ACTION;
        end

        READ_WAIT_ACTION: begin
          if (wb_ack_i == 1'b1) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            state <= READ_WAIT_CHECK;
          end
        end

        READ_WAIT_CHECK: begin
          if (wb_dat_i[8] == 1'b1) begin
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= 32'h1000_0000;
            // 不关心wb_dat_o
            wb_sel_o <= 4'b0001; // 不需要左移
            wb_we_o <= 1'b0;
            state <= READ_DATA_ACTION;
          end else begin
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= 32'h1000_0005;
            // 不关心wb_dat_o
            wb_sel_o <= 4'b0010; // 左移1位
            wb_we_o <= 1'b0;
            state <= READ_WAIT_ACTION;
          end
        end

        READ_DATA_ACTION: begin
          if (wb_ack_i == 1'b1) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            state <= READ_DATA_DONE;
          end
        end

        READ_DATA_DONE: begin
          wb_cyc_o <= 1'b1;
          wb_stb_o <= 1'b1;
          wb_adr_o <= addr;
          wb_dat_o <= wb_dat_i << (addr[1:0] << 3); // 左移
          data <= wb_dat_i;
          wb_sel_o <= 4'b0001 << (addr[1:0]); // 左移
          wb_we_o <= 1'b1;
          state <= WRITE_SRAM_ACTION;
        end

        WRITE_SRAM_ACTION: begin
          if (wb_ack_i == 1'b1) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_we_o <= 1'b0;
            state <= WRITE_SRAM_DONE;
          end
        end

        WRITE_SRAM_DONE: begin
          wb_cyc_o <= 1'b1;
          wb_stb_o <= 1'b1;
          wb_adr_o <= 32'h1000_0005;
          // 不关心wb_dat_o
          wb_sel_o <= 4'b0010; // 左移1位
          wb_we_o <= 1'b0;
          state <= WRITE_WAIT_ACTION;
        end

        WRITE_WAIT_ACTION: begin
          if (wb_ack_i == 1'b1) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            state <= WRITE_WAIT_CHECK;
          end
        end

        WRITE_WAIT_CHECK: begin
          if (wb_dat_i[13] == 1'b1) begin
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= 32'h1000_0000;
            wb_dat_o <= data; // 不需要左移
            wb_sel_o <= 4'b0001; // 不需要左移
            wb_we_o <= 1'b1;
            state <= WRITE_DATA_ACTION;
          end else begin
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= 32'h1000_0005;
            // 不关心wb_dat_o
            wb_sel_o <= 4'b0010; // 左移1位
            wb_we_o <= 1'b0;
            state <= WRITE_WAIT_ACTION;
          end
        end

        WRITE_DATA_ACTION: begin
          if (wb_ack_i == 1'b1) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_we_o <= 1'b0;
            state <= WRITE_DATA_DONE;
          end
        end

        WRITE_DATA_DONE: begin
          addr <= addr + 32'h0000_0004;
          state <= IDLE;
        end

        default: begin
          wb_cyc_o <= 1'b0;
          wb_stb_o <= 1'b0;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
