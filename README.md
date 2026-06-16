# ARM Processor System on FPGA (VHDL)

Implementation of core components of an **ARMv4-compatible processor system** in VHDL,
verified in simulation and synthesized onto a **Basys 3 (Xilinx Artix-7)** FPGA.

Built during the *Hardwarepraktikum* (hardware lab) at the Technical University of Berlin
(Chair of Embedded Systems Architecture). Team project (group Di-12-7).

> **Note on scope:** This builds on a course-provided framework. The chair supplied the
> module *interfaces* (VHDL entities, shared type/configuration packages, and testbenches);
> our work was implementing the *behaviour* — the architecture bodies — of the individual
> modules and getting the whole uncore to simulate and synthesize. See
> [Provided vs. implemented](#provided-vs-implemented).

---

## Overview

The system is assembled step by step across several lab sheets, from individual processor
building blocks up to a complete "uncore" (everything around the CPU core) that boots, loads
a program over a serial link, and runs on real hardware:

- **Processor building blocks** — data replication unit, instruction address register
- **Register subsystem** — mode-dependent register-address translation, distributed-RAM
  register file built from Xilinx `RAM32M` primitives
- **Memory subsystem** — 4K×32 RAM block and memory interface
- **Serial I/O** — RS232 interface with a PISO (parallel-in / serial-out) shift register
- **Uncore integration** — clock generation (MMCM/PLL IP), top-level wiring, behavioural
  simulation, synthesis and a hardware bring-up on the Basys 3 board

## My contribution

This was a team project; the modules I implemented / worked on:

| Module | What it does |
|---|---|
| `ArmDataReplication.vhd` | Replicates a byte / half-word across the 32-bit data bus |
| `ArmRegaddressTranslation.vhd` | Maps virtual register + CPU mode → physical register address |
| `DistRAM32M.vhd` | Behavioural model of the Xilinx `RAM32M` distributed-RAM primitive |
| `ArmRegfile.vhd` | Register file: 3 read / 2 + PC write ports, built from distributed RAM |
| `ArmRAMB_4kx32.vhd`, `ArmMemInterface.vhd` | 4K×32 RAM block and the memory interface |
| `PISOShiftReg.vhd`, `ArmRS232Interface.vhd` | Serial transmit path (PISO shift register + RS232) |
| `ArmBarrelShifter.vhd`, `ArmShifter.vhd` | Barrel shifter / shifter unit |
| Uncore (Blatt 5) | `ArmClkGen` clock IP, `ArmUncoreTop` behavioural simulation & synthesis |

Teammates contributed further modules and testbenches — the commit history shows who did what.

## Provided vs. implemented

- **Provided by the chair (course templates):** the module *entities* (port declarations),
  shared packages (`ArmTypes.vhd`, `ArmConfiguration.vhd`, `ArmFilePaths.vhd`), the test
  helpers (`TB_Tools.vhd`) and most of the `*_tb.vhd` testbenches.
- **Implemented by the team:** the architecture bodies of the modules listed above — the
  actual logic — plus getting the uncore to simulate and synthesize.

The provided template code remains the intellectual property of the TU Berlin chair and is
included here only to keep the project self-contained.

## Repository structure

```
src/
  packages/        shared types & configuration (ArmTypes, ArmConfiguration, ArmFilePaths)
  datapath/        barrel shifter, shifter, data replication
  register-file/   register file, register-address translation, RAM32M primitive
  core/            instruction address register & history buffer
  memory/          4K×32 RAM block, memory interface
  serial-io/       RS232 interface, PISO shift register
  uncore/          top level, system controller, chip-select, clocking glue
sim/               testbenches, test helpers and test vectors (sim/data/)
constraints/       Basys 3 pin/timing constraints (.xdc)
```

> Files under `src/packages/` and most testbenches in `sim/` are part of the
> course-provided framework; the architecture bodies of the design modules are the
> team's own work (see [Provided vs. implemented](#provided-vs-implemented)).

## Tech stack

- **VHDL** (IEEE 1076)
- **Xilinx Vivado** — synthesis, implementation, IP (Clocking Wizard)
- **Simulation** — Vivado XSim / GHDL
- **Target hardware** — Basys 3 board, Artix-7 FPGA

Each module is verified by its testbench in `sim/`. Generated simulation and Vivado
project artifacts are excluded via `.gitignore`.
