SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

export HDL_SRCS = $(shell find $(PWD)/../hdl -name '*.sv')

.PHONY: lint
lint: clean
	mkdir -p reports
	sg_shell < lint.tcl
	mv spyglass-1/consolidated_reports/*_lint_lint_turbo_rtl/*.rpt reports/
	mv reports/moresimple_turbo.rpt reports/lint.rpt
	rm -rf spyglass-1 WORK *.log
	
.PHONY: clean
clean:
	rm -rf spyglass-1 WORK *.log reports
