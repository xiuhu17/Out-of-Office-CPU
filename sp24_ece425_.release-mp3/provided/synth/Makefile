SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

export HDL_SRCS = $(shell find $(PWD)/../hdl -name '*.sv')

export STD_CELL_LIB=../stdcells.db

.PHONY: synth
synth: clean
	mkdir -p reports outputs
	dc_shell -f synthesis.tcl |& tee reports/synthesis.log
	rm -f  *.log
	rm -f  default.svf
	rm -rf work

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
