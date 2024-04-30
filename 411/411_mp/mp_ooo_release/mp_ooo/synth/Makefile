SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

FSDB2SAIF_START = $(shell head -n1 ../sim/sim/time.txt)
FSDB2SAIF_END   = $(shell tail -n1 ../sim/sim/time.txt)

export PKG_SRCS = $(PWD)/../pkg/types.sv
export HDL_SRCS = $(shell find $(PWD)/../hdl -name '*.sv')
export SRAM_LIB = $(shell find $(PWD)/../sram/output/ -name "*.db")

export STD_CELL_LIB=$(FREEPDK45)/stdcells.db
export STD_CELL_ALIB=$(FREEPDK45)/alib

.PHONY: synth
synth: clean
	$(MAKE) outputs/synth.ddc

outputs/synth.ddc:
	mkdir -p reports outputs
	python3 get_clock.py
	python3 get_min_power.py
	python3 get_compile_cmd.py
	export ECE411_CLOCK_PERIOD_PS=$(shell python3 get_clock.py) ;\
	export ECE411_MIN_POWER=$(shell python3 get_min_power.py) ;\
	export ECE411_COMPILE_CMD="$(shell python3 get_compile_cmd.py)" ;\
	dc_shell -f synthesis.tcl |& tee reports/synthesis.log
	rm -f  *.log
	rm -f  default.svf
	rm -rf work
	bash check_synth_error.sh

../sim/sim/dump.fsdb.saif: ../sim/sim/dump.fsdb
	cd ../sim/sim && fsdb2saif dump.fsdb -bt $(FSDB2SAIF_START)ps -et $(FSDB2SAIF_END)ps -s top_tb/dut

.PHONY: power
power: outputs/synth.ddc ../sim/sim/dump.fsdb.saif
	dc_shell -f power.tcl |& tee reports/power.log

.PHONY: dv
dv:
	design_vision -f dc-gui.tcl

.PHONY: clean
clean:
	rm -f  *.log
	rm -f  default.svf
	rm -rf work
	rm -rf reports
	rm -rf outputs
