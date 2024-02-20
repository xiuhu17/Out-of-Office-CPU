SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS  := $(PWD)/../pkg/types.sv
HDL_SRCS  := $(shell find $(PWD)/../hdl -name '*.sv')
HVL_SRCS  := $(shell find $(PWD)/../hvl -name '*.sv' -o -name '*.v')
SRAM_SRCS := $(shell find $(PWD)/../sram/output -name '*.v')
HDRS      := $(shell find $(PWD)/../hvl -name '*.svh')
SRCS      := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS) $(SRAM_SRCS)

export VCS_ARCH_OVERRIDE=linux
VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/1ns -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED

sim/cache_dut_tb: $(SRCS) $(HDRS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../vcs_warn.config -l compile.log -top cache_dut_tb -o cache_dut_tb
	bash check_compile_error.sh

.PHONY: run_cache_dut_tb
run_cache_dut_tb: sim/cache_dut_tb
	rm -f sim/dump.fsdb
	cd sim && ./cache_dut_tb -l sim.log
	bash check_sim_error.sh

.PHONY: covrep
covrep: sim/cache_dut_tb.vdb
	cd sim && urg -dir cache_dut_tb.vdb

.PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && $(VERDI_HOME)/bin/verdi -ssf $(PWD)/sim/dump.fsdb

.PHONY: clean
clean:
	rm -rf bin sim verdi
