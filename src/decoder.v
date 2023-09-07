

// Instructions
parameter C_NOP      = 3'd0;
parameter C_LINE     = 3'd1;
parameter C_INCR     = 3'd2;
parameter C_DCRE     = 3'd3; 
parameter C_JUMP     = 3'd4;
parameter C_X_RECT   = 3'd5;
parameter C_Y_RECT   = 3'd6;
parameter C_LINE_D   = 3'd7;

// Meta
parameter PARAM_SIZE = 8;
parameter INSTRUCTION_COUNT = 16;
parameter MAX_INSTRUCTIONS = 8'd15;


module triangle_wave_gen_fsm_comb (
    input clk,
    input reset, 
    input enable,
    input ack,
    input [(INSTRUCTION_COUNT*3)-1:0] instructions_flat,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_a,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_b,
    input [(INSTRUCTION_COUNT*8)-1:0] params_flat_c,
    output reg [7:0] dac_out,
    output reg done_out
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
    wire [7:0] params_c[INSTRUCTION_COUNT-1:0];
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
            assign params_c[i] = params_flat_c[i*PARAM_SIZE +: PARAM_SIZE];
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
                cycle_flag = 1'b0;
                done_op <= 1'b0;
                done_out <= 1'b0;
                instruction_pointer <= 8'd0;
                param_counter <= 8'd0;
                counter <= 8'd0;
                dac_out <= 8'd0;
            end else begin
                action_state <= next_action_state;
                logic_state <= next_logic_state;
                //cycle_flag <= next_cycle_flag;
                done_op <= next_done_op;
                done_out <= next_done_op;
                instruction_pointer <= next_instruction_pointer;
                param_counter <= next_param_counter;
                counter <= next_counter;
                dac_out <= counter;
            end

            cycle_flag = 1; // Switch to check cycle
        end else if (enable) begin // Check cycle
            next_action_state = action_state;
            next_logic_state = logic_state;
            next_cycle_flag = cycle_flag;
            next_done_op = done_op;
            next_instruction_pointer = instruction_pointer;
            next_param_counter = param_counter;
            next_counter = counter;

            case (action_state)
                UP: next_counter = counter + params_c[instruction_pointer];
                DOWN: next_counter = counter - params_c[instruction_pointer];
                HOLD: next_counter = counter;
            endcase
            next_param_counter = param_counter + 8'd1; // Used by instructions to check when to finish
            // Here we will pick an instruction to execture
            if (done_op == 1'b0) begin
                case (instructions[instruction_pointer])
                    C_NOP: begin
                        next_action_state = HOLD;
                        next_done_op = 1'b1;
                    end
                    C_LINE: begin
                        case (logic_state)
                            L_INIT: begin
                                next_action_state = UP;
                                next_counter = params_a[instruction_pointer];
                                next_logic_state = L_ONE;
                                next_param_counter = 8'd0;
                            end
                            L_ONE: begin                      
                                if (param_counter == params_b[instruction_pointer]) begin
                                    //logic_state = L_NOP;
                                    next_action_state = HOLD;
                                    next_done_op = 1'b1;
                                end
                            end
                        endcase
                    end
                    C_LINE_D: begin
                        case (logic_state)
                            L_INIT: begin
                                next_action_state = DOWN;
                                next_counter = params_a[instruction_pointer];
                                next_logic_state = L_ONE;
                                next_param_counter = 8'd0;
                            end
                            L_ONE: begin                      
                                if (param_counter == params_b[instruction_pointer]) begin
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
           end else begin
            // Check if this instruction is done
            
//                if (instruction_pointer == MAX_INSTRUCTIONS) instruction_pointer = 3'd0;
//                else instruction_pointer = instruction_pointer + 8'd1;
               
                next_param_counter = 8'd0;
                next_logic_state = L_INIT;
                next_action_state = HOLD;
            
                if (ack) begin
                     next_instruction_pointer = instruction_pointer + 8'd1; // Loops
                     next_done_op = 1'b0;
                end
            end
            cycle_flag = 0; // Switch back to action cycle
        end
    end
endmodule



// RX code from fpga4fun.com, all credit to them!! :) :) Permission for use in tiny tapeout given over email
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
parameter Baud = 921600;

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
parameter Baud = 921600;
parameter Oversampling = 8;

function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
localparam AccWidth = log2(ClkFrequency/Baud)+8;  // +/- 2% max timing error over a byte
reg [AccWidth:0] Acc = 0;
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));  // this makes sure Inc calculation doesn't overflow
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);
always @(posedge clk) if(enable) Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0]; else Acc <= Inc[AccWidth:0];
assign tick = Acc[AccWidth];
endmodule


module instruction_reader(
    input clk,
    input reset,
    input uart_rx_wire,
    output reg [(INSTRUCTION_COUNT*3)-1:0] x_instructions_flat,
    output reg [(INSTRUCTION_COUNT*8)-1:0] x_params_a_flat,
    output reg [(INSTRUCTION_COUNT*8)-1:0] x_params_b_flat,
    output reg [(INSTRUCTION_COUNT*8)-1:0] x_params_c_flat,
    output reg [(INSTRUCTION_COUNT*3)-1:0] y_instructions_flat,
    output reg [(INSTRUCTION_COUNT*8)-1:0] y_params_a_flat,
    output reg [(INSTRUCTION_COUNT*8)-1:0] y_params_b_flat,
    output reg [(INSTRUCTION_COUNT*8)-1:0] y_params_c_flat,
    output reg data_valid
);

    // FSM states
    parameter IDLE = 2'd0;
    parameter TYPE_DETECTION = 2'd1;
    parameter DATA_RECEIVE = 2'd2;
    parameter END_DETECTION = 2'd3;
    
    // Instantiate UART RX module
    wire rx_data_ready;
    wire [7:0]rx_data_r;
    reg [7:0]rx_data_out;
    reg idle, eop;
    
    always @(posedge clk) begin
        if (reset)
            rx_data_out <= 8'd0;
        else if (rx_data_ready)
            rx_data_out <= rx_data_r;
    end
    
    async_receiver uart_rx_m(
        .clk(clk),
        .RxD(uart_rx_wire),
        .RxD_data_ready(rx_data_ready),
        .RxD_data(rx_data_r),
        .RxD_idle(idle),
        .RxD_endofpacket(eop)
    );
    
    reg [1:0] current_state, next_state;
    reg [2:0] data_type;
    reg [7:0] byte_count;
    reg RxD_endofpacket;
    
    // FSM logic
    always @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            byte_count <= 8'd0;
            RxD_endofpacket <= 1'b0;
            data_valid <= 1'd0;
        end else begin
            current_state <= next_state;
            if (rx_data_ready) begin
                case (current_state)
                    IDLE: begin
                        if (rx_data_out == 8'hAA) 
                            next_state <= TYPE_DETECTION;
                        else
                            next_state <= IDLE;
                    end
                    TYPE_DETECTION: begin
                        data_type <= rx_data_out[2:0]; // Extracting the 3 least significant bits as type
                        byte_count <= 8'd0;
                        next_state <= DATA_RECEIVE;
                        data_valid <= 1'd0;
                    end
                    DATA_RECEIVE: begin
                        case (data_type)
                            3'd0: x_instructions_flat[byte_count*3 +: 3] <= rx_data_out[2:0];
                            3'd1: x_params_a_flat[byte_count*8 +: 8] <= rx_data_out;
                            3'd2: x_params_b_flat[byte_count*8 +: 8] <= rx_data_out;
                            3'd3: x_params_c_flat[byte_count*8 +: 8] <= rx_data_out;
                            3'd4: y_instructions_flat[byte_count*3 +: 3] <= rx_data_out[2:0];
                            3'd5: y_params_a_flat[byte_count*8 +: 8] <= rx_data_out;
                            3'd6: y_params_b_flat[byte_count*8 +: 8] <= rx_data_out;
                            3'd7: y_params_c_flat[byte_count*8 +: 8] <= rx_data_out;
                        endcase
                        byte_count <= byte_count + 1;
                        if (byte_count == INSTRUCTION_COUNT-1) 
                            next_state <= END_DETECTION;
                        else
                            next_state <= DATA_RECEIVE;
                    end
                    END_DETECTION: begin
                        data_valid <= 1'd1;
                        if (rx_data_out == 8'h55) begin
                            RxD_endofpacket <= 1;
                            next_state <= IDLE;
                            
                        end else 
                            next_state <= DATA_RECEIVE; // If it's not end byte, continue to collect data
                    end
                endcase
            end
        end
    end


    always @(posedge clk) begin
        if (reset)
            RxD_endofpacket <= 0;
        else if (RxD_endofpacket)
            RxD_endofpacket <= 0;
    end
endmodule


module image_wave_gen (
    input clk,
    input ten_clk,
    input reset, // Active high reset
    input enable,
    input uart_rx_wire,
    output [7:0] xdac,
    output [7:0] ydac
);

    wire [(INSTRUCTION_COUNT*3)-1:0] x_instructions_flat;
    wire [(INSTRUCTION_COUNT*8)-1:0] x_params_a_flat;
    wire [(INSTRUCTION_COUNT*8)-1:0] x_params_b_flat;
    wire [(INSTRUCTION_COUNT*8)-1:0] x_params_c_flat;
        
    wire [(INSTRUCTION_COUNT*3)-1:0] y_instructions_flat;
    wire [(INSTRUCTION_COUNT*8)-1:0] y_params_a_flat;
    wire [(INSTRUCTION_COUNT*8)-1:0] y_params_b_flat;
    wire [(INSTRUCTION_COUNT*8)-1:0] y_params_c_flat;
    
    
    wire data_valid;
    
    
    reg done_triangle1;
    wire done_triangle1_wire;
    reg done_triangle2;
    wire done_triangle2_wire;
    reg ack_triangle1;
    reg ack_triangle2;

    always @(posedge clk) begin
        if (reset) begin
            ack_triangle1 <= 0;
            ack_triangle2 <= 0;
        end else begin
            done_triangle1 = done_triangle1_wire;
            done_triangle2 = done_triangle2_wire;
            if (done_triangle1 && done_triangle2) begin
                ack_triangle1 <= 1;
                ack_triangle2 <= 1;
            end else begin
                ack_triangle1 <= 0;
                ack_triangle2 <= 0;
            end
        end
    end
    
     instruction_reader serial_reader (
        .clk(ten_clk),
        .reset(reset),
        .uart_rx_wire(uart_rx_wire),
        .x_instructions_flat(x_instructions_flat),
        .x_params_a_flat(x_params_a_flat),
        .x_params_b_flat(x_params_b_flat),
        .x_params_c_flat(x_params_c_flat),
        .y_instructions_flat(y_instructions_flat),
        .y_params_a_flat(y_params_a_flat),
        .y_params_b_flat(y_params_b_flat),
        .y_params_c_flat(y_params_c_flat),
        .data_valid(data_valid)
    );
    
    
    // DONT ASSUME IT'LL START FROM 0 LIKE ON THE FPGA
//    always @(posedge clk) begin
//        x_instructions_flat   = {C_X_RECT, C_JUMP, C_LINE, C_JUMP, C_X_RECT, C_JUMP, C_X_RECT, C_JUMP};
//        x_params_a_flat       = {8'd100,   8'd150, 8'd30,    8'd100, 8'd090,   8'd030, 8'd90, 8'd000};
//        x_params_b_flat       = {8'd100,   8'd150, 8'd60,    8'd100, 8'd090,   8'd030, 8'd90, 8'd000};
        
//        y_instructions_flat   = {C_Y_RECT, C_JUMP, C_LINE, C_JUMP, C_Y_RECT, C_JUMP, C_Y_RECT, C_JUMP};
//        y_params_a_flat       = {8'd100,   8'd150, 8'd90,    8'd020, 8'd090,   8'd000, 8'd90, 8'd000};
//        y_params_b_flat       = {8'd100,   8'd150, 8'd60,    8'd020, 8'd090,   8'd000, 8'd90, 8'd000};
//    end

    
    triangle_wave_gen_fsm_comb triangle1 (
        .clk(clk),
        .reset(reset),
        .enable(data_valid || enable),
        .ack(ack_triangle1),
        .instructions_flat(x_instructions_flat),
        .params_flat_a(x_params_a_flat),
        .params_flat_b(x_params_b_flat),
        .params_flat_c(x_params_c_flat),
        .dac_out(xdac),
        .done_out(done_triangle1_wire)
    );
    
    triangle_wave_gen_fsm_comb triangle2 (
        .clk(clk),
        .reset(reset),
        .enable(data_valid || enable),
        .ack(ack_triangle2),
        .instructions_flat(y_instructions_flat),
        .params_flat_a(y_params_a_flat),
        .params_flat_b(y_params_b_flat),
        .params_flat_c(y_params_c_flat),
        .dac_out(ydac),
        .done_out(done_triangle2_wire)
    );


endmodule
