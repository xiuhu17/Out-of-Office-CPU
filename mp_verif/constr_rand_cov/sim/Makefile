SHELL = /bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS := $(PWD)/../pkg/types.sv
HVL_SRCS := $(shell find $(PWD)/../hvl -name '*.sv' -o -name '*.v')
HDRS     := $(shell find $(PWD)/../hvl -name '*.svh')
SRCS := $(PKG_SRCS) $(HVL_SRCS)

export VCS_ARCH_OVERRIDE=linux
VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/1ns -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED

sim/tb: $(SRCS) $(HDRS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../vcs_warn.config -l compile.log -top tb -o tb

.PHONY: run
run_tb: sim/tb $(PROG)
	cd sim && ./tb -l tb_sim.log

.PHONY: covrep
covrep: sim/tb.vdb
	cd sim && urg -dir tb.vdb

.PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && $(VERDI_HOME)/bin/verdi -ssf $(PWD)/sim/dump.fsdb

.PHONY: clean
clean:
	rm -rf sim verdi
