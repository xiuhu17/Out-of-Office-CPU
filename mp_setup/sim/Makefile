SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

HDL_SRCS := $(shell find $(PWD)/../hdl -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/../hvl -name '*.sv' -o -name '*.v')
SRCS := $(HDL_SRCS) $(HVL_SRCS)

export VCS_ARCH_OVERRIDE=linux
VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/1ns -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED

.PHONY: clean
.PHONY: run

sim/alu_tb: $(SRCS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../vcs_warn.config -l compile.log -top alu_tb -o alu_tb

.PHONY: run_alu_tb
run_alu_tb: sim/alu_tb $(PROG)
	cd sim && ./alu_tb -l simulation.log

.PHONY: verdi 
verdi:
	mkdir -p verdi
	cd verdi && $(VERDI_HOME)/bin/verdi -ssf $(PWD)/sim/dump.fsdb

.PHONY: clean
clean:
	rm -rf sim verdi
