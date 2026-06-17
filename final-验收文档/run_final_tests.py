#!/usr/bin/env python3
import json
import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
FINAL = ROOT.parent / "final" / "verilog-tests"
EXPECTED = json.loads((FINAL / "tests" / "expected_results.json").read_text())


def run(cmd, cwd):
    return subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )


def resolve_expected(key):
    data = EXPECTED[key]
    if "same_as" in data:
        return resolve_expected(data["same_as"])
    return data


def compile_targets():
    sc_cmd = [
        "iverilog", "-I", ".", "-s", "sc_final_tb", "-o", "sc_final.out",
        "alu.v", "ctrl.v", "dm.v", "EXT.v", "im.v", "NPC.v", "PC.v",
        "sccomp.v", "SCCPU.v", "RF.v",
        "../../final/verilog-tests/tb/sc_final_tb.v",
    ]
    pl_cmd = [
        "iverilog", "-I", ".", "-s", "pl_final_tb", "-o", "pl_final.out",
        "PipelineCPU.v", "pipe_decode.v", "pipe_alu.v", "pipe_branch.v",
        "hazard_unit.v", "dm.v", "im.v", "plcomp.v", "RF.v",
        "../../final/verilog-tests/tb/pl_final_tb.v",
    ]
    for cmd, cwd in [(sc_cmd, ROOT / "source-sc"), (pl_cmd, ROOT / "source-pipeline")]:
        result = run(cmd, cwd)
        if result.returncode != 0:
            print(result.stdout)
            raise SystemExit(result.returncode)


def run_one(kind, key):
    cwd = ROOT / ("source-sc" if kind == "sc" else "source-pipeline")
    out = "sc_final.out" if kind == "sc" else "pl_final.out"
    cycles = "+CYCLES=80" if kind == "sc" else "+CYCLES=160"
    result = run(
        ["vvp", out, f"+IMEM=../../final/verilog-tests/tests/{key}", cycles],
        cwd,
    )
    regs = dict(re.findall(r"\[REG\] x(\d+)=(\w{8})", result.stdout))
    misses = []
    for reg, want in resolve_expected(key)["regs"].items():
        got = "0x" + regs.get(reg[1:], "????????").lower()
        want = want.lower()
        if got != want:
            misses.append(f"{reg}: got {got}, want {want}")
    return result.returncode == 0 and not misses, misses


def main():
    compile_targets()
    results = []
    for key in [k for k in EXPECTED if k.startswith("sc/")]:
        ok, misses = run_one("sc", key)
        results.append((key, ok, misses))
    for key in [k for k in EXPECTED if k.startswith("pl/")]:
        ok, misses = run_one("pl", key)
        results.append((key, ok, misses))

    for key, ok, misses in results:
        print(("[PASS]" if ok else "[FAIL]"), key)
        for miss in misses:
            print("  ", miss)

    failed = [item for item in results if not item[1]]
    print(f"Summary: {len(results) - len(failed)}/{len(results)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
