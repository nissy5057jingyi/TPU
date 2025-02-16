# Makefile for RTL simulation using VCS

export CLOCK_PERIOD = 10.0

VCS = SW_VCS=2020.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 -kdb -lca -nc \
      -debug_access+all+reverse +warn=noTFIPC +warn=noDEBUG_DEP +warn=noENUMASSIGN \
      +define+CLOCK_PERIOD=$(CLOCK_PERIOD)ps

# For norm testbench
NORM_MODULE      = norm
NORM_TESTBENCH   = $(NORM_MODULE)_tb.v
NORM_SOURCES     = $(NORM_MODULE).v
NORM_SYNTH_FILES = $(NORM_MODULE).vg

# For pool testbench
POOL_MODULE      = pool
POOL_TESTBENCH   = $(POOL_MODULE)_tb.v
POOL_SOURCES     = $(POOL_MODULE).v
POOL_SYNTH_FILES = $(POOL_MODULE).vg

# Default target
.DEFAULT_GOAL = sim

# Compilation targets
norm_simv: $(NORM_TESTBENCH) $(NORM_SOURCES)
	@echo "Compiling norm simulation executable $@"
	@echo "NOTE: If this is slow to startup: run 'module load vcs verdi synopsys-synth'"
	$(VCS) $^ -o $@
	@echo "Finished compiling $@"

pool_simv: $(POOL_TESTBENCH) $(POOL_SOURCES)
	@echo "Compiling pool simulation executable $@"
	@echo "NOTE: If this is slow to startup: run 'module load vcs verdi synopsys-synth'"
	$(VCS) $^ -o $@
	@echo "Finished compiling $@"

# Simulation targets
norm_sim: norm_simv
	@echo "Running norm simulation"
	./norm_simv | tee norm_sim.out
	@echo "Output saved to norm_sim.out"

pool_sim: pool_simv
	@echo "Running pool simulation"
	./pool_simv | tee pool_sim.out
	@echo "Output saved to pool_sim.out"

# Cleanup targets
clean:
	rm -rf *simv *.daidir csrc *.key
	rm -rf *.vcd *.vpd *.out *.dump
	rm -rf verdi* novas*
	rm -rf *.vg *.syn *.db

.PHONY: norm_sim pool_sim clean