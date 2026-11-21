`timescale 1ns/1ps
// Render real RTL output to PPM for visual inspection; not a hardware model.
module cpu8_video_preview_tb;
    reg clk=0, resetn=0, boot_run=1;
    always #20 clk=~clk;
    reg [12:0] address=0;
    reg [7:0] value=0;
    reg rd_n=1,wr_n=1,selection=0;
    wire [23:0] rgb;
    wire de,hs,vs,ready;
    wire [7:0] out_data;
    wire oe,dir,oe_n;
    cpu8_video_core dut(.clk(clk),.resetn(resetn),.boot_run(boot_run),
        .cpu_addr(address),.cpu_data_in(value),.cpu_rd_n(rd_n),.cpu_wr_n(wr_n),
        .video_select(selection),.key_select(1'b0),.ps2_clk(1'b1),.ps2_data(1'b1),
        .cpu_data_out(out_data),.cpu_data_oe(oe),.ready(ready),
        .cpu_buffer_dir(dir),.cpu_buffer_oe_n(oe_n),.rgb(rgb),.de(de),.hsync(hs),.vsync(vs));
    task write_register(input [15:0] full_address,input [7:0] data);
        begin
            @(negedge clk); selection=1; address=full_address[15:3]; value=data;
            repeat(4) @(negedge clk); wr_n=0;
            repeat(25) @(negedge clk); wr_n=1;
            repeat(8) @(negedge clk);
        end
    endtask
    task capture(input [511:0] path);
        integer file_id,count;
        begin
            // Start after vertical sync; the next DE pixel is (0,0).
            @(negedge vs); @(posedge vs);
            file_id=$fopen(path,"wb");
            $fwrite(file_id,"P6\n640 480\n255\n");
            count=0;
            while(count<640*480) begin
                @(negedge clk);
                if(de) begin
                    $fwrite(file_id,"%c%c%c",rgb[23:16],rgb[15:8],rgb[7:0]);
                    count=count+1;
                end
            end
            $fclose(file_id);
        end
    endtask
    reg [127:0] label_text;
    initial begin
        repeat(5) @(negedge clk); resetn=1;
        capture("build/boot-screen.ppm");
        boot_run=0; wait(ready);
        write_register(16'h2028,8'h1f); write_register(16'h2020,1); wait(ready);
        for(integer row=0;row<16;row=row+1) begin
            write_register(16'h2030,8); write_register(16'h2038,8+row*2);
            write_register(16'h2028,row);
            label_text="ENZO TASCA 8 BIT";
            for(integer col=0;col<16;col=col+1)
                write_register(16'h2000,label_text >> ((15-col)*8));
        end
        write_register(16'h2030,8); write_register(16'h2038,42);
        write_register(16'h2028,8'h1e); write_register(16'h2040,8'h1d);
        capture("build/color-screen.ppm");
        $display("Rendered BOOT and CPU color previews from RTL");
        $finish;
    end
    initial begin #150000000; $fatal(1,"Preview timeout"); end
endmodule
