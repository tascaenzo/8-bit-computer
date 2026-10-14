`timescale 1ns/1ps
// VGA-compatible 640x480 timing: 800x525 total, 25.2 MHz, exactly 60 Hz.
module cpu8_text_video (
    input wire clk, resetn, memory_ready,
    input wire [7:0] character,
    output wire [13:0] video_addr,
    output reg [23:0] rgb,
    output reg de, hsync, vsync
);
    reg [9:0] x, y;
    assign video_addr = {y[9:3], x[9:3]};
    reg [2:0] x1, y1, x2;
    reg de1, hs1, vs1, de2, hs2, vs2;
    wire [7:0] glyph_row;
    cpu8_font font(.clk(clk), .character(character), .row(y1), .pixels(glyph_row));
    always @(posedge clk) begin
        if (!resetn) begin
            x <= 0; y <= 0;
            x1 <= 0; y1 <= 0; x2 <= 0;
            de1 <= 0; hs1 <= 1; vs1 <= 1;
            de2 <= 0; hs2 <= 1; vs2 <= 1;
            rgb <= 0; de <= 0; hsync <= 1; vsync <= 1;
        end else begin
            if (x == 799) begin
                x <= 0;
                if (y == 524) y <= 0;
                else y <= y + 1'b1;
            end else x <= x + 1'b1;
            // Stage 1 accompanies the synchronous VRAM lookup.
            x1 <= x[2:0]; y1 <= y[2:0];
            de1 <= x < 640 && y < 480 && memory_ready;
            hs1 <= !(x >= 656 && x < 752);
            vs1 <= !(y >= 490 && y < 492);
            // Stage 2 accompanies the synchronous font lookup.
            x2 <= x1; de2 <= de1; hs2 <= hs1; vs2 <= vs1;
            // Stage 3: monochrome white on black.
            rgb <= de2 && glyph_row[x2] ? 24'hffffff : 24'h000000;
            de <= de2; hsync <= hs2; vsync <= vs2;
        end
    end
endmodule
