`timescale 1ns/1ps
module cpu8_video_core #(
    parameter VIDEO_720P = 0,
    parameter VIDEO_50HZ = 0
)(
    input wire clk, resetn,
    input wire boot_run, // 1 = BOOT screen and isolated CPU bus; 0 = RUN
    input wire [12:0] cpu_addr,
    input wire [7:0] cpu_data_in,
    input wire cpu_rd_n, cpu_wr_n, video_select, key_select,
    input wire ps2_clk, ps2_data,
    output wire [7:0] cpu_data_out,
    output wire cpu_data_oe, ready, debug_tx,
    output wire cpu_buffer_dir, cpu_buffer_oe_n,
    output wire [23:0] rgb,
    output wire de, hsync, vsync
);
    localparam VIDEO_DATA=1, VIDEO_STATUS=4, KEY_CTRL=7,
               VIDEO_CMD=8, VIDEO_COLOR=9, CURSOR_X=10, CURSOR_Y=11, VIDEO_CONTROL=12;
    localparam IDLE=0, CLEAR=1, SCROLL_READ=2, SCROLL_CAPTURE=3, SCROLL_WRITE=4;
    reg [2:0] engine;
    reg [13:0] pointer, job_addr;
    reg [7:0] color, control, copy_character, copy_attr, job_color;
    reg [26:0] blink_counter;
    wire [13:0] video_addr;
    wire [7:0] write_data, key_data, key_status, vram_character, vram_attr;
    wire [7:0] memory_character, memory_attr;
    wire vram_ready, splash_active;
    wire [7:0] splash_character, splash_attr;
    wire [7:0] character = splash_active ? splash_character : vram_character;
    wire [7:0] attribute = splash_active ? splash_attr : vram_attr;
    (* async_reg = "true" *) reg run_meta, run_sync;
    always @(posedge clk) begin
        if (!resetn) begin run_meta <= 0; run_sync <= 0; end
        else begin run_meta <= !boot_run; run_sync <= run_meta; end
    end
    wire cpu_run = resetn && !boot_run && run_sync;
    assign splash_active = !run_sync;
    assign ready = vram_ready && cpu_run && engine==IDLE;
    wire [7:0] status = {6'b0, (!vram_ready || engine!=IDLE), ready};
    cpu8_boot_screen #(.CLK_HZ(VIDEO_720P ? 74_250_000 : 25_200_000)) boot_screen(
        .clk(clk), .resetn(resetn), .active(splash_active), .video_addr(video_addr),
        .character(splash_character), .attribute(splash_attr));

    wire [3:0] reg_id;
    wire write_enable, key_take, read_accepted;
    wire video_write = write_enable && reg_id == VIDEO_DATA;
    wire [6:0] cursor_x=pointer[6:0], cursor_y=pointer[13:7];
    wire cursor_visible = !splash_active && control[0] &&
                          (!control[1] || blink_counter < (VIDEO_720P ? 37_125_000 : 12_600_000));
    reg [7:0] register_data;
    always @* begin
        case(reg_id)
            VIDEO_COLOR: register_data=color;
            CURSOR_X: register_data={1'b0,cursor_x};
            CURSOR_Y: register_data={1'b0,cursor_y};
            VIDEO_CONTROL: register_data=control;
            default: register_data=0;
        endcase
    end
    // CPU port is shared with the clear/scroll engine. Busy video writes
    // are ignored; keyboard operations and VIDEO_STATUS reads remain usable.
    wire engine_write = engine==CLEAR || engine==SCROLL_WRITE;
    wire [13:0] memory_addr = engine==SCROLL_READ || engine==SCROLL_CAPTURE ?
                             job_addr+14'd128 : engine!=IDLE ? job_addr : pointer;
    wire [7:0] memory_write_character = engine==CLEAR ||
                (engine==SCROLL_WRITE && job_addr>=14'd7552) ? 8'h20 :
                engine==SCROLL_WRITE ? copy_character : write_data;
    wire [7:0] memory_write_attr = engine==CLEAR ||
                (engine==SCROLL_WRITE && job_addr>=14'd7552) ? job_color :
                engine==SCROLL_WRITE ? copy_attr : color;
    always @(posedge clk) begin
        if(!resetn) begin
            pointer<=0; color<=8'h0f; control<=8'h1c;
            engine<=IDLE; job_addr<=0; job_color<=8'h0f;
            copy_character<=8'h20; copy_attr<=8'h0f; blink_counter<=0;
        end else begin
            if(blink_counter==(VIDEO_720P ? 74_249_999 : 25_199_999)) blink_counter<=0;
            else blink_counter<=blink_counter+1'b1;
            case(engine)
                CLEAR: if(job_addr==14'd7679) engine<=IDLE;
                       else job_addr<=job_addr+1'b1;
                SCROLL_READ: engine<=SCROLL_CAPTURE;
                SCROLL_CAPTURE: begin
                    copy_character<=memory_character; copy_attr<=memory_attr;
                    engine<=SCROLL_WRITE;
                end
                SCROLL_WRITE: if(job_addr==14'd7679) engine<=IDLE;
                              else begin job_addr<=job_addr+1'b1; engine<=SCROLL_READ; end
                default: begin end
            endcase
            if(write_enable && cpu_run && engine==IDLE) begin
                case(reg_id)
                    VIDEO_COLOR: color<=write_data;
                    CURSOR_X: if(write_data<80) pointer[6:0]<=write_data[6:0];
                    CURSOR_Y: if(write_data<60) pointer[13:7]<=write_data[6:0];
                    VIDEO_CONTROL: control<=write_data & 8'h1f;
                    VIDEO_DATA: if(control[2]) begin
                        if(control[3] && cursor_x>=79) begin
                            pointer[6:0]<=0;
                            if(cursor_y<59) pointer[13:7]<=cursor_y+1'b1;
                            else if(control[4]) begin
                                pointer[13:7]<=59;
                                engine<=SCROLL_READ; job_addr<=0; job_color<=color;
                            end
                        end else pointer<=pointer+1'b1;
                    end
                    VIDEO_CMD: case(write_data)
                        1: begin // Clear visible screen (including row padding), home.
                            pointer<=0; job_addr<=0; job_color<=color; engine<=CLEAR;
                        end
                        2: pointer<=0;
                        3: begin // Newline, optional scroll on the bottom row.
                            pointer[6:0]<=0;
                            if(cursor_y<59) pointer[13:7]<=cursor_y+1'b1;
                            else if(control[4]) begin
                                pointer[13:7]<=59;
                                engine<=SCROLL_READ; job_addr<=0; job_color<=color;
                            end
                        end
                        4: begin // Explicit scroll up one line.
                            pointer<=14'd7552; job_addr<=0; job_color<=color; engine<=SCROLL_READ;
                        end
                        5: pointer[6:0]<=0;
                        default: begin end
                    endcase
                    default: begin end
                endcase
            end
        end
    end

    cpu8_video_bus bus (
        .clk(clk), .resetn(resetn), .video_ready(ready),
        .video_status(status), .video_register_data(register_data),
        .cpu_addr(cpu_addr), .cpu_data(cpu_data_in),
        .cpu_rd_n(cpu_rd_n), .cpu_wr_n(cpu_wr_n),
        .video_select(video_select && cpu_run), .key_select(key_select && cpu_run),
        .key_data(key_data), .key_status(key_status), .key_take(key_take), .read_accepted(read_accepted),
        .reg_id(reg_id), .write_data(write_data), .write_enable(write_enable),
        .data_oe(cpu_data_oe), .read_data(cpu_data_out),
        .buffer_dir(cpu_buffer_dir), .buffer_oe_n(cpu_buffer_oe_n)
    );
    cpu8_debug_uart #(.CLK_HZ(VIDEO_720P ? 74_250_000 : 25_200_000)) debug_uart(
        .clk(clk), .resetn(resetn), .boot_run(boot_run), .cpu_addr(cpu_addr),
        .cpu_data_in(cpu_data_in), .cpu_data_out(cpu_data_out),
        .video_select(video_select), .key_select(key_select),
        .rd_n(cpu_rd_n), .wr_n(cpu_wr_n),
        .buffer_oe_n(cpu_buffer_oe_n), .buffer_dir(cpu_buffer_dir), .ready(ready),
        .pointer(pointer), .color(color), .status(status),
        .write_accepted(write_enable), .read_accepted(read_accepted),
        .write_data(write_data), .tx(debug_tx));
    cpu8_ps2_keyboard #(.FRAME_TIMEOUT(VIDEO_720P ? 148500 : 50400)) keyboard (
        .clk(clk), .resetn(resetn), .ps2_clk(ps2_clk), .ps2_data(ps2_data),
        .take(key_take), .clear_flags(write_enable && reg_id == KEY_CTRL ? write_data[1:0] : 2'b0),
        .event_data(key_data), .status(key_status)
    );
    cpu8_vram vram (
        .clk(clk), .resetn(resetn), .cpu_addr(memory_addr),
        .video_addr(video_addr), .cpu_write_data(memory_write_character), .cpu_write_attr(memory_write_attr),
        .cpu_write_enable(video_write || engine_write), .cpu_read_data(memory_character),
        .cpu_read_attr(memory_attr), .video_attr(vram_attr),
        .video_data(vram_character), .ready(vram_ready)
    );
    cpu8_text_video #(.VIDEO_720P(VIDEO_720P), .VIDEO_50HZ(VIDEO_50HZ)) display (
        .clk(clk), .resetn(resetn), .memory_ready(splash_active || vram_ready),
        .character(character), .attribute(attribute),
        .cursor_addr(pointer), .cursor_visible(cursor_visible), .video_addr(video_addr),
        .rgb(rgb), .de(de), .hsync(hsync), .vsync(vsync)
    );
endmodule
