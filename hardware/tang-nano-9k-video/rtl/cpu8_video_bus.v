`timescale 1ns/1ps
// Bundled-data bus: address/data must remain stable throughout each strobe.
// Eight settle cycles include transceiver direction setup and data acquisition.
module cpu8_video_bus (
    input wire clk, resetn, memory_ready,
    input wire [15:0] cpu_addr,
    input wire [7:0] cpu_data,
    input wire cpu_rd_n, cpu_wr_n, cpu_enable,
    input wire [7:0] memory_data,
    output reg [13:0] memory_addr,
    output reg [7:0] write_data,
    output reg write_enable,
    output wire data_oe,
    output wire buffer_dir,
    output wire buffer_oe_n,
    output wire [7:0] read_data
);
    (* async_reg = "true" *) reg [15:0] addr_meta, addr_sync;
    (* async_reg = "true" *) reg [7:0] data_meta, data_sync;
    (* async_reg = "true" *) reg [2:0] ctrl_meta, ctrl_sync;
    wire enabled = ctrl_sync[2];
    wire rd_n = ctrl_sync[1];
    wire wr_n = ctrl_sync[0];
    wire idle = rd_n && wr_n;
    wire read_cycle = !rd_n && wr_n;
    wire write_cycle = rd_n && !wr_n;

    localparam DISARMED=0, IDLE=1, SETTLE=2, READ_WAIT=3, HOLD=4, READ_ARM=5;
    reg [2:0] state;
    reg [2:0] delay_count;
    reg reading;
    reg response_valid;
    reg [15:0] transaction_addr;
    reg [7:0] response;

    always @(posedge clk) begin
        if (!resetn) begin
            addr_meta <= 0; addr_sync <= 0;
            data_meta <= 0; data_sync <= 0;
            ctrl_meta <= 3'b011; ctrl_sync <= 3'b011;
        end else begin
            addr_meta <= cpu_addr; addr_sync <= addr_meta;
            data_meta <= cpu_data; data_sync <= data_meta;
            ctrl_meta <= {cpu_enable,cpu_rd_n,cpu_wr_n};
            ctrl_sync <= ctrl_meta;
        end
    end

    always @(posedge clk) begin
        write_enable <= 0;
        if (!resetn || !memory_ready || !enabled) begin
            state <= DISARMED;
            delay_count <= 0;
            response_valid <= 0;
            memory_addr <= 0;
            transaction_addr <= 0;
            write_data <= 0;
            response <= 0;
            reading <= 0;
        end else begin
            case (state)
                DISARMED: if (idle) state <= IDLE;
                IDLE: begin
                    response_valid <= 0;
                    if (read_cycle || write_cycle) begin
                        reading <= read_cycle;
                        delay_count <= 0;
                        state <= SETTLE;
                    end else if (!idle) state <= DISARMED;
                end
                SETTLE: begin
                    if ((reading && !read_cycle) || (!reading && !write_cycle))
                        state <= DISARMED;
                    else if (delay_count == 7) begin
                        transaction_addr <= addr_sync;
                        memory_addr <= addr_sync[13:0];
                        if (addr_sync[15:14] != 2'b01) state <= HOLD;
                        else if (reading) begin
                            delay_count <= 0;
                            state <= READ_WAIT;
                        end else begin
                            write_data <= data_sync;
                            write_enable <= 1;
                            state <= HOLD;
                        end
                    end else delay_count <= delay_count + 1'b1;
                end
                READ_WAIT: begin
                    if (!read_cycle) state <= DISARMED;
                    else if (delay_count == 1) begin
                        response <= memory_data;
                        response_valid <= 1;
                        state <= READ_ARM;
                    end else delay_count <= delay_count + 1'b1;
                end
                READ_ARM: begin
                    // FPGA data is driven for one clock with the translator
                    // disabled, before enabling the external A -> B outputs.
                    if (read_cycle) state <= HOLD;
                    else begin
                        response_valid <= 0;
                        state <= DISARMED;
                    end
                end
                HOLD: if (idle) begin
                    response_valid <= 0;
                    state <= IDLE;
                end else if ((!reading && !write_cycle) || (reading && !read_cycle)) begin
                    response_valid <= 0;
                    state <= DISARMED;
                end
                default: state <= DISARMED;
            endcase
        end
    end

    // Asynchronous release/interlock: never wait for a synchronizer to stop
    // driving the physical bus. CPU must still allow buffer turn-around time.
    assign data_oe = resetn && memory_ready && cpu_enable && response_valid &&
                     !cpu_rd_n && cpu_wr_n && (cpu_addr == transaction_addr);
    assign read_data = response;
    // A = FPGA (3.3 V), B = CPU (5 V). DIR: 0 B->A, 1 A->B.
    // Direction changes only when IDLE accepts a new transaction, while OE
    // is high. Writes enable reception BEFORE sampling the CPU data.
    assign buffer_dir = reading;
    wire receive_window = !reading &&
        ((state == SETTLE && delay_count >= 2) || state == HOLD);
    wire receive_enable = resetn && memory_ready && cpu_enable && enabled &&
        cpu_rd_n && !cpu_wr_n && (cpu_addr[15:14] == 2'b01) &&
        (addr_sync[15:14] == 2'b01) && receive_window;
    wire transmit_enable = reading && state == HOLD && data_oe;
    assign buffer_oe_n = !(receive_enable || transmit_enable);
endmodule
