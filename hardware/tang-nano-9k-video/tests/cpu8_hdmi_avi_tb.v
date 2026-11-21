`timescale 1ns/1ps
module cpu8_hdmi_avi_tb;
    reg clk=0, resetn=0;
    always #5 clk=~clk;
    wire [29:0] symbols;
    cpu8_hdmi_avi dut(.clk(clk),.resetn(resetn),.hsync(1'b0),.vsync(1'b0),
        .video_symbols(30'd0),.symbols(symbols));

    localparam [159:0] TERC4 = {
        10'h2c3,10'h163,10'h271,10'h28e,10'h2c6,10'h19c,10'h139,10'h2cc,
        10'h13c,10'h18e,10'h11e,10'h171,10'h2e2,10'h2e4,10'h263,10'h29c
    };
    function [3:0] decode(input [9:0] symbol);
        integer k;
        begin
            decode = 4'bx;
            for (k=0;k<16;k=k+1)
                if (TERC4[k*10+:10] == symbol) decode=k[3:0];
        end
    endfunction

    reg [31:0] header;
    reg [63:0] payload;
    reg [3:0] lane0, lane1, lane2;
    integer n, x, y, i, checksum, islands=0;
    localparam [29:0] ISLAND_PRE = {10'h0ab,10'h0ab,10'h354};
    localparam [29:0] VIDEO_PRE = {10'h354,10'h0ab,10'h354};
    localparam [29:0] ISLAND_GUARD = {10'h133,10'h133,10'h28e};
    localparam [29:0] VIDEO_GUARD = {10'h2cc,10'h133,10'h2cc};
    initial begin
        repeat(3) @(negedge clk);
        resetn=1;
        // Account for three raster pipeline stages and one encoder register.
        for(n=0;n<1650*750+3;n=n+1) begin
            @(posedge clk); #1;
            if(n>=3) begin
                x=(n-3)%1650; y=(n-3)/1650;
                if(y==749 && x>=1302 && x<1310) begin
                    if(symbols!==ISLAND_PRE) $fatal(1,"Island preamble");
                end else if(y==749 && (x==1310 || x==1311 || x==1344 || x==1345)) begin
                    if(symbols!==ISLAND_GUARD) $fatal(1,"Island guard band");
                end else if(y==749 && x>=1312 && x<1344) begin
                    i=x-1312;
                    lane0=decode(symbols[9:0]);
                    lane1=decode(symbols[19:10]);
                    lane2=decode(symbols[29:20]);
                    if(lane0[3]!==1'b1 || lane0[1:0]!==0 ||
                       lane1[3:1]!==0 || lane2[3:1]!==0 ||
                       (^lane0 === 1'bx) || (^lane1 === 1'bx) || (^lane2 === 1'bx))
                        $fatal(1,"Malformed TERC4 at packet pixel %0d",i);
                    header[i]=lane0[2];
                    payload[2*i]=lane1[0];
                    payload[2*i+1]=lane2[0];
                    islands=islands+1;
                end else if((y<719 || y==749) && x>=1640) begin
                    if(symbols!==(x<1648 ? VIDEO_PRE : VIDEO_GUARD))
                        $fatal(1,"Video preamble or guard");
                end else if(symbols!==0) $fatal(1,"Auxiliary symbol outside HDMI blanking");
            end
        end
        if(islands!=32 || header!==32'he40d0282 ||
           payload!==64'hf00000040020004b) $fatal(1,"AVI bytes/ECC %h %h",header,payload);
        checksum=0;
        for(i=0;i<3;i=i+1) checksum=checksum+header[i*8+:8];
        for(i=0;i<7;i=i+1) checksum=checksum+payload[i*8+:8];
        if(checksum%256!=0) $fatal(1,"AVI checksum");
        $display("PASS: 720p AVI VIC 4, checksum, BCH, preambles and guard bands");
        $finish;
    end
endmodule
