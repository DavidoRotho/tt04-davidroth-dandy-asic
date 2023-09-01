
// Instructions
parameter C_NOP  = 3'd0;
parameter C_LINE = 3'd1;
parameter C_INCR = 3'd2;
parameter C_DCRE = 3'd3; 
parameter C_JUMP = 3'd4;
parameter PARAM_SIZE = 8;

module triangle_wave_gen_fsm (
    input clk,
    input reset, // Active high reset
    input [11:0] instructions_flat,
    input [31:0] params_flat,
    output [7:0] dac_out,
    input phase_shift
);

    reg [7:0] counter;
    reg [4:0] logic_state;
    reg [2:0] action_state;
    reg cycle_flag; // 0 for action cycle, 1 for check cycle
    
    
    reg [2:0] instructions[3:0];
    reg [7:0] params[3:0];
    reg [7:0] param_counter;
    reg [3:0] instruction_pointer;

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
    parameter L_INIT      = 4'd0;
    parameter L_UP        = 4'd1;
    parameter L_DOWN      = 4'd2;
    parameter L_BOUNCE    = 4'd3;
    parameter L_FULL_DOWN = 4'd4;

    always @(posedge clk) begin
        if (reset) begin
            action_state <= UP;
            logic_state = UP;
            cycle_flag = 1'b0;
            instructions[0] = instructions_flat[0*3 +: 3];
            instructions[1] = instructions_flat[1*3 +: 3];
            instructions[2] = instructions_flat[2*3 +: 3];
            instructions[3] = instructions_flat[3*3 +: 3];
            params[0] = params_flat[0*PARAM_SIZE +: PARAM_SIZE];
            params[1] = params_flat[1*PARAM_SIZE +: PARAM_SIZE];
            params[2] = params_flat[2*PARAM_SIZE +: PARAM_SIZE];
            params[3] = params_flat[3*PARAM_SIZE +: PARAM_SIZE];
            instruction_pointer = 4'd0;
            param_counter = 8'd0;
        end else if (cycle_flag == 0) begin // Action cycle
            case (action_state)
                UP: counter = counter + 8'd1;
                DOWN: counter = counter - 8'd1;
                HOLD: counter = counter;
            endcase
            param_counter = param_counter + 8'd1;
            cycle_flag = 1; // Switch to check cycle
        end else begin // Check cycle
            case (instructions[instruction_pointer])
                C_NOP: begin
                    action_state <= HOLD;
                    instruction_pointer = instruction_pointer + 4'd1;
                    param_counter = 8'd0;
                end
                C_JUMP: begin
                    action_state <= HOLD;
                    counter = params[instruction_pointer];
                    instruction_pointer = instruction_pointer + 4'd1;
                    param_counter = 8'd0;
                end
                C_INCR: begin
                    action_state <= UP;
                    if (param_counter == params[instruction_pointer]) begin
                        instruction_pointer = instruction_pointer + 4'd1;
                        param_counter = 8'd0;
                    end
                end
                C_DCRE: begin
                    action_state <= DOWN;
                    if (param_counter == params[instruction_pointer]) begin
                        instruction_pointer = instruction_pointer + 4'd1;
                        param_counter = 8'd0;
                    end
                end
                C_LINE: begin
                    action_state <= HOLD;
                    if (param_counter == params[instruction_pointer]) begin
                        instruction_pointer = instruction_pointer + 4'd1;
                        param_counter = 8'd0;
                    end
                end
            endcase
            cycle_flag = 0; // Switch back to action cycle
        end
    end

    assign dac_out = counter;

endmodule


module image_wave_gen (
    input clk,
    input reset, // Active high reset
    output [7:0] xdac,
    output [7:0] ydac
);

    reg [2:0] x_instructions[3:0];
    reg [11:0] x_instructions_flat;
    reg [7:0] x_params[3:0];
    reg [31:0] x_params_flat;

    always @(*) begin
        x_instructions[0] <= C_JUMP;
        x_params[0]       <= 8'd250;
        x_instructions[1] <= C_LINE;
        x_params[1]       <= 8'd100;
        x_instructions[2] <= C_DCRE;
        x_params[2]       <= 8'd90;
        x_instructions[3] <= C_NOP;
        x_params[3]       <= 8'd0;
        
        x_instructions_flat[0*3 +: 3] <= x_instructions[0];
        x_instructions_flat[1*3 +: 3] <= x_instructions[1];
        x_instructions_flat[2*3 +: 3] <= x_instructions[2];
        x_instructions_flat[3*3 +: 3] <= x_instructions[3];
        x_params_flat[0*PARAM_SIZE +: PARAM_SIZE] <= x_params[0];
        x_params_flat[1*PARAM_SIZE +: PARAM_SIZE] <= x_params[1];
        x_params_flat[2*PARAM_SIZE +: PARAM_SIZE] <= x_params[2];
        x_params_flat[3*PARAM_SIZE +: PARAM_SIZE] <= x_params[3];
    end
    
    reg [2:0] y_instructions[3:0];
    reg [11:0] y_instructions_flat;
    reg [7:0] y_params[3:0];
    reg [31:0] y_params_flat;

    always @(*) begin
        y_instructions[0] <= C_JUMP;
        y_params[0]       <= 8'd10;
        y_instructions[1] <= C_INCR;
        y_params[1]       <= 8'd100;
        y_instructions[2] <= C_DCRE;
        y_params[2]       <= 8'd90;
        y_instructions[3] <= C_NOP;
        y_params[3]       <= 8'd0;

    
        y_instructions_flat[0*3 +: 3] <= y_instructions[0];
        y_instructions_flat[1*3 +: 3] <= y_instructions[1];
        y_instructions_flat[2*3 +: 3] <= y_instructions[2];
        y_instructions_flat[3*3 +: 3] <= y_instructions[3];
        y_params_flat[0*PARAM_SIZE +: PARAM_SIZE] <= y_params[0];
        y_params_flat[1*PARAM_SIZE +: PARAM_SIZE] <= y_params[1];
        y_params_flat[2*PARAM_SIZE +: PARAM_SIZE] <= y_params[2];
        y_params_flat[3*PARAM_SIZE +: PARAM_SIZE] <= y_params[3];
    end
    
    


    triangle_wave_gen_fsm triangle1 (
        .clk(clk),
        .reset(reset),
        .instructions_flat(x_instructions_flat),
        .params_flat(x_params_flat),
        .dac_out(xdac),
        .phase_shift(1'b0)
    );
    
    triangle_wave_gen_fsm triangle2 (
        .clk(clk),
        .reset(reset),
        .instructions_flat(y_instructions_flat),
        .params_flat(y_params_flat),
        .dac_out(ydac),
        .phase_shift(1'b1)
    );


endmodule

