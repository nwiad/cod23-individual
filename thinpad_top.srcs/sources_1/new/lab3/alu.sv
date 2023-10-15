`default_nettype none

module alu (
    input wire [15:0] alu_a,
    input wire [15:0] alu_b,
    input wire [3:0] alu_op,
    output reg [15:0] alu_y
);
always_comb begin
    case (alu_op)
        4'b0001: alu_y = alu_a + alu_b;
        4'b0010: alu_y = alu_a - alu_b;
        4'b0011: alu_y = alu_a & alu_b;
        4'b0100: alu_y = alu_a | alu_b;
        4'b0101: alu_y = alu_a ^ alu_b;
        4'b0110: alu_y = ~alu_a;
        4'b0111: alu_y = alu_a << (alu_b & 16'hF);
        4'b1000: alu_y = alu_a >> (alu_b & 16'hF);
        4'b1001: alu_y = $signed(alu_a) >>> (alu_b & 16'hF);
        4'b1010: alu_y = (alu_a << (alu_b & 16'hF)) | (alu_a >> (16'h0010 - (alu_b & 16'hF)));
        default: alu_y = 16'b0;
    endcase
end
endmodule