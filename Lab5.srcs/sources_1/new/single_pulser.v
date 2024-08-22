`timescale 1ns / 1ps


module single_pulser(
    input signal, clk,
    output pulse
    );
    
    reg not_u = 1;
    assign pulse = signal && not_u;
    
    always @ (posedge clk)
    begin
        not_u <= !signal;
    end
endmodule
