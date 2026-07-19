#  Copyright 2026 M. I. E. ARDJOUNE
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# ==============================================================================
# qmtech-workspace - build and verification automation
#
# Orchestrates open-source RTL simulation (GHDL / Icarus Verilog), Xilinx
# Vivado synthesis and implementation, SDF-annotated gate-level simulation,
# and hardware deployment for the projects under projects/, targeting a
# QMTECH Artix-7 (xc7a100tfgg676-1) board.
#
# RTL sources are written to IEEE 1076-2008 (VHDL) and IEEE 1800-2012
# (SystemVerilog); project layout follows Xilinx UG949 source-management
# conventions.
#
# Usage: make <target> PRJ=<project_name>
# ==============================================================================
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

VIVADO_IMAGE ?= vivado-runner-light:latest
ASIC_IMAGE   ?= hpretl/iic-osic-tools:latest
VIVADO_PATH  ?= /opt/Xilinx
VIVADO_VER   ?= 2025.2

PRJ ?=

PRJ_DIR := projects/$(PRJ)
TOP     := $(shell cat $(PRJ_DIR)/TOP 2>/dev/null)

# Colors
RED    := \033[1;31m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
CYAN   := \033[1;36m
RESET  := \033[0m

# Source Detection (Enforces strict language isolation for OS simulators)
SRC_VHDL := $(wildcard $(PRJ_DIR)/src/*.vhd $(PRJ_DIR)/src/*.vhdl)
SRC_SV   := $(wildcard $(PRJ_DIR)/src/*.sv $(PRJ_DIR)/src/*.v)

# Filter noisy container startup logs
DOCKER_FILTER := grep -v -E "USER_ID|GROUP_ID|Final PATH|Final PYTHONPATH|Executing command|Unexpected option|STARTUP" || true

.PHONY: all clean tidy check-env sim sim-vhdl sim-sv build sim-gate deploy

all: check-env sim build sim-gate

check-env:
	@if [ -z "$(PRJ)" ]; then echo -e "$(RED)[ERROR] PRJ variable not set. Usage: make <target> PRJ=<project_name>$(RESET)"; exit 1; fi
	@if [ ! -d "$(PRJ_DIR)" ]; then echo -e "$(RED)[ERROR] Project directory $(PRJ_DIR) does not exist.$(RESET)"; exit 1; fi
	@if [ -z "$(TOP)" ]; then echo -e "$(RED)[ERROR] Missing TOP file in $(PRJ_DIR). Please specify the top module name.$(RESET)"; exit 1; fi

# Full purge: removes every regenerable artifact for PRJ, plus workspace-root
# tool droppings (journals, logs, clockInfo.txt). Requires PRJ to be set.
clean: check-env
	@echo -e "$(YELLOW)[CLEAN] Purging build artifacts for $(PRJ)...$(RESET)"
	@rm -rf $(PRJ_DIR)/build $(PRJ_DIR)/sim $(PRJ_DIR)/reports .Xil/ .crash/* *.jou *.log *.pb clockInfo.txt diagnostics/*
	@echo -e "$(GREEN)[CLEAN] Done.$(RESET)"

# Light cleanup: clears transient Vivado journals/logs and clockInfo.txt from
# the workspace root without touching any project's build/sim/reports output.
# Does not require PRJ. Use 'clean' for a full per-project purge.
tidy:
	@echo -e "$(YELLOW)[TIDY] Removing transient tool logs from the workspace root...$(RESET)"
	@rm -rf .Xil/ .crash/* *.jou *.log *.pb clockInfo.txt
	@echo -e "$(GREEN)[TIDY] Done. Build outputs and reports were left in place.$(RESET)"

sim: check-env
	@if [ -n "$(SRC_VHDL)" ] && [ -n "$(SRC_SV)" ]; then \
		echo -e "$(RED)[ERROR] Mixed VHDL and SystemVerilog detected in $(PRJ_DIR)/src.$(RESET)"; \
		echo -e "$(YELLOW)[HINT] Open-source simulation (GHDL/Icarus) requires a single language per project. Please isolate RTL to either VHDL or SystemVerilog for this workspace.$(RESET)"; exit 1; \
	elif [ -n "$(SRC_VHDL)" ]; then $(MAKE) --no-print-directory sim-vhdl; \
	elif [ -n "$(SRC_SV)" ]; then $(MAKE) --no-print-directory sim-sv; \
	else echo -e "$(RED)[ERROR] No valid HDL sources found in $(PRJ_DIR)/src.$(RESET)"; exit 1; fi

sim-vhdl:
	@echo -e "$(CYAN)[SIM:VHDL] Launching IEEE 1076-2008 simulation using GHDL...$(RESET)"
	@mkdir -p $(PRJ_DIR)/sim
	@if [ -f $(PRJ_DIR)/mem_content.txt ]; then cp $(PRJ_DIR)/mem_content.txt $(PRJ_DIR)/sim/; fi
	@sg docker -c "docker run --rm -v \$$(pwd):/home/runner/project -w /home/runner/project $(ASIC_IMAGE) --skip \
		bash -c 'cd $(PRJ_DIR)/sim && ghdl -a --std=08 ../src/*.vhd ../tb/*.vhd && ghdl -e --std=08 $(TOP)_tb && ghdl -r --std=08 $(TOP)_tb --vcd=waveform.vcd --assert-level=error'" | $(DOCKER_FILTER) || \
		{ echo -e "$(RED)[ERROR] VHDL Simulation Failed$(RESET)"; exit 1; }
	@echo -e "$(GREEN)[SUCCESS] VHDL Simulation Passed. Waveform: $(PRJ_DIR)/sim/waveform.vcd$(RESET)"

sim-sv:
	@echo -e "$(CYAN)[SIM:SV] Launching IEEE 1800-2012 simulation using Icarus Verilog...$(RESET)"
	@mkdir -p $(PRJ_DIR)/sim
	@if [ -f $(PRJ_DIR)/mem_content.txt ]; then cp $(PRJ_DIR)/mem_content.txt $(PRJ_DIR)/sim/; fi
	@sg docker -c "docker run --rm -v \$$(pwd):/home/runner/project -w /home/runner/project $(ASIC_IMAGE) --skip \
		bash -c 'cd $(PRJ_DIR)/sim && iverilog -g2012 -s $(TOP)_tb -o rtl_sim ../src/*.sv ../tb/*.sv && vvp rtl_sim'" | $(DOCKER_FILTER) || \
		{ echo -e "$(RED)[ERROR] SystemVerilog Simulation Failed$(RESET)"; exit 1; }
	@echo -e "$(GREEN)[SUCCESS] SystemVerilog Simulation Passed. Waveform generated in $(PRJ_DIR)/sim.$(RESET)"

build: check-env
	@echo -e "$(CYAN)[BUILD] Synthesizing and Routing $(PRJ) for QMTECH Artix-7...$(RESET)"
	@mkdir -p $(PRJ_DIR)/build $(PRJ_DIR)/reports $(PRJ_DIR)/sim .crash
	@if [ -f $(PRJ_DIR)/mem_content.txt ]; then cp $(PRJ_DIR)/mem_content.txt ./; fi
	@sg docker -c "docker run --rm -v $(VIVADO_PATH):$(VIVADO_PATH):ro -v \$$(pwd):/home/runner/project -w /home/runner/project $(VIVADO_IMAGE) \
		vivado -mode batch -notrace -journal .crash/vivado.jou -log .crash/vivado.log -source scripts/build.tcl -tclargs $(PRJ_DIR) $(TOP)" || \
		{ echo -e "$(RED)[ERROR] Vivado Build Failed. Check logs in .crash/$(RESET)"; rm -f mem_content.txt; exit 1; }
	@rm -f mem_content.txt
	@echo -e "$(GREEN)[SUCCESS] Build complete. Bitstream and netlists generated.$(RESET)"

sim-gate: check-env
	@echo -e "$(CYAN)[SIM:GATE] Running Post-Route SDF Annotated Gate-Level Simulation...$(RESET)"
	@sg docker -c "docker run --rm -v $(VIVADO_PATH):$(VIVADO_PATH):ro -v \$$(pwd):/home/runner/project -w /home/runner/project $(VIVADO_IMAGE) \
		vivado -mode batch -notrace -journal .crash/xsim.jou -log .crash/xsim.log -source scripts/sim_gate.tcl -tclargs $(PRJ_DIR) $(TOP) $(VIVADO_PATH)/$(VIVADO_VER)" || \
		{ echo -e "$(RED)[ERROR] Gate-Level Simulation Failed.$(RESET)"; exit 1; }
	@echo -e "$(GREEN)[SUCCESS] Timing Simulation Passed.$(RESET)"

# Programs the QMTECH board over JTAG.
deploy: check-env
	@bash scripts/deploy.sh $(PRJ_DIR) $(TOP)
