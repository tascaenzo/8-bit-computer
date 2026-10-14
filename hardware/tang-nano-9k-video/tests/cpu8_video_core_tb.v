`timescale 1ns/1ps
module cpu8_video_core_tb;
    reg clk=0;
    always #20 clk=~clk;
    reg resetn=0, rd_n=1, wr_n=1, enable=1;
    reg [15:0] addr=0;
    reg [7:0] cpu_value=0;
    tri [7:0] data_in, cpu_bus;
    wire buffer_dir, buffer_oe_n;
    wire [7:0] data_out;
    wire oe, ready, de, hs, vs;
    // Digital model of an external LVC8T245, including propagation delay.
    assign cpu_bus = !wr_n ? cpu_value : 8'bz;
    assign data_in = oe ? data_out : 8'bz;
    assign #12 data_in = !buffer_oe_n && !buffer_dir ? cpu_bus : 8'bz;
    assign #12 cpu_bus = !buffer_oe_n && buffer_dir ? data_in : 8'bz;
    wire [23:0] rgb;
    integer writes=0, before_writes, i;
    cpu8_video_core dut(.clk(clk),.resetn(resetn),.cpu_addr(addr),
        .cpu_data_in(data_in),.cpu_rd_n(rd_n),.cpu_wr_n(wr_n),
        .cpu_enable(enable),.cpu_data_out(data_out),.cpu_data_oe(oe),
        .cpu_buffer_dir(buffer_dir),.cpu_buffer_oe_n(buffer_oe_n),
        .ready(ready),.rgb(rgb),.de(de),.hsync(hs),.vsync(vs));
    always @(posedge clk) if(dut.write_enable) writes=writes+1;
    task clocks(input integer count);
        begin repeat(count) @(negedge clk); end
    endtask
    task idle;
        begin rd_n=1; wr_n=1; clocks(26); end
    endtask
    task write_byte(input [15:0] a, input [7:0] d);
        begin
            idle(); addr=a; cpu_value=d; clocks(3);
            wr_n=0; clocks(25);
            if(oe) $fatal(1,"FPGA drives during write %h",a);
            if(enable && a>=16'h4000 && a<=16'h7fff && (buffer_oe_n || buffer_dir))
                $fatal(1,"Write reception not enabled %h",a);
            if((!enable || a<16'h4000 || a>16'h7fff) && !buffer_oe_n)
                $fatal(1,"Translator enabled for unselected write %h",a);
            idle();
        end
    endtask
    task read_byte(input [15:0] a, input [7:0] expected);
        begin
            idle(); addr=a; clocks(3); rd_n=0; clocks(25);
            if(!oe || buffer_oe_n || !buffer_dir || cpu_bus !== expected)
                $fatal(1,"Read %h got %h oe=%b expected=%h",a,data_out,oe,expected);
            rd_n=1; #1;
            if(oe || !buffer_oe_n) $fatal(1,"OE failed immediate release");
            clocks(16);
        end
    endtask
    reg previous_dir=0, previous_oe_n=1, previous_fpga_oe=0;
    always @(posedge clk) begin
        #1;
        if(resetn && ready && enable) begin
            if(buffer_dir != previous_dir && (!buffer_oe_n || !previous_oe_n))
                $fatal(1,"DIR changed without disabled guard interval");
            if(!buffer_oe_n) begin
                if(addr[15:14]!=2'b01 || rd_n==wr_n)
                    $fatal(1,"Translator enabled for invalid or unselected cycle");
                if(!buffer_dir && oe) $fatal(1,"FPGA and receive buffer contend");
                if(buffer_dir && (!oe || !previous_fpga_oe))
                    $fatal(1,"External transmit enabled before FPGA data setup");
            end
        end
        previous_dir=buffer_dir;
        previous_oe_n=buffer_oe_n;
        previous_fpga_oe=oe;
    end
    initial begin
        clocks(5); resetn=1;
        // A transaction already active during initialization is not accepted.
        addr=16'h4000; cpu_value=8'h58; wr_n=0;
        wait(ready); clocks(20);
        if(writes != 0 || oe) $fatal(1,"Transaction during clear accepted");
        for(i=0;i<16384;i=i+1)
            if(dut.vram.cells[i] !== 8'h20) $fatal(1,"Clear failed at %d",i);
        idle();
        write_byte(16'h4000,8'h41);
        write_byte(16'h4105,8'h42);
        write_byte(16'h5dcf,8'h43);
        write_byte(16'h7fff,8'hfe);
        if(writes != 4) $fatal(1,"Repeated writes for long strobes: %d",writes);
        read_byte(16'h4000,8'h41); read_byte(16'h4105,8'h42);
        read_byte(16'h5dcf,8'h43); read_byte(16'h7fff,8'hfe);
        read_byte(16'h4001,8'h20); read_byte(16'h4080,8'h20);

        // Range boundaries and high-address aliases must not touch VRAM.
        write_byte(16'h0000,8'h11); write_byte(16'h3fff,8'h11);
        write_byte(16'h8000,8'h11); write_byte(16'hc000,8'h11);
        write_byte(16'hff00,8'h11); write_byte(16'hffff,8'h11);
        if(writes != 4) $fatal(1,"Out-of-range write accepted");
        addr=16'hff00; rd_n=0; clocks(50);
        if(oe) $fatal(1,"IO range incorrectly responds");
        idle();

        // Invalid simultaneous strobes and disabled cycles.
        addr=16'h4000; rd_n=0; wr_n=0; clocks(25);
        if(oe || writes != 4) $fatal(1,"Invalid cycle accepted");
        idle(); enable=0; write_byte(16'h4000,8'hff);
        if(writes != 4) $fatal(1,"Disabled write accepted");
        enable=1; idle();
        // Short glitches, below the defined protocol, do not commit.
        addr=16'h4000; wr_n=0; #5; wr_n=1; clocks(20);
        if(writes != 4) $fatal(1,"Short glitch accepted");
        read_byte(16'h4000,8'h41);

        // Read-to-write turn-around releases OE before sync catches up.
        addr=16'h4000; rd_n=0; clocks(50);
        if(!oe) $fatal(1,"Read not ready");
        wr_n=0; #1;
        if(oe) $fatal(1,"OE when physical WR goes low");
        idle();
        addr=16'h4000; rd_n=0; clocks(50);
        addr=16'h8000; #1;
        if(oe) $fatal(1,"OE after physical address changes");
        idle();
        addr=16'h4000; rd_n=0; clocks(50); enable=0; #1;
        if(oe) $fatal(1,"OE after disable");
        idle(); enable=1; idle();

        // A reset cancels the transaction and starts a new clear.
        addr=16'h4000; rd_n=0; clocks(50); resetn=0; #1;
        if(oe) $fatal(1,"OE after reset");
        clocks(3); resetn=1; idle(); wait(ready); clocks(20);
        read_byte(16'h4000,8'h20);
        before_writes=writes;
        write_byte(16'h4080,8'h61);
        read_byte(16'h4080,8'h61);
        if(writes != before_writes+1) $fatal(1,"Write after reset failed");
        $display("PASS: LVC8T245 model, 1us write/read, direction guards, bounds, OE and reset");
        $finish;
    end
    initial begin #5000000; $fatal(1,"Core test timeout"); end
endmodule
