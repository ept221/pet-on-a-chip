lint: 
	verilator --lint-only -Wall soc/src/counter_timer/*.v soc/src/cpu/*.v soc/src/d_ram_and_io/*.v soc/src/gpio/*.v soc/src/gpu/*.v soc/src/memory/*.v soc/src/soc/top.v soc/src/uart/*.v soc/src/motor_controller/*.v soc/src/servo/*.v soc/src/sonar/*.v

sim:
	mkdir -p build/sim
	iverilog -o build/sim/sim.vvp soc/src/counter_timer/*.v soc/src/cpu/*.v soc/src/d_ram_and_io/*.v soc/src/gpio/*.v soc/src/memory/*.v soc/src/uart/*.v soc/src/sim/*.v
	vvp build/sim/sim.vvp
	mv test_tb.vcd build/sim/test_tb.vcd
	open -a Scansion build/sim/test_tb.vcd

synth: soc/src/soc/top.v
	mkdir -p build/synth
	yosys -p "synth_ice40 -json build/synth/hardware.json -top top"  soc/src/soc/top.v soc/src/counter_timer/*.v soc/src/cpu/*.v soc/src/d_ram_and_io/*.v soc/src/gpio/*.v soc/src/gpu/*.v soc/src/memory/*.v soc/src/uart/*.v soc/src/motor_controller/*.v soc/src/servo/*.v soc/src/sonar/*.v soc/src/pic/*.v
pnr: build/synth/hardware.json
	mkdir -p build/pnr
	nextpnr-ice40 --hx8k --package bg121 --json build/synth/hardware.json --pcf soc/src/soc/pins.pcf --asc build/pnr/hardware.asc  --pcf-allow-unconstrained --freq 16 -r

refresh:
	find build/pnr -type f -not -name "hardware.asc" -delete
	rm -rf build/binary build/images

clean:
	rm -rf build