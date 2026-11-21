`timescale 1ns/1ps
// Single AVI InfoFrame per 720p60 frame, without audio. See HDMI 1.4
// sections 5.2 and 5.4 for island layout, BCH, guard bands and TERC4.
module cpu8_hdmi_avi (
    input wire clk, resetn,
    input wire hsync, vsync,
    input wire [29:0] video_symbols,
    output wire [29:0] symbols
);
    reg [10:0] x;
    reg [9:0] y;
    localparam NORMAL=0, VIDEO_PRE=1, VIDEO_GUARD=2,
               ISLAND_PRE=3, ISLAND_GUARD=4, ISLAND=5;
    reg [2:0] period;
    always @* begin
        period = NORMAL;
        if (y == 749 && x >= 1302 && x < 1346) begin
            if (x < 1310) period = ISLAND_PRE;
            else if (x < 1312 || x >= 1344) period = ISLAND_GUARD;
            else period = ISLAND;
        end else if ((y < 719 || y == 749) && x >= 1640)
            period = x < 1648 ? VIDEO_PRE : VIDEO_GUARD;
    end

    // Match the renderer's three-clock sync delay, then register the
    // auxiliary symbols alongside the registered video encoder outputs.
    reg [7:0] phase1, phase2, phase3;
    reg use_aux;
    reg [29:0] aux, aux_next;
    always @(posedge clk) begin
        if (!resetn) begin
            x <= 0; y <= 0;
            phase1 <= 0; phase2 <= 0; phase3 <= 0;
            use_aux <= 0;
            aux <= 0;
        end else begin
            if (x == 1649) begin
                x <= 0;
                y <= y == 749 ? 10'd0 : y + 1'b1;
            end else x <= x + 1'b1;
            phase1 <= {period,x[4:0]};
            phase2 <= phase1;
            phase3 <= phase2;
            use_aux <= phase3[7:5] != NORMAL;
            aux <= aux_next;
        end
    end

    function [7:0] ecc;
        input [55:0] bytes;
        input integer count;
        integer i;
        reg [7:0] remainder;
        begin
            remainder = 0;
            for (i=0; i<count; i=i+1)
                remainder = (remainder >> 1) ^
                            ((remainder[0] ^ bytes[i]) ? 8'h83 : 8'h00);
            ecc = remainder;
        end
    endfunction

    // HB0..2: AVI, version 2, length 13. PB2: 16:9. PB4: VIC 4.
    // PB0 is the checksum over the header and the 13 payload bytes.
    localparam [23:0] HEADER = 24'h0d0282;
    localparam [55:0] PAYLOAD = 56'h0000040020004b;
    localparam [31:0] HEADER_BCH = {ecc({32'b0,HEADER},24),HEADER};
    localparam [63:0] SUB0_BCH = {ecc(PAYLOAD,56),PAYLOAD};
    wire [4:0] index = phase3[4:0]; // Island starts at x=1312, a multiple of 32.
    wire [1:0] sync = {vsync,hsync};

    function [9:0] control_symbol;
        input [1:0] bits;
        case (bits)
            0: control_symbol = 10'b1101010100;
            1: control_symbol = 10'b0010101011;
            2: control_symbol = 10'b0101010100;
            3: control_symbol = 10'b1010101011;
        endcase
    endfunction

    function [9:0] terc4;
        input [3:0] bits;
        case (bits)
             0: terc4 = 10'b1010011100;
             1: terc4 = 10'b1001100011;
             2: terc4 = 10'b1011100100;
             3: terc4 = 10'b1011100010;
             4: terc4 = 10'b0101110001;
             5: terc4 = 10'b0100011110;
             6: terc4 = 10'b0110001110;
             7: terc4 = 10'b0100111100;
             8: terc4 = 10'b1011001100;
             9: terc4 = 10'b0100111001;
            10: terc4 = 10'b0110011100;
            11: terc4 = 10'b1011000110;
            12: terc4 = 10'b1010001110;
            13: terc4 = 10'b1001110001;
            14: terc4 = 10'b0101100011;
            15: terc4 = 10'b1011000011;
        endcase
    endfunction

    localparam [9:0] GUARD_A = 10'b1011001100, GUARD_B = 10'b0100110011;
    always @* begin
        case (phase3[7:5])
            VIDEO_PRE: aux_next = {control_symbol(0),control_symbol(1),control_symbol(sync)};
            ISLAND_PRE: aux_next = {control_symbol(1),control_symbol(1),control_symbol(sync)};
            VIDEO_GUARD: aux_next = {GUARD_A,GUARD_B,GUARD_A};
            ISLAND_GUARD: aux_next = {GUARD_B,GUARD_B,terc4({2'b11,sync})};
            ISLAND: aux_next = {terc4({3'b0,SUB0_BCH[{index,1'b1}]}),
                               terc4({3'b0,SUB0_BCH[{index,1'b0}]}),
                               terc4({1'b1,HEADER_BCH[index],sync})};
            default: aux_next = 0;
        endcase
    end
    assign symbols = use_aux ? aux : video_symbols;
endmodule
