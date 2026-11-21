`timescale 1ns/1ps
module cpu8_reset_tb;
    reg clk=0, clock_running=1;
    always #5 if(clock_running) clk=~clk;
    reg board_resetn=0, pll_lock=0, cpu_reset=0;
    wire request_n, core_resetn, low_request_n, low_core_resetn;
    cpu8_reset #(.CPU_RESET_ACTIVE_HIGH(1)) dut(.clk(clk), .board_resetn(board_resetn), .pll_lock(pll_lock),
        .cpu_reset(cpu_reset), .reset_request_n(request_n), .core_resetn(core_resetn));
    cpu8_reset #(.CPU_RESET_ACTIVE_HIGH(0)) active_low(
        .clk(clk), .board_resetn(board_resetn), .pll_lock(pll_lock),
        .cpu_reset(!cpu_reset), .reset_request_n(low_request_n), .core_resetn(low_core_resetn));
    task check_release;
        begin
            for(integer i=0;i<4;i=i+1) begin
                @(posedge clk); #1;
                if(core_resetn !== (i==3) || low_core_resetn !== (i==3))
                    $fatal(1,"Reset release not synchronized to four clocks");
            end
            @(negedge clk);
        end
    endtask
    task check_asserted;
        begin
            #1;
            if(request_n!==0 || core_resetn!==0 || low_request_n!==0 || low_core_resetn!==0)
                $fatal(1,"Reset did not assert asynchronously");
        end
    endtask
    initial begin
        #2; check_asserted();
        @(negedge clk); board_resetn=1; pll_lock=1; check_release();
        // A pulse shorter than a clock must still clear synchronous core state.
        #1; cpu_reset=1; check_asserted();
        #1; cpu_reset=0; check_release();
        board_resetn=0; check_asserted();
        board_resetn=1; check_release();
        pll_lock=0; check_asserted();
        pll_lock=1; check_release();
        // Physical bus gating must work even if the pixel clock is stopped.
        clock_running=0; #3; cpu_reset=1; check_asserted();
        cpu_reset=0; #20;
        if(core_resetn || low_core_resetn) $fatal(1,"Reset released without a clock");
        clock_running=1; check_release();
        $display("PASS: CPU/board/PLL reset, short pulses, stopped clock, synchronized release, both polarities");
        $finish;
    end
    initial begin #2000; $fatal(1,"Reset test timeout"); end
endmodule
