`timescale 1ns/1ps
// Both scan modes use the same 80x60 character memory.
module cpu8_text_video #(parameter VIDEO_720P = 0, VIDEO_50HZ = 0) (
    input wire clk, resetn, memory_ready,
    input wire [7:0] character, attribute,
    input wire [13:0] cursor_addr,
    input wire cursor_visible,
    output wire [13:0] video_addr,
    output reg [23:0] rgb,
    output reg de, hsync, vsync
);
    localparam H_ACTIVE = VIDEO_720P ? 1280 : 640;
    localparam V_ACTIVE = VIDEO_720P ? 720 : 480;
    localparam H_TOTAL = VIDEO_720P ? (VIDEO_50HZ ? 1980 : 1650) : 800;
    localparam V_TOTAL = VIDEO_720P ? 750 : 525;
    localparam H_SYNC_START = VIDEO_720P ? (VIDEO_50HZ ? 1720 : 1390) : 656;
    localparam H_SYNC_END = VIDEO_720P ? (VIDEO_50HZ ? 1760 : 1430) : 752;
    localparam V_SYNC_START = VIDEO_720P ? 725 : 490;
    localparam V_SYNC_END = VIDEO_720P ? 730 : 492;
    localparam X_OFFSET = (H_ACTIVE - 640) / 2;
    localparam Y_OFFSET = (V_ACTIVE - 480) / 2;
    reg [$clog2(H_TOTAL)-1:0] x;
    reg [$clog2(V_TOTAL)-1:0] y;
    wire [9:0] text_x = x - X_OFFSET;
    wire [9:0] text_y = y - Y_OFFSET;
    wire in_text = x >= X_OFFSET && x < X_OFFSET + 640 &&
                   y >= Y_OFFSET && y < Y_OFFSET + 480;
    assign video_addr = {text_y[9:3], text_x[9:3]};
    reg [2:0] x1, y1, x2;
    reg de1, hs1, vs1, de2, hs2, vs2, text1, text2;
    reg [7:0] attr2;
    reg cursor1, cursor2;
    function [23:0] palette(input [3:0] color);
        case(color)
            0: palette=24'h000000; 1: palette=24'h18243b;
            2: palette=24'h238636; 3: palette=24'h168aad;
            4: palette=24'hb93838; 5: palette=24'h9146b5;
            6: palette=24'had762d; 7: palette=24'hb8c4d4;
            8: palette=24'h526177; 9: palette=24'h5b8def;
            10: palette=24'h68d391; 11: palette=24'h38d9cf;
            12: palette=24'hff7b72; 13: palette=24'hd99bff;
            14: palette=24'hffd166; 15: palette=24'hffffff;
        endcase
    endfunction
    wire [7:0] glyph_row;
    cpu8_font font(.clk(clk), .character(character), .row(y1), .pixels(glyph_row));
    always @(posedge clk) begin
        if (!resetn) begin
            x <= 0; y <= 0;
            x1 <= 0; y1 <= 0; x2 <= 0;
            attr2 <= 0; cursor1 <= 0; cursor2 <= 0;
            de1 <= 0; hs1 <= 1; vs1 <= 1;
            de2 <= 0; hs2 <= 1; vs2 <= 1;
            text1 <= 0; text2 <= 0;
            rgb <= 0; de <= 0; hsync <= 1; vsync <= 1;
        end else begin
            if (x == H_TOTAL-1) begin
                x <= 0;
                if (y == V_TOTAL-1) y <= 0;
                else y <= y + 1'b1;
            end else x <= x + 1'b1;
            // Stage 1 accompanies the synchronous VRAM lookup.
            x1 <= text_x[2:0]; y1 <= text_y[2:0];
            text1 <= in_text;
            cursor1 <= cursor_visible && video_addr == cursor_addr;
            de1 <= x < H_ACTIVE && y < V_ACTIVE && memory_ready;
            hs1 <= (x >= H_SYNC_START && x < H_SYNC_END) == VIDEO_720P;
            vs1 <= (y >= V_SYNC_START && y < V_SYNC_END) == VIDEO_720P;
            // Stage 2 accompanies the synchronous font lookup.
            x2 <= x1; text2 <= text1; de2 <= de1; hs2 <= hs1; vs2 <= vs1;
            attr2 <= attribute; cursor2 <= cursor1;
            // Attribute follows the glyph through its font lookup stage.
            // The cursor is an inverted full cell, with no VRAM modification.
            rgb <= de2 && text2 ? palette((glyph_row[x2] ^ cursor2) ?
                                         attr2[3:0] : attr2[7:4]) : 24'h000000;
            de <= de2; hsync <= hs2; vsync <= vs2;
        end
    end
endmodule
