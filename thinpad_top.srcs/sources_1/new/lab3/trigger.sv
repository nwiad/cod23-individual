`default_nettype none
module trigger(
    input wire clk,
    input wire reset,
    input wire push_btn,
    output logic trigger
);
reg push_btn_reg = push_btn;
always_ff @(posedge clk)
begin
    push_btn_reg <= push_btn;
    if (reset)
    begin
        trigger <= 1'b0;
    end
    else
    begin
        if (push_btn && !push_btn_reg) 
        begin
            trigger <= 1'b1;
        end
        else
        begin
            trigger <= 1'b0;
        end
    end
end
endmodule