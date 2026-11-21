`timescale 1ns/1ps
module cpu8_text_video_tb #(parameter VIDEO_720P=0, VIDEO_50HZ=0);
    localparam W = VIDEO_720P ? 1280 : 640, H = VIDEO_720P ? 720 : 480;
    localparam HT = VIDEO_720P ? (VIDEO_50HZ ? 1980 : 1650) : 800, VT = VIDEO_720P ? 750 : 525;
    localparam X0 = (W-640)/2, Y0 = (H-480)/2;
    reg clk=0, resetn=0, ready=1;
    always #20 clk=~clk;
    wire [13:0] address;
    reg [7:0] character, attribute;
    wire [23:0] rgb;
    wire de, hs, vs;
    cpu8_text_video #(.VIDEO_720P(VIDEO_720P), .VIDEO_50HZ(VIDEO_50HZ)) dut(.clk(clk),.resetn(resetn),.memory_ready(ready),
        .character(character),.attribute(attribute),.cursor_addr(14'h0105),
        .cursor_visible(1'b1),.video_addr(address),.rgb(rgb),.de(de),
        .hsync(hs),.vsync(vs));
    // Independent synchronous VRAM model: A in three selected cells,
    // unsupported code next to first cell, and spaces everywhere else.
    always @(posedge clk) begin
        if(address == 0 || address == 14'h0105 || address == 14'h1dcf)
            character <= 8'h41;
        else if(address == 1) character <= 8'h80;
        else character <= 8'h20;
        case(address)
            0: attribute<=8'h1e;
            1: attribute<=8'h24;
            14'h0105: attribute<=8'h4b;
            default: attribute<=8'h0f;
        endcase
    end
    function [7:0] a_row(input integer row);
        begin case(row)
            0: a_row=8'h38;
            1,2,4,5,6: a_row=8'h44;
            3: a_row=8'h7c;
            default: a_row=0;
        endcase end
    endfunction
    reg [26:0] expected[0:2];
    reg [7:0] glyph;
    reg active, in_text, expected_hs, expected_vs, pixel;
    reg [23:0] foreground, background;
    integer n,x,y,offset,active_count=0,hs_count=0,vs_count=0;
    initial begin
        repeat(5) @(negedge clk);
        resetn=1;
        for(n=0;n<HT*VT+2;n=n+1) begin
            x=n%HT; y=(n/HT)%VT;
            active=x<W && y<H;
            in_text=x>=X0 && x<X0+640 && y>=Y0 && y<Y0+480;
            expected_hs=VIDEO_720P ? (VIDEO_50HZ ? (x>=1720 && x<1760) : (x>=1390 && x<1430)) : !(x>=656 && x<752);
            expected_vs=VIDEO_720P ? (y>=725 && y<730) : !(y>=490 && y<492);
            offset=((y-Y0)/8)*128+(x-X0)/8;
            glyph=(offset==0 || offset==14'h0105 || offset==14'h1dcf) ? a_row((y-Y0)%8) : 0;
            pixel=((glyph >> ((x-X0)%8)) & 1) ^ (offset==14'h0105);
            foreground=24'hffffff; background=0;
            if(offset==0) begin foreground=24'hffd166; background=24'h18243b; end
            if(offset==1) begin foreground=24'hb93838; background=24'h238636; end
            if(offset==14'h0105) begin foreground=24'h38d9cf; background=24'hb93838; end
            expected[2]=expected[1]; expected[1]=expected[0];
            expected[0]={active,expected_hs,expected_vs,active && in_text ? (pixel ? foreground : background) : 24'h000000};
            if(in_text && address !== offset[13:0]) $fatal(1,"VRAM stride at x=%d y=%d",x,y);
            @(posedge clk); #1;
            if(n>=2) begin
                if({de,hs,vs,rgb} !== expected[2])
                    $fatal(1,"Pixel or sync pipeline mismatch at sample %d got=%h expected=%h",n,{de,hs,vs,rgb},expected[2]);
                if(de) active_count=active_count+1;
                if(hs == VIDEO_720P) hs_count=hs_count+1;
                if(vs == VIDEO_720P) vs_count=vs_count+1;
            end
            @(negedge clk);
        end
        if(active_count!=W*H || hs_count!=(VIDEO_720P ? 40 : 96)*VT || vs_count!=(VIDEO_720P ? 5 : 2)*HT)
            $fatal(1,"Frame geometry: active=%d HS=%d VS=%d",active_count,hs_count,vs_count);
        ready=0;
        repeat(10) @(negedge clk);
        if(de || rgb!==0) $fatal(1,"Display not blank during initialization");
        $display("PASS: %0dx%0d active, colored glyphs/backgrounds, cursor, stride and sync alignment", W, H);
        $finish;
    end
    initial begin #60000000; $fatal(1,"Text test timeout"); end
endmodule
