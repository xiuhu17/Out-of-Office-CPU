SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS  := $(PWD)/../pkg/types.sv
HDL_SRCS  := $(shell find $(PWD)/../hdl -name '*.sv')
HVL_SRCS  := $(shell find $(PWD)/../hvl -name '*.sv' -o -name '*.v')
SRAM_SRCS := $(shell find $(PWD)/../sram/output -name '*.v')
HDRS      := $(shell find $(PWD)/../hvl -name '*.svh')
DW_IP     := $(shell python3 get_dw_ip.py)
SRCS      := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS) $(SRAM_SRCS) $(DW_IP)

export VCS_ARCH_OVERRIDE=linux
VCS_FLAGS= -full64 -lca -sverilog -timescale=1ns/1ns -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED +incdir+$(DW)/sim_ver +define+DW_SUPPRESS_WARN

sim/top_tb: $(SRCS) $(HDRS)
	mkdir -p sim
	python3 check_sus.py
	python3 ../bin/rvfi_reference.py
	python3 set_dw_ip.py
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../vcs_warn.config -l compile.log -top top_tb -o top_tb
	bash check_compile_error.sh

.PHONY: run_top_tb
run_top_tb: sim/top_tb $(PROG)
	../bin/generate_memory_file.sh $(PROG)
	rm -f sim/dump.fsdb
	python3 ../synth/get_clock.py
	python3 get_bmem_x.py
	export ECE411_CLOCK_PERIOD_PS=$(shell python3 ../synth/get_clock.py) ;\
	export ECE411_BRAM_0_ON_X=$(shell python3 get_bmem_x.py) ;\
	export ECE411_MEMLST=$(PWD)/sim/memory ;\
	cd sim && ./top_tb -l simulation.log
	bash check_sim_error.sh

.PHONY: covrep
covrep: sim/top_tb.vdb
	cd sim && urg -dir top_tb.vdb

.PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && $(VERDI_HOME)/bin/verdi -ssf $(PWD)/sim/dump.fsdb

.PHONY: spike
spike: $(ELF)
	mkdir -p sim
	spike --isa=rv32imc -m0x60000000:0x20000000 --log-commits $(ELF) |& tail -n +6 > sim/spike.log

.PHONY: interactive_spike
interactive_spike: $(ELF)
	mkdir -p sim
	spike --isa=rv32imc -m0x60000000:0x20000000 --log-commits -d $(ELF)

.PHONY: clean
clean:
	rm -rf bin sim verdi
