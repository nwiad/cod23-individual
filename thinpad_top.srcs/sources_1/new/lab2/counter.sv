`default_nettype none
module counter(
    input wire clk,
    input wire reset,
    input wire trigger,
    output logic [3:0] count
);
reg [3:0] count_reg;
always_ff @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        count_reg <= 4'd0;
    end
    else 
    begin
        if (trigger && count != 4'd15)
        begin
            count_reg <= count + 4'd1;
        end
    end
end
assign count = count_reg;
endmodule