`timescale 1ns/1ps
module cpu8_boot_screen_tb;
    reg clk=0, resetn=0, active=1;
    always #5 clk=~clk;
    reg [13:0] address=0;
    wire [7:0] character, attribute;
    cpu8_boot_screen #(.CLK_HZ(80)) dut(.clk(clk),.resetn(resetn),.active(active),
        .video_addr(address),.character(character),.attribute(attribute));
    task check(input integer row,col,input [7:0] ch,attr);
        begin
            @(negedge clk); address=row*128+col;
            @(posedge clk); #1;
            if(character!==ch || attribute!==attr)
                $fatal(1,"Boot cell %0d,%0d got %h/%h expected %h/%h",row,col,character,attribute,ch,attr);
        end
    endtask
    initial begin
        repeat(2) @(negedge clk); resetn=1;
        check(24,35,"E",8'h1f); check(24,44,"a",8'h1f);
        check(27,33,"8",8'h1b); check(27,46,"R",8'h1b);
        check(31,35,"B",8'h1e); check(31,44,".",8'h1e);
        check(39,29,"C",8'h17); check(39,50,"M",8'h17);
        check(46,30,"W",8'h08); check(46,48,"N",8'h08);
        check(17,12,"+",8'h1b); check(18,12,"|",8'h18);
        check(0,0," ",8'h00);
        @(negedge clk); active=0;
        repeat(2) @(negedge clk);
        if(dut.activity!==0) $fatal(1,"Activity did not reset outside boot");
        active=1; repeat(12) @(negedge clk);
        if(dut.activity!==1) $fatal(1,"Activity indicator did not advance");
        $display("PASS: colored boot layout, complete text and animated activity");
        $finish;
    end
endmodule
