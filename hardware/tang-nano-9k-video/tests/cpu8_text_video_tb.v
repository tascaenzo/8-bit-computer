`timescale 1ns/1ps
module cpu8_text_video_tb;
    reg clk=0, resetn=0, ready=1;
    always #20 clk=~clk;
    wire [13:0] address;
    reg [7:0] character;
    wire [23:0] rgb;
    wire de, hs, vs;
    cpu8_text_video dut(.clk(clk),.resetn(resetn),.memory_ready(ready),
        .character(character),.video_addr(address),.rgb(rgb),.de(de),
        .hsync(hs),.vsync(vs));
    // Independent synchronous VRAM model: A in three selected cells,
    // unsupported code next to first cell, and spaces everywhere else.
    always @(posedge clk) begin
        if(address == 0 || address == 14'h0105 || address == 14'h1dcf)
            character <= 8'h41;
        else if(address == 1) character <= 8'h80;
        else character <= 8'h20;
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
    reg active, expected_hs, expected_vs, pixel;
    integer n,x,y,offset,active_count=0,hs_count=0,vs_count=0;
    initial begin
        repeat(5) @(negedge clk);
        resetn=1;
        for(n=0;n<420002;n=n+1) begin
            x=n%800; y=(n/800)%525;
            active=x<640 && y<480;
            expected_hs=!(x>=656 && x<752);
            expected_vs=!(y>=490 && y<492);
            offset=(y/8)*128+x/8;
            glyph=(offset==0 || offset==14'h0105 || offset==14'h1dcf) ? a_row(y%8) : 0;
            pixel=active && ((glyph >> (x%8)) & 1);
            expected[2]=expected[1]; expected[1]=expected[0];
            expected[0]={active,expected_hs,expected_vs,pixel ? 24'hffffff : 24'h000000};
            if(address !== offset[13:0]) $fatal(1,"VRAM stride at x=%d y=%d",x,y);
            @(posedge clk); #1;
            if(n>=2) begin
                if({de,hs,vs,rgb} !== expected[2])
                    $fatal(1,"Pixel or sync pipeline mismatch at sample %d got=%h expected=%h",n,{de,hs,vs,rgb},expected[2]);
                if(de) active_count=active_count+1;
                if(!hs) hs_count=hs_count+1;
                if(!vs) vs_count=vs_count+1;
            end
            @(negedge clk);
        end
        if(active_count!=307200 || hs_count!=50400 || vs_count!=1600)
            $fatal(1,"Frame geometry: active=%d HS=%d VS=%d",active_count,hs_count,vs_count);
        ready=0;
        repeat(10) @(negedge clk);
        if(de || rgb!==0) $fatal(1,"Display not blank during initialization");
        $display("PASS: full 800x525 frame, 640x480 active, glyph pixels, stride and sync alignment");
        $finish;
    end
    initial begin #20000000; $fatal(1,"Text test timeout"); end
endmodule
