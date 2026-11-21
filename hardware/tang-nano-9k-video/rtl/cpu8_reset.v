`timescale 1ns/1ps
// All reset sources assert immediately; release is synchronized to the pixel
// clock. Even a short external pulse holds the core reset for four clocks.
module cpu8_reset #(
    parameter CPU_RESET_ACTIVE_HIGH = 0
)(
    input wire clk, board_resetn, pll_lock, cpu_reset,
    output wire reset_request_n, core_resetn
);
    wire cpu_reset_active = CPU_RESET_ACTIVE_HIGH ? cpu_reset : !cpu_reset;
    assign reset_request_n = board_resetn && pll_lock && !cpu_reset_active;
    (* async_reg = "true" *) reg [3:0] release_pipe = 0;
    always @(posedge clk or negedge reset_request_n) begin
        if (!reset_request_n) release_pipe <= 0;
        else release_pipe <= {release_pipe[2:0], 1'b1};
    end
    assign core_resetn = release_pipe[3];
endmodule
