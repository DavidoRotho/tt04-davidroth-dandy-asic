
module tt_um_dandy_dance #( parameter MAX_COUNT = 24'd10_000_000 ) (
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
    
    
    reg div_clk;
    reg [5:0] clk_divider = 6'd0;
    reg div_clk_unsynced;
    reg div_clk_sync_stage1;
    

    always @(posedge clk) begin
        if (clk_divider == ui_in[7:2]) begin
            clk_divider <= 6'd0;
            div_clk_unsynced <= 1;
        end else begin
            clk_divider <= clk_divider + 6'd1;
            div_clk_unsynced <= 0;
        end

    end

    image_wave_gen im_gen(
        .clk(div_clk_unsynced),
        .ten_clk(clk),
        .reset(reset),
        .enable(ui_in[1]),
        .uart_rx_wire(ui_in[0]),
        .xdac(x_out),
        .ydac(y_out)
    );
    
endmodule
