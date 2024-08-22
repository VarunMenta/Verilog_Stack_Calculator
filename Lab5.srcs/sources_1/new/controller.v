`timescale 1ns / 1ps

module controller(clk, cs, we, addr, data_in, data_out, btns, swtchs, leds, segs, an);
    input clk;
    
    //Fetching and outputting addresses in memory
    output cs;
    output we;
    output[6:0] addr; 
        
    input[7:0] data_in; //from memory the value at address
    output[7:0] data_out;
    
    input[3:0] btns;
    input[7:0] swtchs;
    
    output[7:0] leds;
    output[6:0] segs;
    output[3:0] an;
    //WRITE THE FUNCTION OF THE CONTROLLER
    
    //Single Pulsers
    wire [3:0] b_pulse;
    single_pulser p0(.signal(btns[0]),.clk(clk),.pulse(b_pulse[0]));
    single_pulser p1(.signal(btns[1]),.clk(clk),.pulse(b_pulse[1]));
    assign b_pulse[2] = btns[2];
    assign b_pulse[3] = btns[3];
//    single_pulser p2(.signal(btns[2]),.clk(clk),.pulse(b_pulse[2]));
//    single_pulser p3(.signal(btns[3]),.clk(clk),.pulse(b_pulse[3]));
    
    //Initialization
    reg [6:0] SPR = 7'h7F;
    reg [6:0] DAR = 0;
    reg [7:0] DVR = 0; //Normall initialized to 0
    
    //LED[7] Logic
//    wire isempty;
//    assign isempty = (SPR == 7'h7F);
    
    //Leds Logic
    assign leds[7] = (SPR == 7'h7F);
    assign leds[6] = DAR[6];
    assign leds[5] = DAR[5];
    assign leds[4] = DAR[4];
    assign leds[3] = DAR[3];
    assign leds[2] = DAR[2];
    assign leds[1] = DAR[1];
    assign leds[0] = DAR[0];
    
    //Main State Machine for functions
    reg [3:0] state = 0;
    reg [3:0] next_state = 0;
    
    reg write = 0;
    reg control = 0;
    reg [6:0] address = 0;
    reg [7:0] data_o = 0;
    reg [7:0] temp_top = 0;
    reg [7:0] temp_und = 0;
     
    
    assign we = write;
    assign cs = 1;
    assign addr = address;
    assign data_out = data_o;
    
    
    always @ (posedge clk) begin
        case(state)
        4'b0000: //Wait State 
            begin
                write = 0;
                control = 0;
                address = DAR;
                if(SPR != 127)
                    DVR = data_in;
                else
                    DVR = 0;
                //DAR = SPR + 1;   
                if(b_pulse == 4'b0001)
                //Push
                begin
                    write = 1;
                    control = 1;
                    address = SPR;
                    next_state = 4'b0001;
                    data_o = swtchs;
                end
                
                else if(b_pulse == 4'b0101)
                //Add
                begin
                    write = 0;
                    control = 0;
                    address = SPR + 1;
                    DAR = SPR + 1;
                    next_state = 4'b0011;
                end
                
                else if(b_pulse == 4'b0110)
                //Sub
                begin
                    write = 0;
                    control = 0;
                    address = SPR + 1;
                    DAR = SPR + 1;
                    next_state = 4'b0010;
                end
                
                else if(b_pulse == 4'b0010)
                //Pop
                begin
                    write = 0;
                    control  = 0;
                    SPR = SPR + 1;
                    DAR = SPR + 1;
                    next_state = 0;
                end
                
                else if(b_pulse == 4'b1101)
                //Inc address
                begin
                    DAR = DAR - 1;
                    next_state = 4'b0000;
                end
                
                else if(b_pulse == 4'b1110)
                //Dec address
                begin
                    DAR = DAR + 1;
                    next_state = 4'b0000;
                end
                
                else if(b_pulse == 4'b1010)
                //Clear
                begin
                    SPR = 127;
                    DAR = 0;
                    DVR = 0;
                    next_state = 4'b0000;
                end
                
                else if(b_pulse == 4'b1001)
                //Top
                begin
                    DAR = SPR + 1;
                    next_state = 4'b0000;
                end
                
                else
                    next_state = 4'b0000;
            end
            
         4'b0001: //Push State
         begin
            //data_o = swtchs;
            DAR = SPR;
            SPR = SPR - 1;          
            next_state = 4'b0111;
         end
         
         4'b0011: //Retrieve 1 State - Add
         begin
            temp_top = data_in;
            address = SPR + 2;
            DAR = SPR + 2;
            next_state = 4'b0100;                       
         end
         
         4'b0100: //Retrieve 2 State - Add
         begin
            temp_und = data_in;
            data_o = temp_und + temp_top;
            SPR = SPR + 1;
            DAR = SPR + 1;
            write = 1;   
            next_state = 4'b0111;
         end
         
         4'b0010: //Retrieve 1 State - Sub
         begin
            temp_top = data_in;
            address = SPR + 2;
            DAR = SPR + 2;
            next_state = 4'b0101;
         end
                  
         4'b0101: //Retrieve 2 State - Sub
         begin
            temp_und = data_in;
            data_o = temp_top - temp_und;
            SPR = SPR + 1;
            DAR = SPR + 1;
            write = 1;
            next_state = 4'b0111;
         end
         
         4'b0110: 
         begin
            next_state = 4'b0000;
         end
         4'b0111: //limbo
         begin
            next_state = 4'b0000;
         end
         
         default: //Defaulting to the wait state
         begin
            write = 0;
            control = 0;
            DVR = data_in;
            next_state = 0;
         end
        endcase
    
    end
   
        //FSM Driver
     always @(posedge clk) begin
         state <= next_state;
      end
     
    //Display Logic
    reg [3:0] b3 = 0;
    reg [3:0] b2 = 0;
    reg [3:0] b1 = 0;
    reg [3:0] b0 = 0;
    
    always @ (posedge clk)
    begin
        begin
            b3 = (DVR / 1000) % 10;
            b2 = (DVR / 100) % 10;
            b1 = (DVR / 10) % 10;
            b0 = (DVR) % 10; 
        end
    end
    
    wire [6:0] c3,c2,c1,c0;
    
    hexto7segment a3(.x(b3),.r(c3));
    hexto7segment a4(.x(b2),.r(c2));
    hexto7segment a5(.x(b1),.r(c1));
    hexto7segment a6(.x(b0),.r(c0));
    
    wire slow_clk;
    wire reset;
    display_clk a7(.clk(clk),.reset(reset),.slow_clk(slow_clk));
    
    wire dec;
    time_mux_state_machine a2(.clk(slow_clk),.reset(reset),.in0(c0),.in1(c1),.in2(c2),.in3(c3),.an(an),.sseg(segs),.dec(dec));
     
endmodule

module memory(clock, cs, we, addr, data_in, data_out);
    input clock;
    input cs;
    input we;
    input[6:0] addr;
    input[7:0] data_in;
    
    output[7:0] data_out;
    
    reg[7:0] data_out;
    reg[7:0] RAM[127:0];
        
    always @ (negedge clock)
        begin
            if((we == 1) && (cs == 1))
                RAM[addr] <= data_in;//data_in[7:0];
            data_out <= RAM[addr];
        end
endmodule
