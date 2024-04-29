export CLOCK_PERIOD_PS = $(shell python3 ../synth/get_clock.py)

SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

VEN_DIR   := $(PWD)/../hvl/ventilator

PKG_SRCS  := $(PWD)/../pkg/types.sv
HDL_SRCS  := $(shell find $(PWD)/../hdl -name '*.sv')
HVL_SRCS  := $(shell find $(PWD)/../hvl -maxdepth 1  -name '*.sv' -o -name '*.v')
SRAM_SRCS := $(shell find $(PWD)/../sram/output -name '*.v')
SRCS 	  := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS) $(SRAM_SRCS)

VEN_SRC   := $(VEN_DIR)/ventilator_monitor.sv $(VEN_DIR)/verilator_tb.sv

START_CYCLE ?= -1
END_CYCLE   ?= -1

../hvl/rvfi_reference.svh: ../hvl/rvfi_reference.json
	python3 ../bin/rvfi_reference.py

sim/vent_exhaust/Vverilator_tb: $(SRCS) $(VEN_SRC) ../hvl/rvfi_reference.svh
	mkdir -p sim
	find ./sim -maxdepth 1 -type f -delete
	cd sim ;\
	verilator -Wall -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-BLKSEQ -Wno-WIDTHTRUNC -Wno-GENUNNAMED -Wno-WIDTHEXPAND -trace --trace-structs --cc -Dclock_period_ps=$(CLOCK_PERIOD_PS) $(SRCS) $(VEN_SRC) --top-module verilator_tb -Mdir vent_exhaust --exe $(VEN_DIR)/top_tb.cpp
	cd sim/vent_exhaust ;\
	$(MAKE) -f Vverilator_tb.mk

.PHONY: sim/memory_8.lst
sim/memory_8.lst: $(PROG)
	mkdir -p sim/vent_exhaust
	../bin/generate_memory_file.sh $(PROG)

.PHONY: ventilate
ventilate: sim/vent_exhaust/Vverilator_tb sim/memory_8.lst
	cd sim ;\
	./vent_exhaust/Vverilator_tb $(CLOCK_PERIOD_PS) memory_8.lst $(START_CYCLE) $(END_CYCLE)

.PHONY: ventilate_manual
ventilate_manual: sim/vent_exhaust/Vverilator_tb
	cd sim ;\
	./vent_exhaust/Vverilator_tb $(CLOCK_PERIOD_PS) $(MEMFILE) $(START_CYCLE) $(END_CYCLE)

.PHONY: clean
clean:
	rm -rf sim
