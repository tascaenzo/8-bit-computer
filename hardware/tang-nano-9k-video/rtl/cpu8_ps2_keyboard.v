`timescale 1ns/1ps
module cpu8_ps2_keyboard #(
    parameter integer FRAME_TIMEOUT = 50400 // 2 ms at 25.2 MHz
)(
    input wire clk, resetn, ps2_clk, ps2_data, take,
    input wire [1:0] clear_flags,
    output wire [7:0] event_data, status
);
    (* async_reg = "true" *) reg clk_meta, clk_sync, data_meta, data_sync;
    reg clk_previous;
    wire falling = clk_previous && !clk_sync;
    always @(posedge clk) begin
        if (!resetn) begin
            clk_meta <= 1; clk_sync <= 1; clk_previous <= 1;
            data_meta <= 1; data_sync <= 1;
        end else begin
            clk_meta <= ps2_clk; clk_sync <= clk_meta; clk_previous <= clk_sync;
            data_meta <= ps2_data; data_sync <= data_meta;
        end
    end

    reg [3:0] bit_count;
    reg [$clog2(FRAME_TIMEOUT+1)-1:0] timeout_count;
    reg [7:0] scan;
    reg parity;
    reg extended, released, left_shift, right_shift, caps, caps_down;
    reg ready, overrun, parity_error, frame_error;
    reg [7:0] pending;
    wire shift = left_shift || right_shift;
    wire [7:0] character = translate(scan, extended, shift, caps);
    assign event_data = ready ? pending : 8'h00;
    assign status = {4'b0,frame_error,parity_error,overrun,ready};

    function [7:0] translate;
        input [7:0] code;
        input ext, shifted, capital;
        begin
            translate = 0;
            if (ext) begin
                case (code)
                    8'h75: translate = 8'h80;
                    8'h72: translate = 8'h81;
                    8'h6b: translate = 8'h82;
                    8'h74: translate = 8'h83;
                    default: translate = 0;
                endcase
            end else begin
                case (code)
                    8'h1c: translate = (shifted ^ capital) ? 8'h41 : 8'h61;
                    8'h32: translate = (shifted ^ capital) ? 8'h42 : 8'h62;
                    8'h21: translate = (shifted ^ capital) ? 8'h43 : 8'h63;
                    8'h23: translate = (shifted ^ capital) ? 8'h44 : 8'h64;
                    8'h24: translate = (shifted ^ capital) ? 8'h45 : 8'h65;
                    8'h2b: translate = (shifted ^ capital) ? 8'h46 : 8'h66;
                    8'h34: translate = (shifted ^ capital) ? 8'h47 : 8'h67;
                    8'h33: translate = (shifted ^ capital) ? 8'h48 : 8'h68;
                    8'h43: translate = (shifted ^ capital) ? 8'h49 : 8'h69;
                    8'h3b: translate = (shifted ^ capital) ? 8'h4a : 8'h6a;
                    8'h42: translate = (shifted ^ capital) ? 8'h4b : 8'h6b;
                    8'h4b: translate = (shifted ^ capital) ? 8'h4c : 8'h6c;
                    8'h3a: translate = (shifted ^ capital) ? 8'h4d : 8'h6d;
                    8'h31: translate = (shifted ^ capital) ? 8'h4e : 8'h6e;
                    8'h44: translate = (shifted ^ capital) ? 8'h4f : 8'h6f;
                    8'h4d: translate = (shifted ^ capital) ? 8'h50 : 8'h70;
                    8'h15: translate = (shifted ^ capital) ? 8'h51 : 8'h71;
                    8'h2d: translate = (shifted ^ capital) ? 8'h52 : 8'h72;
                    8'h1b: translate = (shifted ^ capital) ? 8'h53 : 8'h73;
                    8'h2c: translate = (shifted ^ capital) ? 8'h54 : 8'h74;
                    8'h3c: translate = (shifted ^ capital) ? 8'h55 : 8'h75;
                    8'h2a: translate = (shifted ^ capital) ? 8'h56 : 8'h76;
                    8'h1d: translate = (shifted ^ capital) ? 8'h57 : 8'h77;
                    8'h22: translate = (shifted ^ capital) ? 8'h58 : 8'h78;
                    8'h35: translate = (shifted ^ capital) ? 8'h59 : 8'h79;
                    8'h1a: translate = (shifted ^ capital) ? 8'h5a : 8'h7a;
                    8'h16: translate = shifted ? 8'h21 : 8'h31;
                    8'h1e: translate = shifted ? 8'h40 : 8'h32;
                    8'h26: translate = shifted ? 8'h23 : 8'h33;
                    8'h25: translate = shifted ? 8'h24 : 8'h34;
                    8'h2e: translate = shifted ? 8'h25 : 8'h35;
                    8'h36: translate = shifted ? 8'h5e : 8'h36;
                    8'h3d: translate = shifted ? 8'h26 : 8'h37;
                    8'h3e: translate = shifted ? 8'h2a : 8'h38;
                    8'h46: translate = shifted ? 8'h28 : 8'h39;
                    8'h45: translate = shifted ? 8'h29 : 8'h30;
                    8'h4e: translate = shifted ? 8'h5f : 8'h2d;
                    8'h55: translate = shifted ? 8'h2b : 8'h3d;
                    8'h54: translate = shifted ? 8'h7b : 8'h5b;
                    8'h5b: translate = shifted ? 8'h7d : 8'h5d;
                    8'h5d: translate = shifted ? 8'h7c : 8'h5c;
                    8'h4c: translate = shifted ? 8'h3a : 8'h3b;
                    8'h52: translate = shifted ? 8'h22 : 8'h27;
                    8'h41: translate = shifted ? 8'h3c : 8'h2c;
                    8'h49: translate = shifted ? 8'h3e : 8'h2e;
                    8'h4a: translate = shifted ? 8'h3f : 8'h2f;
                    8'h0e: translate = shifted ? 8'h7e : 8'h60;
                    8'h29: translate = 8'h20;
                    8'h66: translate = 8'h08;
                    8'h0d: translate = 8'h09;
                    8'h5a: translate = 8'h0d;
                    8'h76: translate = 8'h1b;
                    default: translate = 0;
                endcase
            end
        end
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            bit_count <= 0; timeout_count <= 0; scan <= 0; parity <= 0;
            extended <= 0; released <= 0;
            left_shift <= 0; right_shift <= 0; caps <= 0; caps_down <= 0;
            ready <= 0; pending <= 0;
            overrun <= 0; parity_error <= 0; frame_error <= 0;
        end else begin
            if (take) ready <= 0;
            if (clear_flags[0]) overrun <= 0;
            if (clear_flags[1]) begin
                parity_error <= 0;
                frame_error <= 0;
            end

            if (falling) begin
                timeout_count <= 0;
                if (bit_count == 0) begin
                    if (!data_sync) bit_count <= 1;
                    else begin
                        frame_error <= 1;
                        extended <= 0; released <= 0;
                    end
                end else if (bit_count <= 8) begin
                    scan <= {data_sync,scan[7:1]};
                    bit_count <= bit_count + 1'b1;
                end else if (bit_count == 9) begin
                    parity <= data_sync;
                    bit_count <= 10;
                end else begin
                    bit_count <= 0;
                    if (!data_sync || !(^{scan,parity})) begin
                        if (!data_sync) frame_error <= 1;
                        if (!(^{scan,parity})) parity_error <= 1;
                        extended <= 0; released <= 0;
                    end else if (scan == 8'he0) extended <= 1;
                    else if (scan == 8'hf0) released <= 1;
                    else begin
                        extended <= 0; released <= 0;
                        if (!extended && scan == 8'h12) left_shift <= !released;
                        else if (!extended && scan == 8'h59) right_shift <= !released;
                        else if (!extended && scan == 8'h58) begin
                            caps_down <= !released;
                            if (!released && !caps_down) caps <= !caps;
                        end else if (!released && character != 0) begin
                            if (ready && !take) overrun <= 1;
                            else begin
                                pending <= character;
                                ready <= 1;
                            end
                        end
                    end
                end
            end else if (bit_count != 0) begin
                if (timeout_count == FRAME_TIMEOUT-1) begin
                    bit_count <= 0;
                    timeout_count <= 0;
                    frame_error <= 1;
                    extended <= 0; released <= 0;
                end else timeout_count <= timeout_count + 1'b1;
            end
        end
    end
endmodule
