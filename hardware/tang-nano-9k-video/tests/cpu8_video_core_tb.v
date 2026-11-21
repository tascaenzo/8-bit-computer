`timescale 1ns/1ps
module cpu8_video_core_tb;
    reg clk=0;
    always #20 clk=~clk;
    reg boot_run=1;
    reg resetn=0, rd_n=1, wr_n=1, video_select=0, key_select=0;
    reg ps2_clk=1, ps2_data=1;
    reg [12:0] addr=0;
    reg [7:0] cpu_value=0;
    tri [7:0] data_in, cpu_bus;
    wire buffer_dir, buffer_oe_n, oe, ready;
    wire [7:0] data_out;
    wire [23:0] rgb;
    reg saw_splash_pixels=0;
    assign cpu_bus = !wr_n ? cpu_value : 8'bz;
    assign data_in = oe ? data_out : 8'bz;
    assign #12 data_in = !buffer_oe_n && !buffer_dir ? cpu_bus : 8'bz;
    assign #12 cpu_bus = !buffer_oe_n && buffer_dir ? data_in : 8'bz;
    cpu8_video_core dut(.clk(clk),.resetn(resetn),.boot_run(boot_run),.cpu_addr(addr),
        .cpu_data_in(data_in),.cpu_rd_n(rd_n),.cpu_wr_n(wr_n),
        .video_select(video_select),.key_select(key_select),.ps2_clk(ps2_clk),.ps2_data(ps2_data),
        .cpu_data_out(data_out),.cpu_data_oe(oe),
        .cpu_buffer_dir(buffer_dir),.cpu_buffer_oe_n(buffer_oe_n),
        .ready(ready),.rgb(rgb),.de(),.hsync(),.vsync());
    task clocks(input integer count);
        repeat(count) @(negedge clk);
    endtask
    task idle;
        begin rd_n=1; wr_n=1; clocks(8); end
    endtask
    task select_register(input [1:0] sel, input [12:0] a);
        begin {video_select,key_select}=sel; addr=a; clocks(4); end
    endtask
    task write_byte(input [1:0] sel, input [12:0] a, input [7:0] d);
        begin
            idle(); select_register(sel,a); cpu_value=d; wr_n=0;
            clocks(25);
            if(oe) $fatal(1,"FPGA drives during write");
            idle();
        end
    endtask
    task check_read(input [7:0] expected);
        begin
            clocks(25);
            if (!oe || buffer_oe_n || !buffer_dir || cpu_bus !== expected)
                $fatal(1,"Read %h got %h expected %h",addr,cpu_bus,expected);
        end
    endtask
    task read_byte(input [1:0] sel, input [12:0] a, input [7:0] expected);
        begin
            idle(); select_register(sel,a); rd_n=0; check_read(expected);
            rd_n=1; #1;
            if(oe || !buffer_oe_n) $fatal(1,"Read OE did not release immediately");
            clocks(8);
        end
    endtask
    // Model the actual external OR + 74238, with A3 passed to the FPGA.
    function [1:0] peripheral_select(input [15:0] address);
        begin
            peripheral_select = 0;
            if (|address[15:13]) begin
                if (address[2:0] == 0) peripheral_select = 2'b10;
                if (address[2:0] == 1) peripheral_select = 2'b01;
            end
        end
    endfunction
    task mapped_write(input [15:0] address, input [7:0] value);
        write_byte(peripheral_select(address),address[15:3],value);
    endtask
    task mapped_read(input [15:0] address, input [7:0] expected);
        read_byte(peripheral_select(address),address[15:3],expected);
    endtask
    task ps2_bit(input bit_value);
        begin
            ps2_data=bit_value; clocks(8); ps2_clk=0; clocks(8);
            ps2_clk=1; clocks(8);
        end
    endtask
    task send_frame(input [7:0] value,input corrupt_parity,input stop_bit);
        integer i;
        begin
            ps2_bit(0);
            for(i=0;i<8;i=i+1) ps2_bit(value[i]);
            ps2_bit((~^value)^corrupt_parity); ps2_bit(stop_bit);
            ps2_data=1; clocks(8);
        end
    endtask
    task send_key(input [7:0] value);
        send_frame(value,0,1);
    endtask
    reg last_dir=0, last_oe_n=1, last_fpga_oe=0;
    integer video_writes=0;
    always @(posedge clk) begin
        if(resetn && dut.splash_active && rgb == 24'hffffff)
            saw_splash_pixels <= 1;
        if(dut.video_write) video_writes=video_writes+1;
        #1;
        if(resetn) begin
            if(buffer_dir!=last_dir && (!buffer_oe_n || !last_oe_n))
                $fatal(1,"DIR changed with translator enabled");
            if(!buffer_oe_n && (video_select==key_select || rd_n==wr_n))
                $fatal(1,"Translator enabled for invalid selection or strobes");
            if(!buffer_oe_n && buffer_dir && (!oe || !last_fpga_oe))
                $fatal(1,"External outputs enabled before data setup");
        end
        last_dir=buffer_dir; last_oe_n=buffer_oe_n; last_fpga_oe=oe;
    end

    initial begin
        clocks(5); resetn=1;
        // BOOT overlay remains until the external input changes, even
        // when CPU selects/strobes are active during the EPROM copy.
        select_register(2'b10,13'h400); cpu_value=8'h58; wr_n=0;
        clocks(300000);
        if(!saw_splash_pixels || !dut.splash_active || ready || video_writes!=0 ||
           oe || !buffer_oe_n) $fatal(1,"BOOT screen/isolation mismatch");
        idle();
        // Wait for the renderer to request the B of BOOTING..., then check
        // the registered character at the matching one-clock latency.
        wait(dut.video_addr == 14'd4003); @(posedge clk); #1;
        if(dut.splash_character !== 8'h42) $fatal(1,"BOOTING message missing");
        boot_run=0; clocks(8);
        if(dut.splash_active || !ready) $fatal(1,"RUN did not remove overlay");
        read_byte(2'b10,13'h403,1);
        write_byte(2'b10,13'h406,8'h05);
        write_byte(2'b10,13'h407,8'h02);
        write_byte(2'b10,13'h400,8'h43);
        write_byte(2'b10,13'h400,8'h49);
        if(video_writes!=2 || dut.pointer!==14'h107 ||
           dut.vram.cells[14'h105]!==8'h43 || dut.vram.cells[14'h106]!==8'h49)
            $fatal(1,"VRAM/pointer/autoincrement mismatch");
        write_byte(2'b10,13'h800,8'h58);
        write_byte(2'b11,13'h400,8'h58);
        write_byte(2'b00,13'h400,8'h58);
        select_register(2'b10,13'h400); cpu_value=8'h58;
        wr_n=0; clocks(4); idle();
        if(video_writes!=2) $fatal(1,"Invalid or short write accepted");

        read_byte(2'b01,13'h400,0);
        send_key(8'h1c); // A make, lowercase
        send_key(8'h32); // B, overrun
        read_byte(2'b01,13'h401,3);
        read_byte(2'b10,13'h403,1);
        read_byte(2'b01,13'h401,3);
        // Direct LDA: /RD remains active from RAM operand fetch into I/O.
        select_register(2'b00,13'h008); rd_n=0; clocks(25);
        if(oe || !buffer_oe_n) $fatal(1,"FPGA drove a RAM read");
        select_register(2'b01,13'h400); check_read(8'h61);
        // A new character arriving while the old read remains held is retained.
        send_key(8'h32);
        if(cpu_bus!==8'h61 || dut.key_data!==8'h62)
            $fatal(1,"Read response changed or consumed more than one byte");
        key_select=0; #1;
        if(oe || !buffer_oe_n) $fatal(1,"OE did not release on deselection");
        idle();
        read_byte(2'b01,13'h400,8'h62);
        write_byte(2'b01,13'h402,1);
        read_byte(2'b01,13'h401,0);
        send_key(8'h12); send_key(8'h1c); // Shift+A
        read_byte(2'b01,13'h400,8'h41);
        send_key(8'hf0); send_key(8'h12);
        send_key(8'he0); send_key(8'h75);
        read_byte(2'b01,13'h400,8'h80);
        send_frame(8'h1c,1,1); send_frame(8'h1c,0,0);
        read_byte(2'b01,13'h401,8'h0c);
        write_byte(2'b01,13'h402,2);
        read_byte(2'b01,13'h401,0);
        select_register(2'b01,13'h400); rd_n=0; wr_n=0; clocks(25);
        if(oe || !buffer_oe_n) $fatal(1,"Both strobes active");
        idle();
        // Cursor coordinates select cells without exposing raw pointer registers.
        mapped_write(16'h2030,8'h00);
        mapped_write(16'h2038,8'h04);
        mapped_write(16'h2000,8'h41);
        mapped_write(16'h2030,8'h20);
        mapped_write(16'h2000,8'h42);
        if(dut.vram.cells[14'h200]!==8'h41 || dut.vram.cells[14'h220]!==8'h42 ||
           dut.vram.cells[14'h201]!==8'h20 || dut.pointer!==14'h221)
            $fatal(1,"Cursor coordinates did not select the expected cells");
        // Removed PTR addresses must neither mutate state nor drive reads.
        for(integer removed=0;removed<2;removed=removed+1) begin
            mapped_write(16'h2008 + removed*8,8'hff);
            if(dut.pointer!==14'h221 || video_writes!=4)
                $fatal(1,"Removed PTR write changed pointer or VRAM");
            idle(); select_register(2'b10,13'h401 + removed);
            rd_n=0; clocks(25);
            if(oe || !buffer_oe_n || cpu_bus !== 8'bz)
                $fatal(1,"Removed PTR read drove the bus");
            idle();
        end
        mapped_read(16'h2030,33); mapped_read(16'h2038,4);
        mapped_read(16'h2018,1);
        send_key(8'h1c);
        mapped_read(16'h2009,1);
        mapped_read(16'h2001,8'h61);
        mapped_read(16'h2009,0);
        mapped_read(16'h2001,0);
        mapped_write(16'h0008,8'hff);
        mapped_write(16'h2002,8'hff);
        if(dut.pointer!==14'h221) $fatal(1,"RAM or different ID accepted");
        // Every high address bit participates in register decoding.
        for(integer bit_index=4;bit_index<16;bit_index=bit_index+1) begin
            idle();
            select_register(peripheral_select(16'h2001 ^ (16'h1 << bit_index)),
                            (16'h2001 ^ (16'h1 << bit_index)) >> 3);
            rd_n=0; clocks(25);
            if(oe || !buffer_oe_n) $fatal(1,"Address bit %0d ignored",bit_index);
            idle();
        end
        // Returning to BOOT releases an active read immediately; no
        // pointer register or VRAM write is accepted while copying ROM.
        select_register(2'b10,13'h403); rd_n=0; check_read(1);
        boot_run=1; #1;
        if(oe || !buffer_oe_n) $fatal(1,"BOOT failed to release read bus");
        clocks(8);
        if(!dut.splash_active || ready) $fatal(1,"Second BOOT screen missing");
        mapped_write(16'h2030,8'h05);
        mapped_write(16'h2000,8'hff);
        if(dut.pointer!==14'h221 || dut.vram.cells[14'h220]!==8'h42)
            $fatal(1,"BOOT modified CPU video state");
        send_key(8'h32);
        select_register(2'b01,13'h400); rd_n=0; clocks(25);
        if(oe || !buffer_oe_n || dut.key_data!==8'h62)
            $fatal(1,"BOOT consumed keyboard event or drove bus");
        idle(); boot_run=0; clocks(8);
        mapped_read(16'h2001,8'h62);
        if(dut.splash_active || !ready || dut.vram.cells[14'h220]!==8'h42)
            $fatal(1,"Second RUN failed to restore CPU display");
        // Per-cell attributes persist after the current color changes.
        mapped_write(16'h2028,8'h2e);
        mapped_read(16'h2028,8'h2e);
        mapped_write(16'h2030,79);
        mapped_write(16'h2038,0);
        mapped_write(16'h2000,8'h41);
        if(dut.pointer!==128 || dut.vram.cells[79]!==8'h41 || dut.vram.attrs[79]!==8'h2e)
            $fatal(1,"Colored write / 80-column wrap failed");
        mapped_write(16'h2028,8'h1b);
        mapped_write(16'h2000,8'h42);
        if(dut.vram.attrs[79]!==8'h2e || dut.vram.attrs[128]!==8'h1b)
            $fatal(1,"Changing current color changed an old cell");
        mapped_read(16'h2030,1);
        mapped_read(16'h2038,1);
        mapped_write(16'h2030,80); mapped_write(16'h2038,60);
        if(dut.pointer!==129) $fatal(1,"Invalid cursor coordinates accepted");
        mapped_write(16'h2040,8'hff); mapped_read(16'h2040,8'h1f);
        force dut.blink_counter=27'd0;
        clocks(2);
        if(!dut.cursor_visible) $fatal(1,"Blink cursor on phase missing");
        force dut.blink_counter=27'd12600000;
        clocks(2);
        if(dut.cursor_visible) $fatal(1,"Blink cursor off phase missing");
        release dut.blink_counter;
        mapped_write(16'h2040,8'h1c);

        // Clear is asynchronous to CPU accesses. Busy is readable, writes
        // are ignored, and the keyboard remains operational during it.
        mapped_write(16'h2028,8'h4b);
        mapped_write(16'h2020,1);
        mapped_read(16'h2018,2);
        mapped_write(16'h2028,8'h0f);
        mapped_write(16'h2000,8'h58);
        send_key(8'h1c); mapped_read(16'h2001,8'h61);
        wait(ready); clocks(4);
        if(dut.pointer!==0 || dut.color!==8'h4b) $fatal(1,"Clear / busy write isolation failed");
        for(integer cell_index=0;cell_index<7680;cell_index=cell_index+1)
            if(dut.vram.cells[cell_index]!==8'h20 || dut.vram.attrs[cell_index]!==8'h4b)
                $fatal(1,"Clear failed at cell %0d",cell_index);
        // Give each row a distinct character and attribute, then scroll.
        for(integer row=0;row<60;row=row+1) begin
            mapped_write(16'h2030,0); mapped_write(16'h2038,row);
            mapped_write(16'h2028,row);
            mapped_write(16'h2000,8'h41+(row%26));
        end
        mapped_write(16'h2028,8'h4b);
        mapped_write(16'h2020,4); mapped_read(16'h2018,2);
        wait(ready); clocks(4);
        for(integer row=0;row<59;row=row+1)
            if(dut.vram.cells[row*128] !== (8'h41+((row+1)%26)) ||
               dut.vram.attrs[row*128] !== row+1)
                $fatal(1,"Scroll character/attribute mismatch at row %0d",row);
        for(integer col=0;col<128;col=col+1)
            if(dut.vram.cells[7552+col]!==8'h20 || dut.vram.attrs[7552+col]!==8'h4b)
                $fatal(1,"Scroll did not clear last row");
        if(dut.pointer!==7552) $fatal(1,"Scroll cursor position");
        // Last-column write on the last row triggers automatic scrolling.
        mapped_write(16'h2028,8'h3f); mapped_write(16'h2030,79);
        mapped_write(16'h2000,8'h5a);
        wait(ready); clocks(4);
        if(dut.pointer!==7552 || dut.vram.cells[58*128+79]!==8'h5a ||
           dut.vram.attrs[58*128+79]!==8'h3f || dut.vram.attrs[7552]!==8'h3f)
            $fatal(1,"Automatic bottom-row scroll failed");
        mapped_write(16'h2020,2);
        mapped_write(16'h2030,5); mapped_write(16'h2020,3);
        if(dut.pointer!==128) $fatal(1,"Newline command");
        mapped_write(16'h2030,5); mapped_write(16'h2020,5);
        if(dut.pointer!==128) $fatal(1,"Carriage return command");
        mapped_write(16'h2040,0);
        mapped_write(16'h2000,8'h51); mapped_write(16'h2000,8'h52);
        if(dut.pointer!==128 || dut.vram.cells[128]!==8'h52)
            $fatal(1,"Disabling autoincrement failed");
        mapped_read(16'h2030,0); mapped_read(16'h2038,1);
        // CPU reset must restore all peripheral state, not only hide the text.
        send_key(8'h12); send_key(8'h1c); // Pending Shift+A event.
        mapped_read(16'h2009,1);
        select_register(2'b01,13'h400); rd_n=0; check_read(8'h41);
        resetn=0; #1;
        if(oe || !buffer_oe_n || ready) $fatal(1,"Reset did not isolate active read");
        idle(); clocks(5);
        if(dut.pointer!==0 || dut.color!==8'h0f || dut.control!==8'h1c ||
           dut.key_status!==0 || dut.key_data!==0 || dut.engine!==0)
            $fatal(1,"Reset did not restore video/keyboard registers");
        resetn=1; clocks(20);
        if(ready) $fatal(1,"READY asserted before VRAM initialization");
        wait(ready); clocks(4);
        for(integer cell_index=0;cell_index<16384;cell_index=cell_index+1)
            if(dut.vram.cells[cell_index]!==8'h20 || dut.vram.attrs[cell_index]!==8'h0f)
                $fatal(1,"Reset did not initialize VRAM cell %0d",cell_index);
        mapped_read(16'h2009,0);
        send_key(8'h1c); mapped_read(16'h2001,8'h61); // Shift cleared.
        mapped_write(16'h2000,8'h48);
        if(dut.pointer!==1 || dut.vram.cells[0]!==8'h48)
            $fatal(1,"CPU write after reset failed");
        $display("PASS: colored cells, cursor, clear/scroll/terminal commands, busy isolation, BOOT/RUN overlay, video MMIO, PS/2 events and errors, shared bus interlocks, OR/74238 and A3-A15 decoding");
        $finish;
    end
    initial begin #60000000; $fatal(1,"Core test timeout"); end
endmodule
