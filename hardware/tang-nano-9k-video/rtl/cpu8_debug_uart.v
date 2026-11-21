`timescale 1ns/1ps
// Read-only USB-UART telemetry. No CPU bus controls are generated here.
// Live snapshots are useful with the CPU stopped; accepted transaction
// counters/last values are captured at the bus FSM's actual commit pulses.
module cpu8_debug_uart #(
    parameter integer CLK_HZ=25_200_000, BAUD=115200,
    parameter integer SNAPSHOT_CYCLES=CLK_HZ/10
)(
    input wire clk, resetn, boot_run,
    input wire [12:0] cpu_addr,
    input wire [7:0] cpu_data_in, cpu_data_out,
    input wire video_select, key_select, rd_n, wr_n,
    input wire buffer_oe_n, buffer_dir, ready,
    input wire [13:0] pointer,
    input wire [7:0] color, status,
    input wire write_accepted, read_accepted,
    input wire [7:0] write_data,
    output wire tx
);
    localparam integer DIV=(CLK_HZ+BAUD/2)/BAUD;
    localparam integer LINE_BYTES=140;
    (* async_reg="true" *) reg [25:0] raw_meta, raw_sync;
    always @(posedge clk) begin
        if(!resetn) begin raw_meta<=0; raw_sync<=0; end
        else begin
            raw_meta<={cpu_addr,cpu_data_in,boot_run,video_select,key_select,rd_n,wr_n};
            raw_sync<=raw_meta;
        end
    end
    function [15:0] address_of(input [12:0] upper,input video,key);
        address_of={upper,3'b000} | (key && !video ? 16'h0001 : 16'h0000);
    endfunction
    function [7:0] hex1(input [3:0] v);
        hex1=v<10 ? 8'h30+v : 8'h41+(v-10);
    endfunction
    function [15:0] hex8(input [7:0] v);
        hex8={hex1(v[7:4]),hex1(v[3:0])};
    endfunction
    function [31:0] hex16(input [15:0] v);
        hex16={hex8(v[15:8]),hex8(v[7:0])};
    endfunction
    function [63:0] hex32(input [31:0] v);
        hex32={hex16(v[31:16]),hex16(v[15:0])};
    endfunction
    reg [31:0] writes,reads;
    reg [15:0] last_wa,last_ra;
    reg [7:0] last_wd,last_rv;
    reg s_boot,s_rd,s_wr,s_valid,s_oe_n,s_dir,s_ready;
    reg [1:0] s_y;
    reg [15:0] s_address,s_mask,s_wa,s_ra;
    reg [13:0] s_pointer;
    reg [7:0] s_data,s_response,s_color,s_status,s_wd,s_rv;
    reg [31:0] s_writes,s_reads;
    wire [LINE_BYTES*8-1:0] line_text={"CPU8v1",
        " B=", hex1({3'b0,s_boot}),
        " Y=", hex1({2'b0,s_y}),
        " RD=", hex1({3'b0,s_rd}),
        " WR=", hex1({3'b0,s_wr}),
        " A=", hex16(s_address),
        " M=", hex16(s_mask),
        " DI=", hex8(s_data),
        " DV=", hex1({3'b0,s_valid}),
        " DO=", hex8(s_response),
        " OE=", hex1({3'b0,s_oe_n}),
        " DIR=", hex1({3'b0,s_dir}),
        " RDY=", hex1({3'b0,s_ready}),
        " P=", hex16({2'b0,s_pointer}),
        " C=", hex8(s_color),
        " S=", hex8(s_status),
        " W=", hex32(s_writes),
        " R=", hex32(s_reads),
        " WA=", hex16(s_wa),
        " WD=", hex8(s_wd),
        " RA=", hex16(s_ra),
        " RV=", hex8(s_rv), 8'h0a};
    reg [$clog2(SNAPSHOT_CYCLES+1)-1:0] snapshot_timer;
    reg [$clog2(LINE_BYTES+1)-1:0] position;
    reg frame_active, sending;
    reg [$clog2(DIV+1)-1:0] baud_timer;
    reg [3:0] bits_left;
    reg [9:0] shift;
    assign tx=shift[0];
    always @(posedge clk) begin
        if(!resetn) begin
            writes<=0; reads<=0; last_wa<=16'hffff; last_ra<=16'hffff;
            last_wd<=0; last_rv<=0;
            snapshot_timer<=0; position<=0; frame_active<=0; sending<=0;
            baud_timer<=0; bits_left<=0; shift<=10'h3ff;
            s_boot<=1; s_y<=0; s_rd<=1; s_wr<=1; s_address<=0; s_mask<=16'hfff8;
            s_data<=0; s_valid<=0; s_response<=0; s_oe_n<=1; s_dir<=0; s_ready<=0;
            s_pointer<=0; s_color<=0; s_status<=0;
            s_writes<=0; s_reads<=0; s_wa<=16'hffff; s_ra<=16'hffff; s_wd<=0; s_rv<=0;
        end else begin
            if(write_accepted) begin
                writes<=writes+1'b1; last_wa<=address_of(cpu_addr,video_select,key_select);
                last_wd<=write_data;
            end
            if(read_accepted) begin
                reads<=reads+1'b1; last_ra<=address_of(cpu_addr,video_select,key_select);
                last_rv<=cpu_data_out;
            end
            if(snapshot_timer==SNAPSHOT_CYCLES-1) begin
                snapshot_timer<=0;
                if(!frame_active) begin
                    s_boot<=raw_sync[4]; s_y<=raw_sync[3:2];
                    s_rd<=raw_sync[1]; s_wr<=raw_sync[0]; s_data<=raw_sync[12:5];
                    s_address<=address_of(raw_sync[25:13],raw_sync[3],raw_sync[2]);
                    s_mask<=raw_sync[3]^raw_sync[2] ? 16'hffff : 16'hfff8;
                    s_valid<=!buffer_oe_n; s_response<=cpu_data_out;
                    s_oe_n<=buffer_oe_n; s_dir<=buffer_dir; s_ready<=ready;
                    s_pointer<=pointer; s_color<=color; s_status<=status;
                    s_writes<=writes; s_reads<=reads;
                    s_wa<=last_wa; s_wd<=last_wd; s_ra<=last_ra; s_rv<=last_rv;
                    position<=0; frame_active<=1;
                end
            end else snapshot_timer<=snapshot_timer+1'b1;
            if(sending) begin
                if(baud_timer==0) begin
                    shift<={1'b1,shift[9:1]}; baud_timer<=DIV-1;
                    if(bits_left==1) begin sending<=0; bits_left<=0; end
                    else bits_left<=bits_left-1'b1;
                end else baud_timer<=baud_timer-1'b1;
            end else if(frame_active) begin
                if(position==LINE_BYTES) begin frame_active<=0; end
                else begin
                    shift<={1'b1,line_text[(LINE_BYTES-1-position)*8 +: 8],1'b0};
                    bits_left<=10; baud_timer<=DIV-1; sending<=1;
                    position<=position+1'b1;
                end
            end
        end
    end
endmodule
