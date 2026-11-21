`timescale 1ns/1ps
// Character/attribute overlay, synchronous like the VRAM read port.
// The moving bar is an activity indicator, not a measured boot percentage.
module cpu8_boot_screen #(parameter CLK_HZ=25_200_000) (
    input wire clk, resetn, active,
    input wire [13:0] video_addr,
    output reg [7:0] character, attribute
);
    localparam TICK_CYCLES=CLK_HZ/8;
    reg [$clog2(TICK_CYCLES)-1:0] tick_count;
    reg [4:0] activity;
    wire [6:0] row=video_addr[13:7], col=video_addr[6:0];
    // Packed constant strings are read from their most significant byte.
    function [7:0] title(input [6:0] index);
        reg [79:0] value;
        begin value="Enzo Tasca"; title=value >> ((9-index)*8); end
    endfunction
    function [7:0] subtitle(input [6:0] index);
        reg [111:0] value;
        begin value="8 BIT COMPUTER"; subtitle=value >> ((13-index)*8); end
    endfunction
    function [7:0] message(input [6:0] index);
        reg [79:0] value;
        begin value="BOOTING..."; message=value >> ((9-index)*8); end
    endfunction
    function [7:0] detail(input [6:0] index);
        reg [175:0] value;
        begin value="COPYING PROGRAM TO RAM"; detail=value >> ((21-index)*8); end
    endfunction
    function [7:0] footer(input [6:0] index);
        reg [151:0] value;
        begin value="WAITING FOR CPU RUN"; footer=value >> ((18-index)*8); end
    endfunction
    always @(posedge clk) begin
        if(!resetn || !active) begin tick_count<=0; activity<=0; end
        else if(tick_count==TICK_CYCLES-1) begin
            tick_count<=0;
            activity<=activity==27 ? 0 : activity+1'b1;
        end else tick_count<=tick_count+1'b1;
        character<=8'h20;
        attribute<=8'h00;
        if(row>=17 && row<=42 && col>=12 && col<=67) begin
            attribute<=8'h17;
            if(row==17 || row==42) begin character<=8'h2d; attribute<=8'h1b; end
            else if(col==12 || col==67) begin character<=8'h7c; attribute<=8'h18; end
            if((row==17 || row==42) && (col==12 || col==67)) character<=8'h2b;
            if(row==20 && col>=36 && col<=43) begin
                case(col)
                    36: character<=8'h5b; 38: character<=8'h45;
                    39: character<=8'h54; 41: character<=8'h38;
                    43: character<=8'h5d;
                    default: character<=8'h20;
                endcase
                attribute<=8'h1e;
            end
            if(row==24 && col>=35 && col<45) begin
                character<=title(col-35); attribute<=8'h1f;
            end
            if(row==27 && col>=33 && col<47) begin
                character<=subtitle(col-33); attribute<=8'h1b;
            end
            if(row==31 && col>=35 && col<45) begin
                character<=message(col-35); attribute<=8'h1e;
            end
            if(row==35 && col>=24 && col<=55) begin
                character<=col==24 ? 8'h5b : col==55 ? 8'h5d : 8'h2d;
                attribute<=8'h18;
                if(col>=26 && col<54 && col-26>=activity && col-26<activity+3) begin
                    character<=8'h3d; attribute<=8'h1b;
                end
            end
            if(row==39 && col>=29 && col<51) begin
                character<=detail(col-29); attribute<=8'h17;
            end
        end
        if(row==46 && col>=30 && col<49) begin
            character<=footer(col-30); attribute<=8'h08;
        end
    end
endmodule
