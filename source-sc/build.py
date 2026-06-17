#!/usr/bin/env python3
"""Lab-6 single-cycle CPU sid sorting simulation helper."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
OSS_CAD_ROOT = Path(r"D:\oss-cad-suite\oss-cad-suite")
OSS_CAD_BIN = OSS_CAD_ROOT / "bin"
OSS_CAD_LIB = OSS_CAD_ROOT / "lib"
TOP = "sccomp_tb"
OUT = ROOT / "sccpu_sim.out"
VCD = ROOT / "sccpu_sid_sort.vcd"

SRCS = [
    "alu.v",
    "ctrl.v",
    "dm.v",
    "EXT.v",
    "im.v",
    "NPC.v",
    "PC.v",
    "sccomp.v",
    "sccomp_tb.v",
    "SCCPU.v",
    "RF.v",
]


def require_tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        candidate = OSS_CAD_BIN / f"{name}.exe"
        if candidate.exists():
            return str(candidate)
    if path is None:
        raise RuntimeError(f"Cannot find {name}. Please install it or add it to PATH.")
    return path


def run_command(cmd: list[str]) -> None:
    print("[CMD]", " ".join(cmd))
    env = dict(os.environ)
    if OSS_CAD_BIN.exists():
        env["PATH"] = f"{OSS_CAD_BIN};{OSS_CAD_LIB};" + env.get("PATH", "")
    subprocess.run(cmd, cwd=ROOT, check=True, env=env)


def build() -> None:
    iverilog = require_tool("iverilog")
    cmd = [
        iverilog,
        "-I",
        ".",
        "-s",
        TOP,
        "-o",
        OUT.name,
        *SRCS,
    ]
    run_command(cmd)


def simulate() -> None:
    vvp = require_tool("vvp")
    run_command([vvp, OUT.name])
    if VCD.exists():
        print(f"[OK] Waveform generated: {VCD.name}")
    else:
        print(f"[WARN] Simulation finished, but {VCD.name} was not found.")


def open_wave() -> None:
    gtkwave = shutil.which("gtkwave")
    if gtkwave is None:
        raise RuntimeError("Cannot find gtkwave. Please add GTKWave to PATH or open sccpu_sid_sort.vcd manually.")
    if not VCD.exists():
        raise RuntimeError(f"Cannot find {VCD.name}. Please run build.py run first.")
    subprocess.Popen([gtkwave, VCD.name], cwd=ROOT)
    print(f"[OK] GTKWave opened: {VCD.name}")


def clean() -> None:
    removed = False
    for path in (OUT, VCD):
        if path.exists():
            path.unlink()
            removed = True
            print(f"[OK] Removed {path.name}")

    for path in ROOT.glob("*.log"):
        path.unlink()
        removed = True
        print(f"[OK] Removed {path.name}")

    if not removed:
        print("[OK] Nothing to clean.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Lab-6 single-cycle CPU sid sorting simulation helper")
    parser.add_argument(
        "target",
        nargs="?",
        default="run",
        choices=("build", "run", "wave", "clean"),
        help="build: compile only; run: compile and simulate; wave: run and open GTKWave; clean: remove outputs",
    )
    args = parser.parse_args()

    try:
        if args.target == "build":
            build()
        elif args.target == "run":
            build()
            simulate()
        elif args.target == "wave":
            build()
            simulate()
            open_wave()
        elif args.target == "clean":
            clean()
    except (RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"[ERROR] {exc}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
