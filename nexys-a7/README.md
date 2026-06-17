# Lab-6 Nexys A7 board tops

This directory contains board-level wrappers for the sid sorting program.

Use one top at a time:

- `sc_nexys_a7_top`: single-cycle CPU board top
- `mc_nexys_a7_top`: multi-cycle CPU board top

Vivado file set:

- Single-cycle: add `nexys-a7/*.v`, `source-sc/SCCPU.v`, `source-sc/RF.v`, `source-sc/ctrl.v`, `source-sc/alu.v`, `source-sc/EXT.v`, `source-sc/NPC.v`, `source-sc/PC.v`, `source-sc/ctrl_encode_def.v`, and `source-sc/rv32_sid_sort_sim.dat`.
- Multi-cycle: add `nexys-a7/*.v`, `source-mc/MCCPU.v`, `source-mc/RF.v`, `source-mc/ctrl_encode_def.v`, and `source-mc/rv32_sid_sort_sim.dat`.
- Add `nexys-a7/nexys_a7.xdc` as the constraint file.

Board use:

- Press `BTNC` to reset and run again.
- `SW0 = 0`: display original sid, `54873530`.
- `SW0 = 1`: display sorted sid, `03345578`.
- `LED[15:0]` mirrors the low 16 bits of the displayed value.

The instruction ROM uses `$readmemh("rv32_sid_sort_sim.dat", ...)`, so keep the `.dat` file in the Vivado project sources or simulation/synthesis working directory.
