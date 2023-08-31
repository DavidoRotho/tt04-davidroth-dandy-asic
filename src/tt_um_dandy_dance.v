
module tt_um_dandy_dance (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire reset = ! rst_n;
    wire [7:0] x_out;
    wire [7:0] y_out;
    assign uo_out[7:0] = x_out;
    assign uio_out[7:0] = y_out;
    
    assign uio_oe = 8'b11111111;

    image_wave_gen im_gen(
        .clk(clk),
        .reset(reset), // Active high reset
        .xdac(x_out),
        .ydac(y_out)
    );

endmodule
