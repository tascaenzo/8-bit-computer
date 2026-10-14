VENDOR := vendor/TangNano-9K-example/hdmi/src
CORE := rtl/cpu8_video_bus.v rtl/cpu8_vram.v rtl/cpu8_text_video.v rtl/cpu8_font.v rtl/cpu8_video_core.v
SOURCES := rtl/top_video.v $(CORE) $(VENDOR)/gowin_rpll/gowin_rpll.v $(VENDOR)/gowin_clkdiv/gowin_clkdiv.v $(VENDOR)/hdmi/svo_tmds.v
DEVICE := GW1NR-LV9QN88PC6/I5

.PHONY: all test synth bitstream clean
all: test bitstream

build:
	mkdir -p build

test: | build
	iverilog -g2012 -Wall -s cpu8_video_decode_tb -o build/decode_tb rtl/cpu8_video_decode.v tests/cpu8_video_decode_tb.v
	vvp build/decode_tb
	iverilog -g2012 -Wall -s cpu8_video_core_tb -o build/core_tb $(CORE) tests/cpu8_video_core_tb.v
	vvp build/core_tb
	iverilog -g2012 -Wall -s cpu8_text_video_tb -o build/text_tb rtl/cpu8_text_video.v rtl/cpu8_font.v tests/cpu8_text_video_tb.v
	vvp build/text_tb
	iverilog -g2012 -Wall -I$(VENDOR)/hdmi -s cpu8_tmds_tb -o build/tmds_tb $(VENDOR)/hdmi/svo_tmds.v tests/cpu8_tmds_tb.v
	vvp build/tmds_tb

synth: build/cpu8_video.json
build/cpu8_video.json: $(SOURCES) $(VENDOR)/hdmi/svo_defines.vh Makefile | build
	yosys -ql build/synth.log -p 'read_verilog -I$(VENDOR)/hdmi $(SOURCES); synth_gowin -noiopads -top top_video -json $@'

build/cpu8_video_pnr.json: build/cpu8_video.json constraints/video.cst
	nextpnr-himbaechel --device $(DEVICE) -o family=GW1N-9C -o cst=constraints/video.cst -o sspi_as_gpio --json $< --write $@ --freq 25.2 --report build/timing.json --log build/pnr.log

bitstream: build/cpu8_video.fs
build/cpu8_video.fs: build/cpu8_video_pnr.json
	gowin_pack -d GW1N-9C --sspi_as_gpio -o $@ $<

clean:
	rm -f build/decode_tb build/core_tb build/text_tb build/tmds_tb build/cpu8_video.json build/cpu8_video_pnr.json build/cpu8_video.fs build/timing.json build/synth.log build/pnr.log
