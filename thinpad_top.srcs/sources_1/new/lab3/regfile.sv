`default_nettype none

module regfile (
    input wire clk,
    input wire reset,
    input wire [4:0] rf_raddr_a,
    output reg [15:0] rf_rdata_a,
    input wire [4:0] rf_raddr_b,
    output reg [15:0] rf_rdata_b,
    input wire [4:0] rf_waddr,
    input wire [15:0] rf_wdata,
    input wire rf_we
);
reg [15:0] rf [31:0];
always_ff @(posedge clk) begin
    if (reset) begin
        rf[0] <= 16'h0000;
    end else begin
        if ((rf_we == 1) && (rf_waddr != 5'b0)) begin
            rf[rf_waddr] <= rf_wdata;
        end 
    end
end
always_comb begin
    rf_rdata_a = rf[rf_raddr_a];
    rf_rdata_b = rf[rf_raddr_b];
end
endmodule