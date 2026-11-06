# ============================================================================
# Cadence Xcelium - xrun Makefile
# Project    : SOP/EOP packet FIFO UVM testbench
# Top module : tb_top
#
# From the project root, use: make -C sim run
# ============================================================================

# ----------------------------------------------------------------------------
# Tools
# ----------------------------------------------------------------------------
XRUN ?= xrun

# ----------------------------------------------------------------------------
# Directories
# ----------------------------------------------------------------------------
# Run this Makefile with "make -C sim <target>" from the project root, or
# invoke make directly while sim/ is the current directory. Relative paths
# also keep the commands safe when a parent directory contains spaces.
SIM_DIR   := .
PROJ_ROOT := ..
RTL_DIR   := $(PROJ_ROOT)/rtl
TB_DIR    := $(PROJ_ROOT)/tb
LOG_DIR   := $(PROJ_ROOT)/logs

# ----------------------------------------------------------------------------
# Source files - ORDER IS IMPORTANT
# ----------------------------------------------------------------------------
# packet_uvc_pkg.sv includes all class files under tb/uvc, tb/env,
# tb/sequences, and tb/tests. Those included files must not be compiled again
# as independent compilation units.
RTL_SRC := $(RTL_DIR)/packet_fifo.sv

TB_SRC := $(TB_DIR)/packet_if.sv \
          $(TB_DIR)/packet_uvc_pkg.sv \
          $(TB_DIR)/tb_top.sv

ALL_SRC := $(RTL_SRC) \
           $(TB_SRC)

# ----------------------------------------------------------------------------
# Top and UVM test selection
# ----------------------------------------------------------------------------
TOP           ?= tb_top
UVM_TEST      ?= packet_random_test
UVM_VERBOSITY ?= UVM_MEDIUM
SEED          ?= random

# ----------------------------------------------------------------------------
# UVM
# ----------------------------------------------------------------------------
# Override this path on systems with a different Xcelium installation:
#   make -C sim run UVM_HOME=/path/to/UVM/CDNS-1.2
UVM_HOME ?= /ecad/apps4/cadence/XCELIUMMAIN25.03.001/tools/methodology/UVM/CDNS-1.2

# ----------------------------------------------------------------------------
# Xcelium options
# ----------------------------------------------------------------------------
XRUN_OPTS := -64bit \
             -sv \
             -nocopyright \
             -access +rwc \
             -licqueue \
             -timescale 1ns/1ps \
             -uvm \
             -uvmhome $(UVM_HOME) \
             -svseed $(SEED) \
             -status

# Extra command-line options can be supplied without editing this file:
#   make -C sim run XRUN_EXTRA="-coverage all"
XRUN_EXTRA ?=

# ----------------------------------------------------------------------------
# Include directories
# ----------------------------------------------------------------------------
# The package uses includes such as "uvc/packet_item.sv", so TB_DIR must be
# present on the include search path. -uvm/-uvmhome supply uvm_macros.svh.
INC_OPTS := +incdir+$(TB_DIR)

# ----------------------------------------------------------------------------
# Waveform recording
# ----------------------------------------------------------------------------
PROBE_TCL := $(SIM_DIR)/probe.tcl
WAVE_DB   := $(SIM_DIR)/waves.shm

# ----------------------------------------------------------------------------
# Logs
# ----------------------------------------------------------------------------
RUN_LOG := $(LOG_DIR)/xrun.log
GUI_LOG := $(LOG_DIR)/xrun_gui.log

# ----------------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------------
.PHONY: all run gui clean help print-config

all: run

run: | $(LOG_DIR)
	@echo "========================================================"
	@echo " Running SOP/EOP packet FIFO test with Xcelium"
	@echo " Top       : $(TOP)"
	@echo " UVM test  : $(UVM_TEST)"
	@echo " Verbosity : $(UVM_VERBOSITY)"
	@echo " Seed      : $(SEED)"
	@echo " Log       : $(RUN_LOG)"
	@echo " Waves     : $(WAVE_DB)"
	@echo "========================================================"
	$(XRUN) $(XRUN_OPTS) $(XRUN_EXTRA) $(INC_OPTS) \
		$(ALL_SRC) \
		+UVM_TESTNAME=$(UVM_TEST) \
		+UVM_VERBOSITY=$(UVM_VERBOSITY) \
		-top $(TOP) \
		-input $(PROBE_TCL) \
		-log $(RUN_LOG)

gui: | $(LOG_DIR)
	@echo "========================================================"
	@echo " Running SOP/EOP packet FIFO test in Xcelium GUI"
	@echo " Top       : $(TOP)"
	@echo " UVM test  : $(UVM_TEST)"
	@echo " Verbosity : $(UVM_VERBOSITY)"
	@echo " Seed      : $(SEED)"
	@echo " Log       : $(GUI_LOG)"
	@echo " Waves     : $(WAVE_DB)"
	@echo "========================================================"
	$(XRUN) $(XRUN_OPTS) $(XRUN_EXTRA) $(INC_OPTS) \
		$(ALL_SRC) \
		+UVM_TESTNAME=$(UVM_TEST) \
		+UVM_VERBOSITY=$(UVM_VERBOSITY) \
		-top $(TOP) \
		-input $(PROBE_TCL) \
		-gui \
		-log $(GUI_LOG)

$(LOG_DIR):
	mkdir -p $@

print-config:
	@echo "SIM_DIR       = $(SIM_DIR)"
	@echo "PROJ_ROOT     = $(PROJ_ROOT)"
	@echo "RTL_DIR       = $(RTL_DIR)"
	@echo "TB_DIR        = $(TB_DIR)"
	@echo "LOG_DIR       = $(LOG_DIR)"
	@echo "TOP           = $(TOP)"
	@echo "UVM_TEST      = $(UVM_TEST)"
	@echo "UVM_VERBOSITY = $(UVM_VERBOSITY)"
	@echo "SEED          = $(SEED)"
	@echo "UVM_HOME      = $(UVM_HOME)"
	@echo "ALL_SRC       = $(ALL_SRC)"

clean:
	@echo "Cleaning Xcelium-generated files..."
	rm -rf $(SIM_DIR)/xcelium.d \
	       $(SIM_DIR)/INCA_libs \
	       $(SIM_DIR)/.simvision \
	       $(SIM_DIR)/waves.shm
	rm -f $(SIM_DIR)/xrun.history \
	      $(SIM_DIR)/xrun.key \
	      $(SIM_DIR)/*.diag \
	      $(SIM_DIR)/*.err \
	      $(RUN_LOG) \
	      $(GUI_LOG)

help:
	@echo ""
	@echo "SOP/EOP packet FIFO - Xcelium targets"
	@echo ""
	@echo "Run from the project root:"
	@echo "  make -C sim run"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Compile, elaborate, and run the default test"
	@echo "  run          - Compile, elaborate, and run in command-line mode"
	@echo "  gui          - Compile, elaborate, and open the Xcelium GUI"
	@echo "  print-config - Display resolved paths and simulation settings"
	@echo "  clean        - Remove Xcelium-generated files and logs"
	@echo "  help         - Display this help"
	@echo ""
	@echo "Common overrides:"
	@echo "  UVM_TEST=<name>          Select the UVM test"
	@echo "  UVM_VERBOSITY=<level>   Set UVM verbosity"
	@echo "  SEED=<number|random>     Select the SystemVerilog random seed"
	@echo "  UVM_HOME=<path>          Select the Cadence UVM installation"
	@echo "  XRUN=<path>              Select the xrun executable"
	@echo "  XRUN_EXTRA='<options>'   Add Xcelium command-line options"
	@echo ""
	@echo "Examples:"
	@echo "  make -C sim run SEED=12345"
	@echo "  make -C sim gui UVM_VERBOSITY=UVM_HIGH"
	@echo "  make -C sim run XRUN_EXTRA='-coverage all'"
	@echo ""
