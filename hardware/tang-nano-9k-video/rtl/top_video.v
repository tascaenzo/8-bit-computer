`timescale 1ns/1ps
module top_video (
    input wire clk, resetn,
    input wire [15:0] cpu_addr,
    inout wire [7:0] cpu_data,
    input wire cpu_rd_n, cpu_wr_n, cpu_enable,
    output wire cpu_buffer_oe_n, cpu_buffer_dir, video_ready_n,
    output wire tmds_clk_p, tmds_clk_n,
    output wire [2:0] tmds_d_p, tmds_d_n
);
    // Explicit pads make both the CPU bus and HDMI pin assignment unambiguous.
    wire clk_i, resetn_i, rd_i, wr_i, enable_i;
    wire [15:0] addr_i;
    wire [7:0] data_i;
    IBUF clock_pad(.I(clk), .O(clk_i));
    IBUF reset_pad(.I(resetn), .O(resetn_i));
    IBUF read_pad(.I(cpu_rd_n), .O(rd_i));
    IBUF write_pad(.I(cpu_wr_n), .O(wr_i));
    IBUF enable_pad(.I(cpu_enable), .O(enable_i));
    IBUF address_pads[15:0](.I(cpu_addr), .O(addr_i));
    wire clk_pixel, clk_5x, pll_lock;
    Gowin_rPLL pll(.clkin(clk_i), .clkout(clk_5x), .lock(pll_lock));
    Gowin_CLKDIV divider(.hclkin(clk_5x), .clkout(clk_pixel), .resetn(pll_lock));
    reg [3:0] reset_pipe = 0;
    wire reset_request_n = resetn_i && pll_lock;
    always @(posedge clk_pixel or negedge reset_request_n) begin
        if (!reset_request_n) reset_pipe <= 0;
        else reset_pipe <= {reset_pipe[2:0],1'b1};
    end
    wire core_resetn = reset_pipe[3];
    wire [7:0] data_out;
    wire data_oe;
    wire buffer_dir_i, buffer_oe_n_i;
    wire ready_i;
    wire [23:0] rgb;
    wire de, hsync, vsync;
    cpu8_video_core core (
        .clk(clk_pixel), .resetn(core_resetn), .cpu_addr(addr_i),
        .cpu_data_in(data_i), .cpu_rd_n(rd_i), .cpu_wr_n(wr_i),
        .cpu_enable(enable_i), .cpu_data_out(data_out),
        .cpu_data_oe(data_oe), .ready(ready_i),
        .cpu_buffer_dir(buffer_dir_i), .cpu_buffer_oe_n(buffer_oe_n_i), .rgb(rgb),
        .de(de), .hsync(hsync), .vsync(vsync)
    );
    // resetn/LOCK also release the physical outputs without a pixel clock.
    wire physical_oe = data_oe && reset_request_n;
    IOBUF data_pads[7:0](.IO(cpu_data), .I(data_out), .O(data_i), .OEN(!physical_oe));
    OBUF oe_pad(.I(buffer_oe_n_i || !reset_request_n), .O(cpu_buffer_oe_n));
    OBUF dir_pad(.I(buffer_dir_i), .O(cpu_buffer_dir));
    // Header pin 63 now carries DIR; ready is shown on the onboard LED1.
    OBUF ready_pad(.I(!(ready_i && reset_request_n)), .O(video_ready_n));

    wire [9:0] blue, green, red;
    // TMDS lane 0 carries blue and sync; lane 2 carries red.
    svo_tmds enc_blue(.clk(clk_pixel), .resetn(core_resetn), .de(de),
        .ctrl({vsync,hsync}), .din(rgb[7:0]), .dout(blue));
    svo_tmds enc_green(.clk(clk_pixel), .resetn(core_resetn), .de(de),
        .ctrl(2'b00), .din(rgb[15:8]), .dout(green));
    svo_tmds enc_red(.clk(clk_pixel), .resetn(core_resetn), .de(de),
        .ctrl(2'b00), .din(rgb[23:16]), .dout(red));
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
