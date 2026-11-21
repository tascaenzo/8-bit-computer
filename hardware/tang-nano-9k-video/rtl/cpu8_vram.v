`timescale 1ns/1ps
module cpu8_vram (
    input wire clk, resetn,
    input wire [13:0] cpu_addr, video_addr,
    input wire [7:0] cpu_write_data, cpu_write_attr,
    input wire cpu_write_enable,
    output reg [7:0] cpu_read_data, video_data, cpu_read_attr, video_attr,
    output reg ready
);
    // One read/write CPU port and one read-only display port, same clock.
    // No reset on the memory array: preserve block RAM inference.
    // A simultaneous display read / CPU write may show old or new pixels.
    // Do not duplicate BRAMs to emulate collision values that video does not need.
    (* no_rw_check *) reg [7:0] cells [0:16383];
    (* no_rw_check *) reg [7:0] attrs [0:16383];
    reg [13:0] clear_addr;
    wire clearing = !ready;
    wire [13:0] write_addr = clearing ? clear_addr : cpu_addr;
    wire [7:0] write_value = clearing ? 8'h20 : cpu_write_data;
    wire write_valid = resetn && (clearing || cpu_write_enable);
    always @(posedge clk) begin
        if (write_valid) begin
            cells[write_addr] <= write_value;
            attrs[write_addr] <= clearing ? 8'h0f : cpu_write_attr;
        end
        // Read only on non-write CPU cycles (native DP no-change mode).
        // The scroll engine reads before writing, so no collision value is needed.
        if (!write_valid) begin
            cpu_read_data <= cells[write_addr];
            cpu_read_attr <= attrs[write_addr];
        end
        video_data <= cells[video_addr];
        video_attr <= attrs[video_addr];
    end
    always @(posedge clk) begin
        if (!resetn) begin
            ready <= 0;
            clear_addr <= 0;
        end else if (!ready) begin
            if (clear_addr == 14'h3fff) ready <= 1;
            else clear_addr <= clear_addr + 1'b1;
        end
    end
endmodule
