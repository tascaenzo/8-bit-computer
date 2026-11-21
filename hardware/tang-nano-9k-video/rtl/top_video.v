`timescale 1ns/1ps
module top_video (
    input wire clk, resetn, boot_run, cpu_reset_n,
    input wire [15:3] cpu_addr,
    inout wire [7:0] cpu_data,
    input wire cpu_rd_n, cpu_wr_n, video_select, key_select,
    input wire ps2_clk, ps2_data,
    output wire cpu_buffer_oe_n, cpu_buffer_dir, video_ready_n, debug_tx,
    output wire tmds_clk_p, tmds_clk_n,
    output wire [2:0] tmds_d_p, tmds_d_n
);
    // Explicit pads make both the CPU bus and HDMI pin assignment unambiguous.
    wire clk_i, resetn_i, cpu_reset_n_i, boot_run_i, rd_i, wr_i, video_select_i, key_select_i, ps2_clk_i, ps2_data_i;
    wire [15:3] addr_i;
    wire [7:0] data_i;
    IBUF clock_pad(.I(clk), .O(clk_i));
    IBUF boot_run_pad(.I(boot_run), .O(boot_run_i));
    IBUF reset_pad(.I(resetn), .O(resetn_i));
    IBUF cpu_reset_pad(.I(cpu_reset_n), .O(cpu_reset_n_i));
    IBUF read_pad(.I(cpu_rd_n), .O(rd_i));
    IBUF write_pad(.I(cpu_wr_n), .O(wr_i));
    IBUF video_select_pad(.I(video_select), .O(video_select_i));
    IBUF key_select_pad(.I(key_select), .O(key_select_i));
    IBUF ps2_clk_pad(.I(ps2_clk), .O(ps2_clk_i));
    IBUF ps2_data_pad(.I(ps2_data), .O(ps2_data_i));
    IBUF address_pads[15:3](.I(cpu_addr), .O(addr_i));
    wire clk_pixel, clk_5x, pll_lock;
`ifdef CPU8_720P
    localparam VIDEO_720P = 1;
    // 27 MHz * 55 / 4 = 371.25 MHz, then CLKDIV /5 = 74.25 MHz.
    Gowin_rPLL #(.IDIV(3), .FBDIV(54), .ODIV(2)) pll
        (.clkin(clk_i), .clkout(clk_5x), .lock(pll_lock));
`else
    localparam VIDEO_720P = 0;
    Gowin_rPLL pll(.clkin(clk_i), .clkout(clk_5x), .lock(pll_lock));
`endif
    Gowin_CLKDIV divider(.hclkin(clk_5x), .clkout(clk_pixel), .resetn(pll_lock));
    wire reset_request_n, core_resetn;
    cpu8_reset reset_control (
        .clk(clk_pixel), .board_resetn(resetn_i), .pll_lock(pll_lock),
        .cpu_reset(cpu_reset_n_i), .reset_request_n(reset_request_n),
        .core_resetn(core_resetn)
    );
    wire [7:0] data_out;
    wire data_oe;
    wire buffer_dir_i, buffer_oe_n_i;
    wire ready_i, debug_tx_i;
    wire [23:0] rgb;
    wire de, hsync, vsync;
`ifdef CPU8_50HZ
    localparam VIDEO_50HZ = 1;
`else
    localparam VIDEO_50HZ = 0;
`endif
    cpu8_video_core #(.VIDEO_720P(VIDEO_720P), .VIDEO_50HZ(VIDEO_50HZ)) core (
        .clk(clk_pixel), .resetn(core_resetn), .boot_run(boot_run_i), .cpu_addr(addr_i),
        .cpu_data_in(data_i), .cpu_rd_n(rd_i), .cpu_wr_n(wr_i),
        .video_select(video_select_i), .key_select(key_select_i),
        .ps2_clk(ps2_clk_i), .ps2_data(ps2_data_i), .cpu_data_out(data_out),
        .cpu_data_oe(data_oe), .ready(ready_i), .debug_tx(debug_tx_i),
        .cpu_buffer_dir(buffer_dir_i), .cpu_buffer_oe_n(buffer_oe_n_i), .rgb(rgb),
        .de(de), .hsync(hsync), .vsync(vsync)
    );
    // Board/CPU reset and LOCK release physical outputs without a pixel clock.
    wire physical_oe = data_oe && reset_request_n;
    IOBUF data_pads[7:0](.IO(cpu_data), .I(data_out), .O(data_i), .OEN(!physical_oe));
    OBUF oe_pad(.I(buffer_oe_n_i || !reset_request_n), .O(cpu_buffer_oe_n));
    OBUF dir_pad(.I(buffer_dir_i), .O(cpu_buffer_dir));
    // Header pin 63 now carries DIR; ready is shown on the onboard LED1.
    OBUF debug_tx_pad(.I(debug_tx_i), .O(debug_tx));
    OBUF ready_pad(.I(!(ready_i && reset_request_n)), .O(video_ready_n));

    wire [9:0] blue, green, red, video_blue, video_green, video_red;
    // TMDS lane 0 carries blue and sync; lane 2 carries red.
    svo_tmds enc_blue(.clk(clk_pixel), .resetn(core_resetn), .de(de),
        .ctrl({vsync,hsync}), .din(rgb[7:0]), .dout(video_blue));
    svo_tmds enc_green(.clk(clk_pixel), .resetn(core_resetn), .de(de),
        .ctrl(2'b00), .din(rgb[15:8]), .dout(video_green));
    svo_tmds enc_red(.clk(clk_pixel), .resetn(core_resetn), .de(de),
        .ctrl(2'b00), .din(rgb[23:16]), .dout(video_red));
`ifdef CPU8_HDMI_AVI
    cpu8_hdmi_avi avi (.clk(clk_pixel), .resetn(core_resetn),
        .hsync(hsync), .vsync(vsync),
        .video_symbols({video_red,video_green,video_blue}),
        .symbols({red,green,blue}));
`else
    assign {red,green,blue} = {video_red,video_green,video_blue};
`endif
    wire [2:0] serial;
    OSER10 ser_blue(.Q(serial[0]), .D0(blue[0]), .D1(blue[1]), .D2(blue[2]),
        .D3(blue[3]), .D4(blue[4]), .D5(blue[5]), .D6(blue[6]), .D7(blue[7]),
        .D8(blue[8]), .D9(blue[9]), .PCLK(clk_pixel), .FCLK(clk_5x), .RESET(!core_resetn));
    OSER10 ser_green(.Q(serial[1]), .D0(green[0]), .D1(green[1]), .D2(green[2]),
        .D3(green[3]), .D4(green[4]), .D5(green[5]), .D6(green[6]), .D7(green[7]),
        .D8(green[8]), .D9(green[9]), .PCLK(clk_pixel), .FCLK(clk_5x), .RESET(!core_resetn));
    OSER10 ser_red(.Q(serial[2]), .D0(red[0]), .D1(red[1]), .D2(red[2]),
        .D3(red[3]), .D4(red[4]), .D5(red[5]), .D6(red[6]), .D7(red[7]),
        .D8(red[8]), .D9(red[9]), .PCLK(clk_pixel), .FCLK(clk_5x), .RESET(!core_resetn));
`ifdef YOSYS
    // nextpnr recognizes the emulated differential pair behind two OBUFs.
    wire [3:0] hdmi_p, hdmi_n;
    ELVDS_OBUF buffers[3:0](.I({clk_pixel,serial}), .O(hdmi_p), .OB(hdmi_n));
    OBUF hdmi_p_pads[3:0](.I(hdmi_p), .O({tmds_clk_p,tmds_d_p}));
    OBUF hdmi_n_pads[3:0](.I(hdmi_n), .O({tmds_clk_n,tmds_d_n}));
`else
    ELVDS_OBUF buffers[3:0](.I({clk_pixel,serial}),
        .O({tmds_clk_p,tmds_d_p}), .OB({tmds_clk_n,tmds_d_n}));
`endif
endmodule
