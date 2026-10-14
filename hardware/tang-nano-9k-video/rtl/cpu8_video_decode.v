`timescale 1ns/1ps
// Decoder combinatorio. In FPGA usare ingressi gia acquisiti e coerenti
// nel dominio di clock locale; questo modulo NON realizza il crossing TTL.
module cpu8_video_decode (
    input  wire [15:0] addr,
    input  wire        rd_n,
    input  wire        wr_n,
    input  wire        bus_enable,
    output wire        ram_sel,
    output wire        video_sel,
    output wire        ram_oe_n,
    output wire        ram_we_n,
    output wire        video_read,
    output wire        video_write,
    output wire        video_d_oe,
    output wire [13:0] vram_addr,
    output wire [6:0]  row,
    output wire [6:0]  col
);
    // Gli strobe simultanei sono invalidi: nessuna lettura/scrittura.
    wire read_cycle  = !rd_n && wr_n;
    wire write_cycle = rd_n && !wr_n;

    assign ram_sel     = bus_enable && (addr[15:14] == 2'b00);
    assign video_sel   = bus_enable && (addr[15:14] == 2'b01);
    assign ram_oe_n    = !(ram_sel && read_cycle);
    assign ram_we_n    = !(ram_sel && write_cycle);
    assign video_read = video_sel && read_cycle;
    assign video_write = video_sel && write_cycle;
    assign video_d_oe = video_read;
    assign vram_addr = addr[13:0];
    assign row = addr[13:7];
    assign col = addr[6:0];
endmodule
