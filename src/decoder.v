
// Instructions
parameter C_NOP      = 3'd0;
parameter C_LINE     = 3'd1;
parameter C_INCR     = 3'd2;
parameter C_DCRE     = 3'd3; 
parameter C_JUMP     = 3'd4;
parameter C_X_RECT   = 3'd5;
parameter C_Y_RECT   = 3'd6;

// Meta
parameter PARAM_SIZE = 8;
parameter INSTRUCTION_COUNT = 8;
parameter MAX_INSTRUCTIONS = 8'd7;

module triangle_wave_gen_fsm (
    input clk,
    input reset, // Active high reset
    input enable,
    input [(INSTRUCTION_COUNT*3)-1:0] instructions_flat,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_a,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_b,
    output [7:0] dac_out
);

    reg [7:0] counter;
    reg [4:0] logic_state;
    reg [2:0] action_state;
    reg cycle_flag; // 0 for action cycle, 1 for check cycle
    reg done_op;
    
    
    // Annoying verilog formatting
    wire [2:0] instructions[INSTRUCTION_COUNT-1:0];
    wire [7:0] params_a[INSTRUCTION_COUNT-1:0];
    wire [7:0] params_b[INSTRUCTION_COUNT-1:0];
    reg [7:0] param_counter;
    reg [INSTRUCTION_COUNT-1:0] instruction_pointer;

    // Constants for clarity
    parameter MAX_COUNTER_VALUE = 8'd255;  // Maximum value for 8-bit up count in decimal
    parameter MIN_COUNTER_VALUE = 8'd0;    // Minimum value for 8-bit down count in decimal
    parameter BOUNCE_VALUE      = 8'd128;

    // Action states
    parameter UP   = 2'b00;
    parameter DOWN = 2'b01;
    parameter HOLD = 2'b10;
    parameter JUMP = 2'b11;
    
    // Logic states
    parameter L_INIT   = 4'd0;
    parameter L_ONE    = 4'd1;
    parameter L_TWO    = 4'd2;
    parameter L_THREE  = 4'd3;
    parameter L_FOUR   = 4'd4;
    parameter L_NOP    = 4'd15;

    genvar i;
    generate
        for (i = 0; i < INSTRUCTION_COUNT; i = i + 1) begin
            assign instructions[i] = instructions_flat[i*3 +: 3];
            assign params_a[i] = params_flat_a[i*PARAM_SIZE +: PARAM_SIZE];
            assign params_b[i] = params_flat_b[i*PARAM_SIZE +: PARAM_SIZE];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset || !enable) begin
            action_state <= UP;
            logic_state = L_INIT;
            cycle_flag = 1'b0;
            done_op    = 1'b0;
            instruction_pointer = 8'd0;
            param_counter = 8'd0;
        end else if (cycle_flag == 0) begin // Action cycle
            case (action_state)
                UP: counter = counter + 8'd1;
                DOWN: counter = counter - 8'd1;
                HOLD: counter = counter;
            endcase
            param_counter = param_counter + 8'd1; // Used by instructions to check when to finish
            cycle_flag = 1; // Switch to check cycle
        end else begin // Check cycle
            
            // Here we will pick an instruction to execture
            case (instructions[instruction_pointer])
                C_NOP: begin
                    action_state <= HOLD;
                    done_op = 1'b1;
                end
                C_LINE: begin
                    case (logic_state)
                        L_INIT: begin
                            if (params_a[instruction_pointer] > params_b[instruction_pointer]) begin
                                action_state <= UP;
                            end else begin
                                action_state <= DOWN;
                            end
                            counter = params_a[instruction_pointer];
                            logic_state = L_ONE;
                            param_counter = 8'd0;
                        end
                        L_ONE: begin
                            if (param_counter == params_b[instruction_pointer])
                            begin
                                //logic_state = L_NOP;
                                action_state <= HOLD;
                                done_op = 1'b1;
                            end
                        end
                    endcase
                end
                C_JUMP: begin
                    action_state <= HOLD;
                    counter = params_a[instruction_pointer];
                    done_op = 1'b1;
                end
                C_INCR: begin
                    action_state <= UP;
                    if (param_counter == params_a[instruction_pointer])
                        done_op = 1'b1;
                end
                C_DCRE: begin
                    action_state <= DOWN;
                    if (param_counter == params_a[instruction_pointer])
                        done_op = 1'b1;
                end
                C_X_RECT: begin
                    case (logic_state)
                        L_INIT: begin
                            action_state <= UP;
                            if (param_counter == params_a[instruction_pointer]) begin
                                logic_state = L_ONE;
                                param_counter = 4'd0;
                            end
                        end
                        L_ONE: begin
                            action_state <= HOLD;
                            if (param_counter == params_b[instruction_pointer]) begin
                                logic_state = L_TWO;
                                param_counter = 4'd0;
                            end
                        end
                        L_TWO: begin
                            action_state <= DOWN;
                            if (param_counter == params_a[instruction_pointer]) begin
                                logic_state = L_THREE;
                                param_counter = 4'd0;
                            end
                        end
                        L_THREE: begin
                            action_state <= HOLD;
                            if (param_counter == params_b[instruction_pointer]) begin
                                logic_state = L_NOP;
                                param_counter = 4'd0;
                                done_op = 1'b1;
                            end
                        end
                    endcase
                end
                C_Y_RECT: begin
                    case (logic_state)
                        L_INIT: begin
                            action_state <= HOLD;
                            if (param_counter == params_a[instruction_pointer]) begin
                                logic_state = L_ONE;
                                param_counter = 4'd0;
                            end
                        end
                        L_ONE: begin
                            action_state <= UP;
                            if (param_counter == params_b[instruction_pointer]) begin
                                logic_state = L_TWO;
                                param_counter = 4'd0;
                            end
                        end
                        L_TWO: begin
                            action_state <= HOLD;
                            if (param_counter == params_a[instruction_pointer]) begin
                                logic_state = L_THREE;
                                param_counter = 4'd0;
                            end
                        end
                        L_THREE: begin
                            action_state <= DOWN;
                            if (param_counter == params_b[instruction_pointer]) begin
                                logic_state = L_NOP;
                                param_counter = 4'd0;
                                done_op = 1'b1;
                            end
                        end
                    endcase
                end
            endcase       
    
            // Check if this instruction is done
            if (done_op == 1'b1) begin
//                if (instruction_pointer == MAX_INSTRUCTIONS) instruction_pointer = 3'd0;
//                else instruction_pointer = instruction_pointer + 8'd1;

                instruction_pointer = instruction_pointer + 8'd1; // Loops
                param_counter = 8'd0;
                logic_state = L_INIT;

                done_op = 1'b0;
            end
            cycle_flag = 0; // Switch back to action cycle
        end
    end

    assign dac_out = counter;

endmodule

module triangle_wave_gen_fsm_comb (
    input clk,
    input reset, 
    input enable,
    input [(INSTRUCTION_COUNT*3)-1:0] instructions_flat,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_a,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_b,
    output reg [7:0] dac_out
);

    reg [7:0] counter;
    reg [7:0] next_counter;
    reg [4:0] logic_state, next_logic_state;
    reg [2:0] action_state, next_action_state;
    reg cycle_flag, next_cycle_flag; 
    reg done_op, next_done_op;
    
    wire [2:0] instructions[INSTRUCTION_COUNT-1:0];
    wire [7:0] params_a[INSTRUCTION_COUNT-1:0];
    wire [7:0] params_b[INSTRUCTION_COUNT-1:0];
    reg [7:0] param_counter, next_param_counter;
    reg [INSTRUCTION_COUNT-1:0] instruction_pointer, next_instruction_pointer;
    
    // Constants for clarity
    parameter MAX_COUNTER_VALUE = 8'd255;  // Maximum value for 8-bit up count in decimal
    parameter MIN_COUNTER_VALUE = 8'd0;    // Minimum value for 8-bit down count in decimal
    parameter BOUNCE_VALUE      = 8'd128;

    // Action states
    parameter UP   = 2'b00;
    parameter DOWN = 2'b01;
    parameter HOLD = 2'b10;
    parameter JUMP = 2'b11;
    
    // Logic states
    parameter L_INIT   = 4'd0;
    parameter L_ONE    = 4'd1;
    parameter L_TWO    = 4'd2;
    parameter L_THREE  = 4'd3;
    parameter L_FOUR   = 4'd4;
    parameter L_NOP    = 4'd15;

    genvar i;
    generate
        for (i = 0; i < INSTRUCTION_COUNT; i = i + 1) begin
            assign instructions[i] = instructions_flat[i*3 +: 3];
            assign params_a[i] = params_flat_a[i*PARAM_SIZE +: PARAM_SIZE];
            assign params_b[i] = params_flat_b[i*PARAM_SIZE +: PARAM_SIZE];
        end
    endgenerate

    // Combinatorial Logic
    always @(posedge clk) begin

        // The previous FSM logic goes here, but with "next_" prefixes for all state variables.
        // I'm condensing this for brevity, but essentially you'll adapt the original FSM to this section.
        // You would replace direct assignments to action_state, logic_state, etc., with assignments
        // to next_action_state, next_logic_state, etc.

        // For example, this:
        // if (reset) action_state = UP;
        // would become:
        // if (reset) next_action_state = UP;

        // ... [rest of the FSM logic from your original code, adapted with the next_ prefix for state variables]
         if (cycle_flag == 0) begin // State cycle
             if (reset) begin
                action_state <= UP;
                logic_state <= L_INIT;
                cycle_flag <= 1'b0;
                done_op <= 1'b0;
                instruction_pointer <= 8'd0;
                param_counter <= 8'd0;
                counter <= 8'd0;
                dac_out <= 8'd0;
            end else if (enable) begin
                action_state <= next_action_state;
                logic_state <= next_logic_state;
                //cycle_flag <= next_cycle_flag;
                done_op <= next_done_op;
                instruction_pointer <= next_instruction_pointer;
                param_counter <= next_param_counter;
                counter <= next_counter;
                dac_out <= counter;
            end

            cycle_flag = 1; // Switch to check cycle
        end else begin // Check cycle
            next_action_state = action_state;
            next_logic_state = logic_state;
            next_cycle_flag = cycle_flag;
            next_done_op = done_op;
            next_instruction_pointer = instruction_pointer;
            next_param_counter = param_counter;
            next_counter = counter;

            case (action_state)
              UP: next_counter = counter + 8'd1;
                DOWN: next_counter = counter - 8'd1;
                HOLD: next_counter = counter;
            endcase
            next_param_counter = param_counter + 8'd1; // Used by instructions to check when to finish
            // Here we will pick an instruction to execture
            case (instructions[instruction_pointer])
                C_NOP: begin
                    next_action_state = HOLD;
                    next_done_op = 1'b1;
                end
                C_LINE: begin
                    case (logic_state)
                        L_INIT: begin
                            if (params_a[instruction_pointer] > params_b[instruction_pointer]) begin
                                next_action_state = UP;
                            end else begin
                                next_action_state = DOWN;
                            end
                            next_counter = params_a[instruction_pointer];
                            next_logic_state = L_ONE;
                            next_param_counter = 8'd0;
                        end
                        L_ONE: begin
                            if (param_counter == params_b[instruction_pointer])
                            begin
                                //logic_state = L_NOP;
                                next_action_state = HOLD;
                                next_done_op = 1'b1;
                            end
                        end
                    endcase
                end
                C_JUMP: begin
                    next_action_state = HOLD;
                    next_counter = params_a[instruction_pointer];
                    next_done_op = 1'b1;
                end
                C_INCR: begin
                    next_action_state = UP;
                    if (param_counter == params_a[instruction_pointer])
                        next_done_op = 1'b1;
                end
                C_DCRE: begin
                    next_action_state = DOWN;
                    if (param_counter == params_a[instruction_pointer])
                        next_done_op = 1'b1;
                end
                C_X_RECT: begin
                    case (logic_state)
                        L_INIT: begin
                            next_action_state = UP;
                            if (param_counter == params_a[instruction_pointer]) begin
                                next_logic_state = L_ONE;
                                next_param_counter = 4'd0;
                            end
                        end
                        L_ONE: begin
                            next_action_state = HOLD;
                            if (param_counter == params_b[instruction_pointer]) begin
                                next_logic_state = L_TWO;
                                next_param_counter = 4'd0;
                            end
                        end
                        L_TWO: begin
                            next_action_state = DOWN;
                            if (param_counter == params_a[instruction_pointer]) begin
                                next_logic_state = L_THREE;
                                next_param_counter = 4'd0;
                            end
                        end
                        L_THREE: begin
                            next_action_state = HOLD;
                            if (param_counter == params_b[instruction_pointer]) begin
                                next_logic_state = L_NOP;
                                next_param_counter = 4'd0;
                                next_done_op = 1'b1;
                            end
                        end
                    endcase
                end
                C_Y_RECT: begin
                    case (logic_state)
                        L_INIT: begin
                            next_action_state = HOLD;
                            if (param_counter == params_a[instruction_pointer]) begin
                                next_logic_state = L_ONE;
                                next_param_counter = 4'd0;
                            end
                        end
                        L_ONE: begin
                            next_action_state = UP;
                            if (param_counter == params_b[instruction_pointer]) begin
                                next_logic_state = L_TWO;
                                next_param_counter = 4'd0;
                            end
                        end
                        L_TWO: begin
                            next_action_state = HOLD;
                            if (param_counter == params_a[instruction_pointer]) begin
                                next_logic_state = L_THREE;
                                next_param_counter = 4'd0;
                            end
                        end
                        L_THREE: begin
                            next_action_state = DOWN;
                            if (param_counter == params_b[instruction_pointer]) begin
                                next_logic_state = L_NOP;
                                next_param_counter = 4'd0;
                                next_done_op = 1'b1;
                            end
                        end
                    endcase
                end
            endcase       
    
            // Check if this instruction is done
            if (done_op == 1'b1) begin
//                if (instruction_pointer == MAX_INSTRUCTIONS) instruction_pointer = 3'd0;
//                else instruction_pointer = instruction_pointer + 8'd1;

                next_instruction_pointer = instruction_pointer + 8'd1; // Loops
                next_param_counter = 8'd0;
                next_logic_state = L_INIT;

                next_done_op = 1'b0;
            end
            cycle_flag = 0; // Switch back to action cycle
        end
    end
endmodule



// RX code from fpga4fun.com, all credit to them!! :) :) THANKS GUYS
////////////////////////////////////////////////////////
module async_receiver(
	input clk,
	input RxD,
	output reg RxD_data_ready = 0,
	output reg [7:0] RxD_data = 0,  // data received, valid only (for one clock cycle) when RxD_data_ready is asserted

	// We also detect if a gap occurs in the received stream of characters
	// That can be useful if multiple characters are sent in burst
	//  so that multiple characters can be treated as a "packet"
	output RxD_idle,  // asserted when no data has been received for a while
	output reg RxD_endofpacket = 0  // asserted for one clock cycle when a packet has been detected (i.e. RxD_idle is going high)
);

parameter ClkFrequency = 10000000; // 10MHz
parameter Baud = 115200;

parameter Oversampling = 8;  // needs to be a power of 2
// we oversample the RxD line at a fixed rate to capture each RxD data bit at the "right" time
// 8 times oversampling by default, use 16 for higher quality reception

////////////////////////////////
reg [3:0] RxD_state = 0;

`ifdef SIMULATION
wire RxD_bit = RxD;
wire sampleNow = 1'b1;  // receive one bit per clock cycle

`else
wire OversamplingTick;
BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen(.clk(clk), .enable(1'b1), .tick(OversamplingTick));

// synchronize RxD to our clk domain
reg [1:0] RxD_sync = 2'b11;
always @(posedge clk) if(OversamplingTick) RxD_sync <= {RxD_sync[0], RxD};

// and filter it
reg [1:0] Filter_cnt = 2'b11;
reg RxD_bit = 1'b1;

always @(posedge clk)
if(OversamplingTick)
begin
	if(RxD_sync[1]==1'b1 && Filter_cnt!=2'b11) Filter_cnt <= Filter_cnt + 1'd1;
	else 
	if(RxD_sync[1]==1'b0 && Filter_cnt!=2'b00) Filter_cnt <= Filter_cnt - 1'd1;

	if(Filter_cnt==2'b11) RxD_bit <= 1'b1;
	else
	if(Filter_cnt==2'b00) RxD_bit <= 1'b0;
end

// and decide when is the good time to sample the RxD line
function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
localparam l2o = log2(Oversampling);
reg [l2o-2:0] OversamplingCnt = 0;
always @(posedge clk) if(OversamplingTick) OversamplingCnt <= (RxD_state==0) ? 1'd0 : OversamplingCnt + 1'd1;
wire sampleNow = OversamplingTick && (OversamplingCnt==Oversampling/2-1);
`endif

// now we can accumulate the RxD bits in a shift-register
always @(posedge clk)
case(RxD_state)
	4'b0000: if(~RxD_bit) RxD_state <= `ifdef SIMULATION 4'b1000 `else 4'b0001 `endif;  // start bit found?
	4'b0001: if(sampleNow) RxD_state <= 4'b1000;  // sync start bit to sampleNow
	4'b1000: if(sampleNow) RxD_state <= 4'b1001;  // bit 0
	4'b1001: if(sampleNow) RxD_state <= 4'b1010;  // bit 1
	4'b1010: if(sampleNow) RxD_state <= 4'b1011;  // bit 2
	4'b1011: if(sampleNow) RxD_state <= 4'b1100;  // bit 3
	4'b1100: if(sampleNow) RxD_state <= 4'b1101;  // bit 4
	4'b1101: if(sampleNow) RxD_state <= 4'b1110;  // bit 5
	4'b1110: if(sampleNow) RxD_state <= 4'b1111;  // bit 6
	4'b1111: if(sampleNow) RxD_state <= 4'b0010;  // bit 7
	4'b0010: if(sampleNow) RxD_state <= 4'b0000;  // stop bit
	default: RxD_state <= 4'b0000;
endcase

always @(posedge clk)
if(sampleNow && RxD_state[3]) RxD_data <= {RxD_bit, RxD_data[7:1]};

//reg RxD_data_error = 0;
always @(posedge clk)
begin
	RxD_data_ready <= (sampleNow && RxD_state==4'b0010 && RxD_bit);  // make sure a stop bit is received
	//RxD_data_error <= (sampleNow && RxD_state==4'b0010 && ~RxD_bit);  // error if a stop bit is not received
end

`ifdef SIMULATION
assign RxD_idle = 0;
`else
reg [l2o+1:0] GapCnt = 0;
always @(posedge clk) if (RxD_state!=0) GapCnt<=0; else if(OversamplingTick & ~GapCnt[log2(Oversampling)+1]) GapCnt <= GapCnt + 1'h1;
assign RxD_idle = GapCnt[l2o+1];
always @(posedge clk) RxD_endofpacket <= OversamplingTick & ~GapCnt[l2o+1] & &GapCnt[l2o:0];
`endif

endmodule


////////////////////////////////////////////////////////
// dummy module used to be able to raise an assertion in Verilog
module ASSERTION_ERROR();
endmodule


////////////////////////////////////////////////////////
module BaudTickGen(
	input clk, enable,
	output tick  // generate a tick at the specified baud rate * oversampling
);
parameter ClkFrequency = 10000000;
parameter Baud = 115200;
parameter Oversampling = 1;

function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
localparam AccWidth = log2(ClkFrequency/Baud)+8;  // +/- 2% max timing error over a byte
reg [AccWidth:0] Acc = 0;
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));  // this makes sure Inc calculation doesn't overflow
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);
always @(posedge clk) if(enable) Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0]; else Acc <= Inc[AccWidth:0];
assign tick = Acc[AccWidth];
endmodule


module image_wave_gen (
    input clk,
    input reset, // Active high reset
    input [7:0]uart_rx,
    output [7:0] xdac,
    output [7:0] ydac
);

    reg [(INSTRUCTION_COUNT*3)-1:0] x_instructions_flat;
    reg [(INSTRUCTION_COUNT*8)-1:0] x_params_a_flat;
    reg [(INSTRUCTION_COUNT*8)-1:0] x_params_b_flat;
        
    reg [(INSTRUCTION_COUNT*3)-1:0] y_instructions_flat;
    reg [(INSTRUCTION_COUNT*8)-1:0] y_params_a_flat;
    reg [(INSTRUCTION_COUNT*8)-1:0] y_params_b_flat;
    reg enable = 0;
    
    
    
    // DONT ASSUME IT'LL START FROM 0 LIKE ON THE FPGA
    always @(posedge clk) begin
        x_instructions_flat   = {C_X_RECT, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_JUMP};
        x_params_a_flat       = {8'd100,   8'd150, 8'd75,    8'd100, uart_rx,   8'd030, 8'd90, 8'd000};
        x_params_b_flat       = {8'd100,   8'd150, 8'd75,    8'd100, uart_rx,   8'd030, 8'd90, 8'd000};
        
        y_instructions_flat   = {C_Y_RECT, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_JUMP};
        y_params_a_flat       = {8'd100,   8'd150, 8'd75,    8'd020, uart_rx,   8'd000, 8'd90, 8'd000};
        y_params_b_flat       = {8'd100,   8'd150, 8'd75,    8'd020, uart_rx,   8'd000, 8'd90, 8'd000};
        enable = 1;
    end

    
    triangle_wave_gen_fsm_comb triangle1 (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .instructions_flat(x_instructions_flat),
        .params_flat_a(x_params_a_flat),
        .params_flat_b(x_params_b_flat),
        .dac_out(xdac)
    );
    
    triangle_wave_gen_fsm_comb triangle2 (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .instructions_flat(y_instructions_flat),
        .params_flat_a(y_params_a_flat),
        .params_flat_b(y_params_b_flat),
        .dac_out(ydac)
    );


endmodule
