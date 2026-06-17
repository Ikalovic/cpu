IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

SRC = PipelineCPU.v pipe_decode.v pipe_alu.v pipe_branch.v hazard_unit.v dm.v im.v pipecomp.v pipecomp_tb.v RF.v
OUT = pipe_cpu_sim.out

.PHONY: all build run wave30 clean

all: run

build:
	$(IVERILOG) -I . -s pipecomp_tb -o $(OUT) $(SRC)

run: build
	$(VVP) $(OUT)

wave30:
	$(IVERILOG) -I . -s pl_final_wave_tb -o pl_final_wave.out \
		PipelineCPU.v pipe_decode.v pipe_alu.v pipe_branch.v hazard_unit.v \
		dm.v im.v plcomp.v RF.v pl_final_wave_tb.v
	$(VVP) pl_final_wave.out +IMEM=../CODExp/testcode/task/Test_30_Instr.dat +CYCLES=200 +VCD=pl_final_test30.vcd
	$(GTKWAVE) pl_final_test30.vcd &

clean:
	rm -f $(OUT) pipe_cpu_sid_sort.vcd pl_final_wave.out pl_final_wave.vcd pl_final_test30.vcd
