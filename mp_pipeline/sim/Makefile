SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS := $(PWD)/../pkg/types.sv
HDL_SRCS := $(shell find $(PWD)/../hdl -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/../hvl -name '*.sv' -o -name '*.v')
HDRS     := $(shell find $(PWD)/../hvl -name '*.svh')
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)

export VCS_ARCH_OVERRIDE=linux
VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/1ns -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED

sim/top_tb: $(SRCS) $(HDRS)
	mkdir -p sim
	python3 ../bin/rvfi_reference.py
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../vcs_warn.config -l top_tb_compile.log -top top_tb -o top_tb
	bash check_compile_error.sh

.PHONY: run_top_tb
run_top_tb: sim/top_tb $(PROG)
	../bin/generate_memory_file.sh $(PROG)
	rm -f sim/dump.fsdb
	cd sim && ./top_tb -l top_tb_sim.log
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
	spike --isa=rv32i -m0x60000000:0x20000000 --log-commits $(ELF) |& tail -n +6 > sim/spike.log

.PHONY: interactive_spike
interactive_spike: $(ELF)
	spike --isa=rv32i -m0x60000000:0x20000000 --log-commits -d $(ELF)

.PHONY: clean
clean:
	rm -rf bin sim verdi
