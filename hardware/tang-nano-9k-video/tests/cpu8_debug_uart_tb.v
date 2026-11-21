`timescale 1ns/1ps
module cpu8_debug_uart_tb;
    reg clk=0,resetn=0;
    always #5 clk=~clk;
    reg [12:0] addr=13'h403;
    reg [7:0] data=1;
    reg video=1,rd_n=0,wr_n=1,oe_n=0,dir=1,wa=0,ra=0;
    reg [13:0] pointer=0;
    wire tx;
    cpu8_debug_uart #(.CLK_HZ(460800)) dut(.clk(clk),.resetn(resetn),.boot_run(1'b0),
        .cpu_addr(addr),.cpu_data_in(data),.cpu_data_out(8'h01),
        .video_select(video),.key_select(1'b0),.rd_n(rd_n),.wr_n(wr_n),
        .buffer_oe_n(oe_n),.buffer_dir(dir),.ready(1'b1),
        .pointer(pointer),.color(8'h0f),.status(8'h01),
        .write_accepted(wa),.read_accepted(ra),.write_data(data),.tx(tx));
    task byte_in(output [7:0] value);
        begin
            @(negedge tx); repeat(2) @(posedge clk); #1;
            if(tx!==0) $fatal(1,"UART start bit");
            for(integer bit_index=0;bit_index<8;bit_index=bit_index+1) begin
                repeat(4) @(posedge clk); #1; value[bit_index]=tx;
            end
            repeat(4) @(posedge clk); #1;
            if(tx!==1) $fatal(1,"UART stop bit");
        end
    endtask
    task frame_in(input [1119:0] expected);
        reg [7:0] value;
        begin
            for(integer i=0;i<140;i=i+1) begin
                byte_in(value);
                if(value!==expected[(139-i)*8 +:8])
                    $fatal(1,"UART char %0d got %h expected %h",i,value,expected[(139-i)*8 +:8]);
            end
        end
    endtask
    initial begin
        repeat(5) @(negedge clk); resetn=1;
        repeat(6) @(negedge clk); ra=1;
        @(negedge clk); ra=0;
        frame_in(1120'h43505538763120423d3020593d322052443d302057523d3120413d32303138204d3d464646462044493d30312044563d3120444f3d3031204f453d30204449523d31205244593d3120503d3030303020433d304620533d303120573d303030303030303020523d30303030303030312057413d464646462057443d30302052413d323031382052563d30310a);
        @(negedge clk); addr=13'h400;rd_n=1;wr_n=0;data=8'h48;dir=0;pointer=1;wa=1;
        @(negedge clk); wa=0;
        frame_in(1120'h43505538763120423d3020593d322052443d312057523d3020413d32303030204d3d464646462044493d34382044563d3120444f3d3031204f453d30204449523d30205244593d3120503d3030303120433d304620533d303120573d303030303030303120523d30303030303030312057413d323030302057443d34382052413d323031382052563d30310a);
        @(negedge clk); video=0; addr=0; rd_n=0;wr_n=1;oe_n=1;data=8'hff;
        frame_in(1120'h43505538763120423d3020593d302052443d302057523d3120413d30303030204d3d464646382044493d46462044563d3020444f3d3031204f453d31204449523d30205244593d3120503d3030303120433d304620533d303120573d303030303030303120523d30303030303030312057413d323030302057443d34382052413d323031382052563d30310a);
        $display("PASS: UART 115200 framing, coherent snapshots, read/write counters, last events and address mask");
        $finish;
    end
    initial begin #3000000; $fatal(1,"Debug UART timeout"); end
endmodule
