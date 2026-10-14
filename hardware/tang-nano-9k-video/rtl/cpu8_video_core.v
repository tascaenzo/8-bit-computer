`timescale 1ns/1ps
module cpu8_video_core (
    input wire clk, resetn,
    input wire [15:0] cpu_addr,
    input wire [7:0] cpu_data_in,
    input wire cpu_rd_n, cpu_wr_n, cpu_enable,
    output wire [7:0] cpu_data_out,
    output wire cpu_data_oe, ready,
    output wire cpu_buffer_dir, cpu_buffer_oe_n,
    output wire [23:0] rgb,
    output wire de, hsync, vsync
);
    wire [13:0] memory_addr, video_addr;
    wire [7:0] write_data, memory_data, character;
    wire write_enable;
    cpu8_video_bus bus (
        .clk(clk), .resetn(resetn), .memory_ready(ready),
        .cpu_addr(cpu_addr), .cpu_data(cpu_data_in),
        .cpu_rd_n(cpu_rd_n), .cpu_wr_n(cpu_wr_n), .cpu_enable(cpu_enable),
        .memory_data(memory_data), .memory_addr(memory_addr),
        .write_data(write_data), .write_enable(write_enable),
        .data_oe(cpu_data_oe), .read_data(cpu_data_out),
        .buffer_dir(cpu_buffer_dir), .buffer_oe_n(cpu_buffer_oe_n)
    );
    cpu8_vram vram (
        .clk(clk), .resetn(resetn), .cpu_addr(memory_addr),
        .video_addr(video_addr), .cpu_write_data(write_data),
        .cpu_write_enable(write_enable), .cpu_read_data(memory_data),
        .video_data(character), .ready(ready)
    );
    cpu8_text_video display (
        .clk(clk), .resetn(resetn), .memory_ready(ready),
        .character(character), .video_addr(video_addr),
        .rgb(rgb), .de(de), .hsync(hsync), .vsync(vsync)
    );
endmodule
