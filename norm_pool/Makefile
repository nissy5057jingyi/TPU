##########################
# ---- Introduction ---- #
##########################

# Welcome to the CSEE 4824 standard makefile!

# NOTE: you should only need to modify the "Executable Compilation" section
# namely the TESTBENCH, SOURCES, and SYNTH_FILES variables
# look for the 'LAB3 TODO' markers below

# reference table of all make targets:

# make cov_simv     <- compile the testbench and sources for coverage
# make cov_simv.vdb <- running the coverage executable will make this report dir
# make cov_report   <- output the coverage report in a new directory
# make cov_verdi    <- run verdi in coverage mode to get a visual view of coverage

# make           <- runs the default target, set explicitly below as 'make sim'
.DEFAULT_GOAL = sim
# ^ this overrides using the first listed target as the default

# make sim       <- execute the simulation testbench (simv)
# make simv      <- compiles simv from the testbench and SOURCES

# make syn       <- execute the synthesized module testbench (syn_simv)
# make syn_simv  <- compiles syn_simv from the testbench and *.vg SYNTH_FILES
# make *.vg      <- synthesize the top level module in SOURCES for use in syn_simv
# make slack     <- a phony command to print the slack of any synthesized modules

# make verdi     <- runs the Verdi GUI debugger for simulation
# make syn_verdi <- runs the Verdi GUI debugger for synthesis

# make clean     <- remove files created during compilations (but not synthesis)
# make nuke      <- remove all files created during compilation and synthesis
# make clean_run_files <- remove per-run output files
# make clean_exe       <- remove compiled executable files
# make clean_synth     <- remove generated synthesis files

######################################################
# ---- Compilation Commands and Other Variables ---- #
######################################################

# LAB3 TODO Make sure the command matches the verification setup

# this is a global clock period variable used in the tcl script and referenced in testbenches
export CLOCK_PERIOD = 10.0

# the Verilog Compiler command and arguments
VCS = SW_VCS=2020.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 -kdb -lca -nc \
      -debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)ps
# a SYNTH define is added when compiling for synthesis that can be used in testbenches

# remove certain warnings that generate MB of text but can be safely ignored
VCS_BAD_WARNINGS = +warn=noTFIPC +warn=noDEBUG_DEP +warn=noENUMASSIGN

# Verdi executable setup
export VERDI_HOME = /tools/synopsys/verdi/verdi/U-2023.03-SP2-1
VERDI_EXE = $(VERDI_HOME)/bin/verdi

# a reference library of standard structural cells that we link against when synthesizing
LIB = $(wildcard /homes/user/fac/tk3070/tmp/synthesis/OpenROAD-flow-scripts/flow/platforms/asap7/work_around_yosys/asap7sc7p5t*.v)

# the CSEE 4824 synthesis script
TCL_SCRIPT = 470synth.tcl

# Set the shell's pipefail option: causes return values through pipes to match the last non-zero value
# (useful for, i.e. piping to `tee`)
SHELL := $(SHELL) -o pipefail

##############################
# ---- Coverage Targets ---- #
##############################

# this section adds targets to compile and run with coverage testing

# VCS arg to both build and run for coverage
COV_ARG = -cm line+cond+fsm+tgl+branch

cov_simv: $(TESTBENCH) $(SOURCES) $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $(COV_ARG) $(TESTBENCH) $(SOURCES) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

cov_simv.vdb: cov_simv
	@$(call PRINT_COLOR, 5, running $<)
	./$< $(COV_ARG) | tee cov_prog.out
	@$(call PRINT_COLOR, 2, created coverage dir $<.vdb and saved output to cov_prog.out)

cov_report: cov_simv.vdb
	@$(call PRINT_COLOR, 5, outputting coverage report in $@)
	urg -format text -dir $< -report $@
	@$(call PRINT_COLOR, 2, coverage report is in $@)

cov_verdi: cov_simv novas.rc verdi_dir
	./$< -gui=verdi -cov -covdir $<.vdb

.PHONY: cov cov_report cov_verdi

####################################
# ---- Executable Compilation ---- #
####################################

# You should only need to modify this section, and only the following variables:
MODULE      = norm
TESTBENCH   = $(MODULE)_tb_q88.v
SOURCES     = $(MODULE).v
SYNTH_FILES = $(MODULE).vg

# the normal simulation executable will run your testbench on the original modules
simv: $(TESTBENCH) $(SOURCES)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $^ -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)
# NOTE: we reference variables with $(VARIABLE), and can make use of the automatic variables: ^, @, <, etc
# see: https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html for explanations

# a make pattern rule to generate the .vg synthesis files
# pattern rules use the % as a wildcard to match multiple possible targets
%.vg: $(SOURCES) $(TCL_SCRIPT)
	@$(call PRINT_COLOR, 5, synthesizing the $* module)
	@$(call PRINT_COLOR, 3, this might take a while...)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	# pipefail causes the command to exit on failure even though it's piping to tee
	set -o pipefail; MODULE=$* SOURCES="$(SOURCES)" dc_shell-t -f $(TCL_SCRIPT) | tee $*_synth.out
	@$(call PRINT_COLOR, 6, finished synthesizing $@)
# this also generates many other files, see the tcl script's introduction for info on each of them

# the synthesis executable runs your testbench on the synthesized versions of your modules
syn_simv: $(TESTBENCH) $(SYNTH_FILES)
	@$(call PRINT_COLOR, 5, compiling the synthesis executable $@)
	$(VCS) +define+SYNTH $^ $(LIB) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)
# we need to link the synthesized modules against LIB, so this differs slightly from simv above
# but we still compile with the same non-synthesizable testbench

# a phony target to view the slack in the *.rep synthesis report file
slack:
	grep --color=auto "slack" *.rep
.PHONY: slack

#####################################
# ---- Running the Executables ---- #
#####################################

# these targets run the compiled executable and save the output to a .out file
# their respective files are program.out or program.syn.out

sim: simv
	@$(call PRINT_COLOR, 5, running $<)
	./simv | tee program.out
	@$(call PRINT_COLOR, 2, output saved to program.out)

syn: syn_simv
	@$(call PRINT_COLOR, 5, running $<)
	./syn_simv | tee program.syn.out
	@$(call PRINT_COLOR, 2, output saved to program.syn.out)

# NOTE: phony targets don't create files matching their name, and make will always run their commands
# make doesn't know how files get created, so we tell it about these explicitly:
.PHONY: sim syn

###################
# ---- Verdi ---- #
###################

# verdi is the synopsys debug system, and an essential tool in CSEE 4824

# these targets run the executables using verdi
verdi: simv novas.rc verdi_dir
	./simv -gui=$(VERDI_EXE)

syn_verdi: syn_simv novas.rc verdi_dir
	./syn_simv -gui=$(VERDI_EXE)

.PHONY: verdi syn_verdi

# this creates a directory verdi will use if it doesn't exist yet
verdi_dir:
	mkdir -p /workdir/$${USER}_csee4824
.PHONY: verdi_dir

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

#####################
# ---- Cleanup ---- #
#####################

# You should only clean your directory if you think something has built incorrectly
# or you want to prepare a clean directory for e.g. git (first check your .gitignore).
# Please avoid cleaning before every build. The point of a makefile is to
# automatically determine which targets have dependencies that are modified,
# and to re-build only those as needed; avoiding re-building everything everytime.

# 'make clean' removes build/output files, 'make nuke' removes all generated files
# clean_* commands clean certain groups of files

clean: clean_exe clean_run_files
	@$(call PRINT_COLOR, 6, note: clean is split into multiple commands that you can call separately: clean_exe and clean_run_files)

# use cautiously, this can cause hours of recompiling in later projects
nuke: clean clean_synth
	@$(call PRINT_COLOR, 6, note: nuke is split into multiple commands that you can call separately: clean_synth)

clean_exe:
	@$(call PRINT_COLOR, 3, removing compiled executable files)
	rm -rf *simv *.daidir csrc *.key vcdplus.vpd vc_hdrs.h
	rm -rf verdi* novas* *fsdb*

clean_run_files:
	@$(call PRINT_COLOR, 3, removing per-run outputs)
	rm -rf *.out *.dump

clean_synth:
	@$(call PRINT_COLOR, 1, removing synthesis files)
	rm -rf *.vg *_svsim.sv *.res *.rep *.ddc *.chk *.syn *_synth.out *.mr *.pvl command.log

.PHONY: clean nuke clean_%

######################
# ---- Printing ---- #
######################

# this is a GNU Make function with two arguments: PRINT_COLOR(color: number, msg: string)
# it does all the color printing throughout the makefile
PRINT_COLOR = if [ -t 0 ]; then tput setaf $(1) ; fi; echo $(2); if [ -t 0 ]; then tput sgr0; fi
# colors: 0:black, 1:red, 2:green, 3:yellow, 4:blue, 5:magenta, 6:cyan, 7:white
# other numbers are valid, but aren't specified in the tput man page

# Make functions are called like this:
# $(call PRINT_COLOR,3,Hello World!)
# NOTE: adding '@' to the start of a line avoids printing the command itself, only the output
