module triangle_wave_gen (
    input clk,
    input reset, // Active high reset
    output [7:0] dac_out,
    input phase_shift
);

    reg [7:0] counter;
    reg up;

    // Constants for clarity
    parameter MAX_COUNTER_VALUE = 8'd255;  // Maximum value for 8-bit up count in decimal
    parameter MIN_COUNTER_VALUE = 8'd0;    // Minimum value for 8-bit down count in decimal
    parameter PHASE_SHIFT_VALUE = 8'd128;  // 25% of the maximum value for 90-degree phase shift

    always @(posedge clk) begin
        if (reset) begin
            if (phase_shift) 
                counter <= PHASE_SHIFT_VALUE;
            else
                counter <= MIN_COUNTER_VALUE;

            up <= 1;
        end else begin
            if (up) begin
                if (counter == MAX_COUNTER_VALUE) begin
                    up <= 0; // Switch direction to down
                    counter <= counter - 8'd1;
                end else begin
                    counter <= counter + 8'd1;
                end
            end else begin
                if (counter == MIN_COUNTER_VALUE) begin
                    up <= 1; // Switch direction to up
                    counter <= counter + 8'd1;
                end else begin
                    counter <= counter - 8'd1;
                end
            end
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


    triangle_wave_gen triangle1 (
        .clk(clk),
        .reset(reset),
        .dac_out(xdac),
        .phase_shift(1'b0)
    );
    
    triangle_wave_gen triangle2 (
        .clk(clk),
        .reset(reset),
        .dac_out(ydac),
        .phase_shift(1'b1)
    );


endmodule
