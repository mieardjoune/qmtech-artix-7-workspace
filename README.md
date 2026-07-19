# qmtech-artix-7-workspace

A containerized build and verification workspace for FPGA projects on the
QMTECH Artix-7 board (`xc7a100tfgg676-1`).

Each project runs through the same pipeline: open-source RTL simulation
(GHDL / Icarus Verilog), Xilinx Vivado synthesis and implementation, and
SDF-annotated gate-level simulation — all orchestrated through a single
`Makefile`.

## Structure

```bash
qmtech-artix-7-workspace/
 Hardware/            # Board files
 projects/
     ram_test/        # VHDL project example
     sv_test/         # SystemVerilog project example
 scripts/
    build.tcl         # Vivado synthesis + implementation + bitstream
    sim_gate.tcl      # Vivado SDF-annotated gate-level simulation
    deploy.sh         # Board programming over JTAG
 Makefile
 LICENSE
```

Each project under `projects/` is self-contained: `src/`, `tb/`,
`constraints/`, `params.txt`, and `TOP` are all it needs to be simulated,
built, and deployed.

## Requirements

- GNU Make, Bash
- Docker
- Xilinx Vivado 2025.2
- GHDL / Icarus Verilog (bundled in the simulation container)
- `xc3sprog` + Xilinx Platform Cable USB II

## Usage

```bash
make sim PRJ=ram_test        # RTL simulation
make build PRJ=ram_test      # Synthesis + implementation + bitstream
make sim-gate PRJ=ram_test   # Gate-level timing simulation
make deploy PRJ=ram_test     # Program the board over JTAG
make all PRJ=ram_test        # Run the full flow
make clean PRJ=ram_test      # Remove build artifacts for a project
make tidy                    # Remove stray tool logs at the workspace root
```

## License

[Apache 2.0](LICENSE)
