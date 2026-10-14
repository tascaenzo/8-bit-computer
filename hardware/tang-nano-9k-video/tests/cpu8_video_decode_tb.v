`timescale 1ns/1ps
module cpu8_video_decode_tb;
    reg [15:0] addr;
    reg rd_n, wr_n, bus_enable;
    wire ram_sel, video_sel, ram_oe_n, ram_we_n;
    wire video_read, video_write, video_d_oe;
    wire [13:0] vram_addr;
    wire [6:0] row, col;
    integer a, control;
    reg expect_ram, expect_video, reading, writing;

    cpu8_video_decode dut (
        .addr(addr), .rd_n(rd_n), .wr_n(wr_n), .bus_enable(bus_enable),
        .ram_sel(ram_sel), .video_sel(video_sel),
        .ram_oe_n(ram_oe_n), .ram_we_n(ram_we_n),
        .video_read(video_read), .video_write(video_write),
        .video_d_oe(video_d_oe), .vram_addr(vram_addr), .row(row), .col(col)
    );

    initial begin
        // Tutti gli indirizzi, bus disabilitato/abilitato e quattro strobe.
        for (control = 0; control < 8; control = control + 1) begin
            {bus_enable, rd_n, wr_n} = control[2:0];
            for (a = 0; a < 65536; a = a + 1) begin
                addr = a;
                #1;
                expect_ram = bus_enable && a < 16384;
                expect_video = bus_enable && a >= 16384 && a < 32768;
                reading = !rd_n && wr_n;
                writing = rd_n && !wr_n;
                if (ram_sel !== expect_ram || video_sel !== expect_video ||
                    ram_oe_n !== !(expect_ram && reading) ||
                    ram_we_n !== !(expect_ram && writing) ||
                    video_read !== (expect_video && reading) ||
                    video_write !== (expect_video && writing) ||
                    video_d_oe !== (expect_video && reading))
                    $fatal(1, "Decodifica errata: addr=%h control=%b", addr, control[2:0]);
                if (ram_sel && video_sel)
                    $fatal(1, "RAM e video selezionati insieme");
                if (video_d_oe && !wr_n)
                    $fatal(1, "FPGA guida il bus durante una scrittura");
                if (expect_video && (vram_addr !== a - 16384 ||
                    row !== (a - 16384) / 128 || col !== a % 128))
                    $fatal(1, "Coordinate errate: addr=%h", addr);
            end
        end
        $display("PASS: 524288 combinazioni; range, coordinate e isolamento bus");
        $finish;
    end
endmodule
