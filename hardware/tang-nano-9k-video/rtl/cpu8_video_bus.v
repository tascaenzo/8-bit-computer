`timescale 1ns/1ps
// CPU holds selection, address and write data stable during the strobe.
// cpu_addr is the physical A15..A3 bus. The 74238 decodes A2..A0.
// Adjacent registers of one peripheral are eight CPU addresses apart.
module cpu8_video_bus (
    input wire clk, resetn,
    input wire [12:0] cpu_addr,
    input wire [7:0] cpu_data,
    input wire cpu_rd_n, cpu_wr_n, video_select, key_select,
    input wire video_ready,
    input wire [7:0] video_status, video_register_data,
    input wire [7:0] key_data, key_status,
    output wire [3:0] reg_id,
    output wire [7:0] write_data,
    output wire write_enable, key_take, read_accepted,
    output wire data_oe, buffer_dir, buffer_oe_n,
    output reg [7:0] read_data
);
    localparam NONE=0, VIDEO_DATA=1,
               VIDEO_STATUS=4, KEY_DATA=5, KEY_STATUS=6, KEY_CTRL=7, VIDEO_CMD=8, VIDEO_COLOR=9, CURSOR_X=10,
               CURSOR_Y=11, VIDEO_CONTROL=12;
    function [3:0] decode;
        input [1:0] selection;
        input [12:0] address;
        input rd_n, wr_n;
        begin
            decode = NONE;
            if (rd_n && !wr_n) begin
                if (selection == 2'b10) begin
                    case (address)
                        13'h400: decode = VIDEO_DATA;
                        13'h404: decode = VIDEO_CMD;
                        13'h405: decode = VIDEO_COLOR;
                        13'h406: decode = CURSOR_X;
                        13'h407: decode = CURSOR_Y;
                        13'h408: decode = VIDEO_CONTROL;
                        default: decode = NONE;
                    endcase
                end else if (selection == 2'b01 && address == 13'h402)
                    decode = KEY_CTRL;
            end else if (!rd_n && wr_n) begin
                if (selection == 2'b10) begin
                    case(address)
                        13'h403: decode = VIDEO_STATUS;
                        13'h405: decode = VIDEO_COLOR;
                        13'h406: decode = CURSOR_X;
                        13'h407: decode = CURSOR_Y;
                        13'h408: decode = VIDEO_CONTROL;
                        default: decode = NONE;
                    endcase
                end
                else if (selection == 2'b01) begin
                    case (address)
                        13'h400: decode = KEY_DATA;
                        13'h401: decode = KEY_STATUS;
                        default: decode = NONE;
                    endcase
                end
            end
        end
    endfunction

    (* async_reg = "true" *) reg [16:0] request_meta, request_sync;
    (* async_reg = "true" *) reg [7:0] data_meta, data_sync;
    always @(posedge clk) begin
        if (!resetn) begin
            request_meta <= 17'h00003; request_sync <= 17'h00003;
            data_meta <= 0; data_sync <= 0;
        end else begin
            request_meta <= {cpu_addr,video_select,key_select,cpu_rd_n,cpu_wr_n};
            request_sync <= request_meta;
            data_meta <= cpu_data; data_sync <= data_meta;
        end
    end

    localparam IDLE=0, SETTLE=1, READ_ARM=2, HOLD=3;
    reg [1:0] state;
    reg [2:0] delay_count;
    reg reading, response_valid;
    reg [16:0] transaction;
    reg [3:0] target;
    wire [3:0] decoded = decode(request_sync[3:2], request_sync[16:4],
                               request_sync[1], request_sync[0]);
    wire physical_match = {cpu_addr,video_select,key_select,cpu_rd_n,cpu_wr_n} == transaction;
    wire settled = resetn && physical_match && request_sync == transaction;
    // Accept once, after allowing the B->A translator and data synchronizer to settle.
    assign write_enable = settled && state == SETTLE && !reading &&
                          delay_count == 7 && decoded == target;
    assign write_data = data_sync;
    assign reg_id = target;
    // Zero is the empty-buffer sentinel. A key arriving after an empty
    // response was captured belongs to the next read.
    assign read_accepted = settled && state == READ_ARM;
    assign key_take = settled && state == READ_ARM &&
                      target == KEY_DATA && read_data != 0;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            reading <= 0;
            response_valid <= 0;
            target <= NONE;
            transaction <= 0;
            delay_count <= 0;
            read_data <= 0;
        end else begin
            case (state)
                IDLE: if (decoded != NONE) begin
                    response_valid <= 0;
                    transaction <= request_sync;
                    target <= decoded;
                    reading <= !request_sync[1];
                    delay_count <= 0;
                    state <= request_sync[3:2] == 2'b10 && request_sync[1] &&
                             !video_ready ? HOLD : SETTLE;
                end
                SETTLE: if (request_sync != transaction) state <= IDLE;
                else if (delay_count == 7) begin
                    state <= HOLD;
                    if (reading && settled) begin
                        case (target)
                            VIDEO_STATUS: read_data <= video_status;
                            KEY_DATA: read_data <= key_data;
                            KEY_STATUS: read_data <= key_status;
                            default: read_data <= video_register_data;
                        endcase
                        response_valid <= 1;
                        state <= READ_ARM;
                    end
                end else delay_count <= delay_count + 1'b1;
                READ_ARM: if (settled) state <= HOLD;
                          else state <= IDLE;
                HOLD: if (request_sync != transaction) state <= IDLE;
            endcase
        end
    end

    assign buffer_dir = reading;
    // Qualify with live controls so the physical bus is released without
    // waiting for the FPGA synchronizer after the CPU ends the read.
    assign data_oe = resetn && physical_match && reading && response_valid &&
                     (state == READ_ARM || state == HOLD);
    wire receive_enable = settled && !reading &&
                          state == SETTLE && delay_count >= 2;
    assign buffer_oe_n = !(receive_enable || (data_oe && state == HOLD));
endmodule
