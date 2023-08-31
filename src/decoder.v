module triangle_wave_gen (
    input clk,
    input reset, // Active high reset
    output [7:0] dac_out,
    input phase_shift
);

reg [9:0] counter;
reg up;

always @(posedge clk) begin
    if (reset) begin
        if (phase_shift) 
            counter <= 10'b0010000000; // 25% of the maximum value for 90-degree phase shift
        else
            counter <= 10'b0; // Start at 0
        
        up <= 1;
    end else begin
        if (up) begin
            if (counter == 10'b0011111111) begin // Maximum value for 8-bit up count
                up <= 0; // Switch direction to down
                counter <= counter - 1;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            if (counter == 10'b0000000000) begin // Minimum value for 8-bit down count
                up <= 1; // Switch direction to up
                counter <= counter + 1;
            end else begin
                counter <= counter - 1;
            end
        end
    end
end

assign dac_out = counter[7:0];

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
        .phase_shift(0)
    );
    
    triangle_wave_gen triangle2 (
        .clk(clk),
        .reset(reset),
        .dac_out(ydac),
        .phase_shift(1)
    );


endmodule
