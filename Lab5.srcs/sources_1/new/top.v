`timescale 1ns / 1ps
module top(clk, btns, swtchs, leds, segs, an);
    input clk;
    input [3:0] btns;
    input [7:0] swtchs;
    
    output [7:0] leds;
    output [6:0] segs;
    output [3:0] an;
    
    //might need to change some of these from wires to regs
    wire cs; //Control signal
    wire we; //Write Enable
    wire[6:0] addr; //SPR
    wire[7:0] data_out_mem; //DVR
    wire[7:0] data_out_ctrl; //DAR
    
    reg[7:0] bus = 0;
    wire[7:0] data_bus;
    assign data_bus = we ? data_out_ctrl : 8'bZ; //(we & data_out_ctrl) | (~we & data_out_mem);
    assign data_bus = ~we ? data_out_mem : 8'bZ;
    
    //CHANGE THESE TWO LINES
    //assign data_bus = we && data_out_ctrl; // 1st driver of the data bus -- tri state switches
    // function of we and data_out_ctrl
    //assign data_bus = data_out_mem; // 2nd driver of the data bus -- tri state switches
    // function of we and data_out_mem
    //assign data_bus = (we & cs & data_out_ctrl) | (~we & data_out_mem);
//    always @ (posedge clk)
//    begin
//        if(we)
//            bus = data_out_ctrl;
//        else
//            bus = data_out_mem;
//    end
    
    //add any other functions you need
    //(e.g. debouncing, multiplexing, clock-division, etc)
    wire [3:0] b_sig;
    debouncer b0(.signal(btns[0]),.clk(clk),.stable(b_sig[0]));
    debouncer b1(.signal(btns[1]),.clk(clk),.stable(b_sig[1]));
    debouncer b2(.signal(btns[2]),.clk(clk),.stable(b_sig[2]));
    debouncer b3(.signal(btns[3]),.clk(clk),.stable(b_sig[3]));
    
    //data_bus = data_in, data_out_ctrl = data_out
    controller ctrl(clk, cs, we, addr, data_bus, data_out_ctrl, b_sig, swtchs, leds, segs, an);
    memory mem(clk, cs, we, addr, data_bus, data_out_mem);
    
    

endmodule




