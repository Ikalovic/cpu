# Lab-6 single-cycle CPU sid sorting simulation Makefile
# source-sc is the run directory. Run make in this directory.

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

TOP      := sccomp_tb
OUT      := sccpu_sim.out
VCD      := sccpu_sid_sort.vcd

# ctrl_encode_def.v is included by the source files through `include`.
SRCS := \
	alu.v \
	ctrl.v \
	dm.v \
	EXT.v \
	im.v \
	NPC.v \
	PC.v \
	sccomp.v \
	sccomp_tb.v \
	SCCPU.v \
	RF.v

IVERILOG_FLAGS := -I . -s $(TOP)

.PHONY: build run wave wave30 clean help

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

wave30:
	$(IVERILOG) -I . -s sc_final_wave_tb -o sc_final_wave.out \
		alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v sccomp.v SCCPU.v RF.v sc_final_wave_tb.v
	$(VVP) sc_final_wave.out +IMEM=../CODExp/testcode/task/Test_30_Instr.dat +CYCLES=120 +VCD=sc_final_test30.vcd
	$(GTKWAVE) sc_final_test30.vcd &

clean:
	rm -f $(OUT) $(VCD) sc_final_wave.out sc_final_wave.vcd sc_final_test30.vcd *.log

help:
	@echo "Lab-6 single-cycle CPU sid sorting simulation"
	@echo ""
	@echo "Targets:"
	@echo "  make build  Compile Verilog sources to $(OUT)"
	@echo "  make run    Build and run simulation, generating $(VCD)"
	@echo "  make wave   Build, run, and open $(VCD) with GTKWave"
	@echo "  make wave30 Build 30-instruction wave VCD and open it with GTKWave"
	@echo "  make clean  Remove generated simulation files"
	@echo "  make help   Show this help"
	@echo ""
	@echo "Required tools: iverilog, vvp, gtkwave"
