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
#!/bin/bash
# ==============================================================================
# Manual Deployment Script — programs the QMTECH Artix-7 board over JTAG.
# Invoked on demand via: make deploy PRJ=<project>
# ==============================================================================
set -euo pipefail

PRJ_DIR=$1
TOP=$2

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

echo -e "${YELLOW}[DEPLOY] Target is QMTECH Artix-7 (Baremetal, JTAG).${RESET}"

# Cable is a Xilinx Platform Cable USB II (DLC10, 03fd:0008 once its FX2
# firmware is loaded). openFPGALoader has no driver for it; xc3sprog does,
# under cable name "xpc". Firmware load + udev rule:
# /etc/udev/rules.d/52-xilinx-pcusb.rules. Override cable with
# XC3SPROG_CABLE=<name>. Debug: `xc3sprog -c xpc` (no bitfile) should print
# the xc7a100t IDCODE; `lsusb | grep 03fd` should show 0008.
XC3SPROG_CABLE="${XC3SPROG_CABLE:-xpc}"

if ! command -v xc3sprog >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] xc3sprog not found.${RESET}"
    echo -e "${YELLOW}[HINT] apt install xc3sprog${RESET}"
    exit 1
fi

BIT_FILE="${PRJ_DIR}/build/${TOP}.bit"
BIN_FILE="${PRJ_DIR}/build/${TOP}.bin"

if [ -f "$BIT_FILE" ]; then
    IMAGE="$BIT_FILE"
elif [ -f "$BIN_FILE" ]; then
    IMAGE="$BIN_FILE"
else
    echo -e "${RED}[ERROR] No bitstream found for $TOP.${RESET}"
    echo -e "${YELLOW}[HINT] Expected $BIT_FILE or $BIN_FILE. Run 'make build PRJ=...' first.${RESET}"
    exit 1
fi

echo -e "${CYAN}[DEPLOY] Programming board with $IMAGE...${RESET}"
if ! xc3sprog -c "$XC3SPROG_CABLE" "$IMAGE"; then
    echo -e "${RED}[ERROR] xc3sprog failed to program the board.${RESET}"
    echo -e "${YELLOW}[HINT] Check the DLC10 is plugged in and powered. Run 'xc3sprog -c xpc' (no bitfile) to confirm the JTAG chain is detected. If 'lsusb | grep 03fd' shows 0013 instead of 0008, the FX2 firmware hasn't loaded -- check the udev rule and replug.${RESET}"
    exit 1
fi
echo -e "${GREEN}[SUCCESS] QMTECH Artix-7 programmed with $(basename "$IMAGE")!${RESET}"
