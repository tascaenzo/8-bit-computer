VENDOR := vendor/hdmi
CORE := rtl/cpu8_debug_uart.v rtl/cpu8_boot_screen.v rtl/cpu8_ps2_keyboard.v rtl/cpu8_video_bus.v rtl/cpu8_vram.v rtl/cpu8_text_video.v rtl/cpu8_font.v rtl/cpu8_video_core.v
SOURCES := rtl/top_video.v rtl/cpu8_reset.v $(CORE) $(VENDOR)/gowin_rpll.v $(VENDOR)/gowin_clkdiv.v $(VENDOR)/svo_tmds.v
DEVICE := GW1NR-LV9QN88PC6/I5

.PHONY: preview all test synth bitstream bitstream-720p bitstream-720p50 bitstream-720p-hdmi clean
all: test bitstream

build:
	mkdir -p build

test: | build
	iverilog -g2012 -Wall -s cpu8_reset_tb -o build/reset_tb rtl/cpu8_reset.v tests/cpu8_reset_tb.v
	vvp build/reset_tb
	iverilog -g2012 -Wall -s cpu8_debug_uart_tb -o build/debug_tb rtl/cpu8_debug_uart.v tests/cpu8_debug_uart_tb.v
	vvp build/debug_tb
	iverilog -g2012 -Wall -s cpu8_boot_screen_tb -o build/boot_tb rtl/cpu8_boot_screen.v tests/cpu8_boot_screen_tb.v
	vvp build/boot_tb
	iverilog -g2012 -Wall -s cpu8_video_decode_tb -o build/decode_tb rtl/cpu8_video_decode.v tests/cpu8_video_decode_tb.v
	vvp build/decode_tb
	iverilog -g2012 -Wall -s cpu8_video_core_tb -o build/core_tb $(CORE) tests/cpu8_video_core_tb.v
	vvp build/core_tb
	iverilog -g2012 -Wall -s cpu8_text_video_tb -o build/text_tb rtl/cpu8_text_video.v rtl/cpu8_font.v tests/cpu8_text_video_tb.v
	vvp build/text_tb
	iverilog -g2012 -Wall -s cpu8_text_video_tb -P cpu8_text_video_tb.VIDEO_720P=1 -o build/text_720p_tb rtl/cpu8_text_video.v rtl/cpu8_font.v tests/cpu8_text_video_tb.v
	vvp build/text_720p_tb
	iverilog -g2012 -Wall -I$(VENDOR) -s cpu8_tmds_tb -o build/tmds_tb $(VENDOR)/svo_tmds.v tests/cpu8_tmds_tb.v
	vvp build/tmds_tb
	iverilog -g2012 -Wall -s cpu8_hdmi_avi_tb -o build/avi_tb rtl/cpu8_hdmi_avi.v tests/cpu8_hdmi_avi_tb.v
	vvp build/avi_tb

preview: | build
	iverilog -g2012 -Wall -s cpu8_video_preview_tb -o build/preview_tb $(CORE) tests/cpu8_video_preview_tb.v
	vvp build/preview_tb

synth: build/cpu8_video.json
build/cpu8_video.json: $(SOURCES) $(VENDOR)/svo_defines.vh Makefile | build
	yosys -ql build/synth.log -p 'read_verilog -I$(VENDOR) $(SOURCES); synth_gowin -noiopads -top top_video -json $@'

build/cpu8_video_pnr.json: build/cpu8_video.json constraints/video.cst
	nextpnr-himbaechel --device $(DEVICE) -o family=GW1N-9C -o cst=constraints/video.cst -o sspi_as_gpio --json $< --write $@ --freq 25.2 --report build/timing.json --log build/pnr.log

bitstream: build/cpu8_video.fs
build/cpu8_video.fs: build/cpu8_video_pnr.json
	gowin_pack -d GW1N-9C --sspi_as_gpio -o $@ $<

bitstream-720p: build/cpu8_video_720p.fs

build/cpu8_video_720p.json: $(SOURCES) $(VENDOR)/svo_defines.vh Makefile | build
	yosys -ql build/synth-720p.log -p 'read_verilog -DCPU8_720P -I$(VENDOR) $(SOURCES); synth_gowin -noiopads -top top_video -json $@'

build/cpu8_video_720p_pnr.json: build/cpu8_video_720p.json constraints/video.cst
	nextpnr-himbaechel --device $(DEVICE) -o family=GW1N-9C -o cst=constraints/video.cst -o sspi_as_gpio --json $< --write $@ --freq 74.25 --report build/timing-720p.json --log build/pnr-720p.log

build/cpu8_video_720p.fs: build/cpu8_video_720p_pnr.json
	gowin_pack -d GW1N-9C --sspi_as_gpio -o $@ $<

bitstream-720p50: build/cpu8_video_720p50.fs

build/cpu8_video_720p50.json: $(SOURCES) $(VENDOR)/svo_defines.vh Makefile | build
	yosys -ql build/synth-720p50.log -p 'read_verilog -DCPU8_720P -DCPU8_50HZ -I$(VENDOR) $(SOURCES); synth_gowin -noiopads -top top_video -json $@'

build/cpu8_video_720p50_pnr.json: build/cpu8_video_720p50.json constraints/video.cst
	nextpnr-himbaechel --device $(DEVICE) -o family=GW1N-9C -o cst=constraints/video.cst -o sspi_as_gpio --json $< --write $@ --freq 74.25 --seed 2 --report build/timing-720p50.json --log build/pnr-720p50.log

build/cpu8_video_720p50.fs: build/cpu8_video_720p50_pnr.json
	gowin_pack -d GW1N-9C --sspi_as_gpio -o $@ $<

bitstream-720p-hdmi: build/cpu8_video_720p_hdmi.fs

build/cpu8_video_720p_hdmi.json: $(SOURCES) rtl/cpu8_hdmi_avi.v $(VENDOR)/svo_defines.vh Makefile | build
	yosys -ql build/synth-720p-hdmi.log -p 'read_verilog -DCPU8_720P -DCPU8_HDMI_AVI -I$(VENDOR) $(SOURCES) rtl/cpu8_hdmi_avi.v; synth_gowin -noiopads -top top_video -json $@'

build/cpu8_video_720p_hdmi_pnr.json: build/cpu8_video_720p_hdmi.json constraints/video.cst
	nextpnr-himbaechel --device $(DEVICE) -o family=GW1N-9C -o cst=constraints/video.cst -o sspi_as_gpio --json $< --write $@ --freq 74.25 --report build/timing-720p-hdmi.json --log build/pnr-720p-hdmi.log

build/cpu8_video_720p_hdmi.fs: build/cpu8_video_720p_hdmi_pnr.json
	gowin_pack -d GW1N-9C --sspi_as_gpio -o $@ $<

clean:
	rm -f build/cpu8_video_720p50.json build/cpu8_video_720p50_pnr.json build/cpu8_video_720p50.fs build/timing-720p50.json build/synth-720p50.log build/pnr-720p50.log
	rm -f build/avi_tb build/cpu8_video_720p_hdmi.json build/cpu8_video_720p_hdmi_pnr.json build/cpu8_video_720p_hdmi.fs build/timing-720p-hdmi.json build/synth-720p-hdmi.log build/pnr-720p-hdmi.log
	rm -f build/cpu8_video_720p.json build/cpu8_video_720p_pnr.json build/cpu8_video_720p.fs build/timing-720p.json build/synth-720p.log build/pnr-720p.log
	rm -f build/decode_tb build/core_tb build/text_tb build/text_720p_tb build/tmds_tb build/cpu8_video.json build/cpu8_video_pnr.json build/cpu8_video.fs build/timing.json build/synth.log build/pnr.log
