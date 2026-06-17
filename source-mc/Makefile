# Lab-6 multi-cycle CPU sid sorting simulation Makefile

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

TOP      := mccomp_tb
OUT      := mccpu_sim.out
VCD      := mccpu_sid_sort.vcd

SRCS := \
	MCCPU.v \
	dm.v \
	im.v \
	mccomp.v \
	mccomp_tb.v \
	RF.v

IVERILOG_FLAGS := -I . -s $(TOP)

.PHONY: build run wave clean help

build:
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(OUT) $(SRCS)

run: build
	$(VVP) $(OUT)

wave: run
	@if [ -f "$(VCD)" ]; then \
		$(GTKWAVE) "$(VCD)" & \
	else \
		echo "Cannot find $(VCD). Please run make run first."; \
		exit 1; \
	fi

clean:
	rm -f $(OUT) $(VCD) *.log

help:
	@echo "Lab-6 multi-cycle CPU sid sorting simulation"
	@echo "Targets: make build | make run | make wave | make clean"
