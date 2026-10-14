`timescale 1ns/1ps
module cpu8_tmds_tb;
    reg clk=0, resetn=0, de=0;
    always #20 clk=~clk;
    reg [1:0] control=0;
    reg [7:0] value=0;
    wire [9:0] symbol;
    svo_tmds dut(.clk(clk),.resetn(resetn),.de(de),.ctrl(control),.din(value),.dout(symbol));
    task check_control(input [1:0] c,input [9:0] expected);
        begin
            @(negedge clk); de=0; control=c;
            repeat(4) @(posedge clk);
            #1;
            if(symbol!==expected) $fatal(1,"TMDS control %b = %b",c,symbol);
        end
    endtask
    reg [9:0] first;
    integer i;
    initial begin
        repeat(5) @(negedge clk); resetn=1;
        check_control(0,10'b1101010100);
        check_control(1,10'b0010101011);
        check_control(2,10'b0101010100);
        check_control(3,10'b1010101011);
        // Decode all byte values independently from the emitted symbol:
        // undo polarity inversion, then XOR/XNOR transition encoding.
        for(i=0;i<256;i=i+1) begin
            check_control(0,10'b1101010100);
            @(negedge clk); de=1; value=i[7:0];
            repeat(3) @(posedge clk); #1;
            first=symbol;
            if(decode(first)!==i[7:0]) $fatal(1,"TMDS data %h decoded wrong",i[7:0]);
        end
        $display("PASS: TMDS control symbols and round-trip of all 256 pixel bytes");
        $finish;
    end
    function [7:0] decode(input [9:0] bits);
        reg [7:0] q,d;
        integer j;
        begin
            q=bits[9] ? ~bits[7:0] : bits[7:0];
            d[0]=q[0];
            for(j=1;j<8;j=j+1) d[j]=bits[8] ? (q[j]^q[j-1]) : ~(q[j]^q[j-1]);
            decode=d;
        end
    endfunction
endmodule
