#!/usr/bin/env python3
"""Generate git-style patch files and an HTML report for Verilog submissions."""

from __future__ import annotations

import argparse
import difflib
import html
import os
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable, Sequence


DEFAULT_COMPARISONS = (
    ("single-cycle", "CODExp/demo/sccpu_sim/source", "student-sc"),
    ("pipeline", "CODExp/demo/plcpu_sim/source", "student-pl"),
)


@dataclass
class DiffLine:
    kind: str
    old_no: int | None
    new_no: int | None
    text: str


@dataclass
class FileDiff:
    comparison: str
    rel_path: str
    status: str
    old_lines: list[str]
    new_lines: list[str]
    rows: list[DiffLine]
    patch: str
    added: int
    deleted: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare Verilog source directories and generate diff.patch plus "
            "a GitHub-like HTML report."
        )
    )
    parser.add_argument(
        "--base-sc",
        default=DEFAULT_COMPARISONS[0][1],
        help="single-cycle demo/source directory",
    )
    parser.add_argument(
        "--student-sc",
        default=DEFAULT_COMPARISONS[0][2],
        help="student single-cycle source directory",
    )
    parser.add_argument(
        "--base-pl",
        default=DEFAULT_COMPARISONS[1][1],
        help="pipeline/multi-cycle demo/source directory",
    )
    parser.add_argument(
        "--student-pl",
        default=DEFAULT_COMPARISONS[1][2],
        help="student pipeline/multi-cycle source directory",
    )
    parser.add_argument(
        "--pair",
        action="append",
        nargs=3,
        metavar=("NAME", "BASE_DIR", "STUDENT_DIR"),
        help=(
            "extra or custom comparison. Can be used more than once. "
            "If supplied, only --pair comparisons are generated."
        ),
    )
    parser.add_argument(
        "--ext",
        action="append",
        default=None,
        help="file extension to compare, for example .v. Repeat for more extensions.",
    )
    parser.add_argument(
        "--out",
        default="diff-report",
        help="output directory for diff.patch and report.html",
    )
    parser.add_argument(
        "--context",
        type=int,
        default=3,
        help="number of unchanged context lines in each diff hunk",
    )
    parser.add_argument(
        "--include-unchanged",
        action="store_true",
        help="include unchanged files in the HTML summary",
    )
    return parser.parse_args()


def normalize_extensions(raw_exts: Sequence[str] | None) -> tuple[str, ...]:
    if not raw_exts:
        return (".v",)
    exts: list[str] = []
    for ext in raw_exts:
        ext = ext.strip()
        if not ext:
            continue
        exts.append(ext if ext.startswith(".") else f".{ext}")
    return tuple(dict.fromkeys(exts)) or (".v",)


def read_text(path: Path) -> list[str]:
    data = path.read_bytes()
    for encoding in ("utf-8-sig", "utf-8", "gbk", "latin-1"):
        try:
            return data.decode(encoding).splitlines(keepends=True)
        except UnicodeDecodeError:
            continue
    return data.decode("latin-1", errors="replace").splitlines(keepends=True)


def collect_files(root: Path, exts: tuple[str, ...]) -> dict[str, Path]:
    if not root.exists():
        return {}
    files: dict[str, Path] = {}
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in exts:
            rel = path.relative_to(root).as_posix()
            files[rel] = path
    return files


def build_rows(old_lines: list[str], new_lines: list[str]) -> list[DiffLine]:
    matcher = difflib.SequenceMatcher(a=old_lines, b=new_lines)
    rows: list[DiffLine] = []
    old_no = 1
    new_no = 1
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            for offset in range(i2 - i1):
                rows.append(DiffLine("context", old_no, new_no, old_lines[i1 + offset]))
                old_no += 1
                new_no += 1
        elif tag == "delete":
            for line in old_lines[i1:i2]:
                rows.append(DiffLine("delete", old_no, None, line))
                old_no += 1
        elif tag == "insert":
            for line in new_lines[j1:j2]:
                rows.append(DiffLine("insert", None, new_no, line))
                new_no += 1
        elif tag == "replace":
            for line in old_lines[i1:i2]:
                rows.append(DiffLine("delete", old_no, None, line))
                old_no += 1
            for line in new_lines[j1:j2]:
                rows.append(DiffLine("insert", None, new_no, line))
                new_no += 1
    return rows


def make_patch(
    old_lines: list[str],
    new_lines: list[str],
    old_name: str,
    new_name: str,
    context: int,
) -> str:
    return "".join(
        difflib.unified_diff(
            old_lines,
            new_lines,
            fromfile=f"a/{old_name}",
            tofile=f"b/{new_name}",
            lineterm="\n",
            n=context,
        )
    )


def diff_pair(
    name: str,
    base_dir: Path,
    student_dir: Path,
    exts: tuple[str, ...],
    context: int,
    include_unchanged: bool,
) -> tuple[list[FileDiff], list[str]]:
    warnings: list[str] = []
    if not base_dir.exists():
        warnings.append(f"[{name}] base directory not found: {base_dir}")
    if not student_dir.exists():
        warnings.append(f"[{name}] student directory not found: {student_dir}")
    if warnings:
        return [], warnings

    base_files = collect_files(base_dir, exts)
    student_files = collect_files(student_dir, exts)
    rel_paths = sorted(set(base_files) | set(student_files))
    diffs: list[FileDiff] = []

    for rel_path in rel_paths:
        old_path = base_files.get(rel_path)
        new_path = student_files.get(rel_path)
        old_lines = read_text(old_path) if old_path else []
        new_lines = read_text(new_path) if new_path else []
        if old_path and new_path and old_lines == new_lines and not include_unchanged:
            continue

        if old_path and not new_path:
            status = "deleted"
        elif new_path and not old_path:
            status = "added"
        elif old_lines == new_lines:
            status = "unchanged"
        else:
            status = "modified"

        rows = build_rows(old_lines, new_lines)
        added = sum(1 for row in rows if row.kind == "insert")
        deleted = sum(1 for row in rows if row.kind == "delete")
        scoped_path = f"{name}/{rel_path}"
        patch = "" if status == "unchanged" else make_patch(
            old_lines, new_lines, scoped_path, scoped_path, context
        )
        diffs.append(
            FileDiff(
                comparison=name,
                rel_path=rel_path,
                status=status,
                old_lines=old_lines,
                new_lines=new_lines,
                rows=rows,
                patch=patch,
                added=added,
                deleted=deleted,
            )
        )
    return diffs, warnings


def row_visible(rows: list[DiffLine], index: int, context: int) -> bool:
    if rows[index].kind != "context":
        return True
    start = max(0, index - context)
    end = min(len(rows), index + context + 1)
    return any(row.kind != "context" for row in rows[start:end])


def render_rows(rows: list[DiffLine], context: int) -> str:
    parts: list[str] = []
    skipped = False
    for index, row in enumerate(rows):
        if row.kind == "context" and not row_visible(rows, index, context):
            if not skipped:
                parts.append(
                    '<tr class="skip"><td class="ln"></td><td class="ln"></td>'
                    '<td class="code">...</td></tr>'
                )
                skipped = True
            continue
        skipped = False
        marker = {"insert": "+", "delete": "-", "context": " "}[row.kind]
        old_no = "" if row.old_no is None else str(row.old_no)
        new_no = "" if row.new_no is None else str(row.new_no)
        text = html.escape(row.text.rstrip("\n\r"))
        parts.append(
            f'<tr class="{row.kind}"><td class="ln">{old_no}</td>'
            f'<td class="ln">{new_no}</td><td class="code">'
            f'<span class="marker">{marker}</span>{text}</td></tr>'
        )
    return "\n".join(parts)


def render_html(
    diffs: list[FileDiff],
    warnings: list[str],
    output_dir: Path,
    context: int,
    comparisons: Iterable[tuple[str, Path, Path]],
) -> str:
    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    total_added = sum(item.added for item in diffs)
    total_deleted = sum(item.deleted for item in diffs)
    changed_count = sum(1 for item in diffs if item.status != "unchanged")
    comparison_rows = "\n".join(
        f"<li><strong>{html.escape(name)}</strong>: "
        f"{html.escape(str(base))} -> {html.escape(str(student))}</li>"
        for name, base, student in comparisons
    )
    warning_html = ""
    if warnings:
        warning_html = "<section class=\"warnings\"><h2>Warnings</h2><ul>" + "".join(
            f"<li>{html.escape(warning)}</li>" for warning in warnings
        ) + "</ul></section>"

    file_items = "\n".join(
        f"""
        <details class="file" id="file-{index}">
          <summary>
            <span class="file-title">
              <span class="status {item.status}">{html.escape(item.status)}</span>
              <strong class="path">{html.escape(item.comparison)}/{html.escape(item.rel_path)}</strong>
            </span>
            <span class="numbers">+{item.added} -{item.deleted}</span>
          </summary>
          <table>
            <colgroup>
              <col class="line-col">
              <col class="line-col">
              <col>
            </colgroup>
            <tbody>
              {render_rows(item.rows, context)}
            </tbody>
          </table>
        </details>
        """
        for index, item in enumerate(diffs)
    ) or '<div class="empty">No matching changes found.</div>'

    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Verilog Diff Report</title>
  <style>
    :root {{
      color-scheme: light;
      --border: #d0d7de;
      --text: #1f2328;
      --muted: #656d76;
      --bg: #f6f8fa;
      --add-bg: #dafbe1;
      --add-line: #aceebb;
      --del-bg: #ffebe9;
      --del-line: #ffcecb;
      --code-bg: #ffffff;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }}
    main {{ max-width: 1180px; margin: 0 auto; padding: 24px; }}
    h1 {{ margin: 0 0 8px; font-size: 26px; }}
    h2 {{ margin: 0 0 12px; font-size: 18px; }}
    .meta, .numbers {{ color: var(--muted); }}
    .overview, .warnings, .files {{
      background: #fff;
      border: 1px solid var(--border);
      border-radius: 8px;
      margin-top: 16px;
    }}
    .overview {{ padding: 16px 18px; }}
    .overview ul, .warnings ul {{ margin: 8px 0 0; padding-left: 22px; }}
    .stats {{
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 14px;
    }}
    .stats span {{
      border: 1px solid var(--border);
      border-radius: 999px;
      padding: 4px 10px;
      background: #fff;
    }}
    .warnings {{ padding: 14px 18px; border-color: #d29922; background: #fff8c5; }}
    .files {{ overflow: hidden; }}
    .empty {{
      padding: 12px 14px;
      color: var(--muted);
    }}
    .file {{
      border-top: 1px solid var(--border);
      overflow: hidden;
    }}
    .file:first-child {{ border-top: 0; }}
    .file summary {{
      display: flex;
      gap: 10px;
      align-items: center;
      padding: 10px 14px;
      color: var(--text);
      cursor: pointer;
      font-family: ui-monospace, SFMono-Regular, Consolas, "Liberation Mono", monospace;
      list-style: none;
    }}
    .file summary::-webkit-details-marker {{ display: none; }}
    .file summary::before {{
      content: "+";
      flex: 0 0 16px;
      color: var(--muted);
      font-weight: 600;
      text-align: center;
    }}
    .file[open] summary {{
      border-bottom: 1px solid var(--border);
      background: #f6f8fa;
    }}
    .file[open] summary::before {{ content: "-"; }}
    .file summary:hover {{ background: #f6f8fa; }}
    .file-title {{
      display: flex;
      gap: 10px;
      align-items: center;
      min-width: 0;
    }}
    .path {{ overflow-wrap: anywhere; }}
    .file summary .numbers {{
      margin-left: auto;
      white-space: nowrap;
    }}
    .status {{
      display: inline-block;
      min-width: 68px;
      border-radius: 999px;
      padding: 2px 8px;
      text-align: center;
      color: #fff;
      font: 12px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }}
    .status.modified {{ background: #8250df; }}
    .status.added {{ background: #1a7f37; }}
    .status.deleted {{ background: #cf222e; }}
    .status.unchanged {{ background: #57606a; }}
    table {{
      width: 100%;
      border-collapse: collapse;
      background: var(--code-bg);
      table-layout: fixed;
    }}
    col.line-col {{ width: 56px; }}
    td {{
      padding: 0;
      vertical-align: top;
      font-family: ui-monospace, SFMono-Regular, Consolas, "Liberation Mono", monospace;
      font-size: 12px;
      line-height: 20px;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
    }}
    .ln {{
      width: 56px;
      color: var(--muted);
      text-align: right;
      padding: 0 10px;
      border-right: 1px solid var(--border);
      user-select: none;
    }}
    .code {{ padding-left: 10px; }}
    .marker {{ display: inline-block; width: 18px; color: var(--muted); }}
    tr.insert td {{ background: var(--add-bg); }}
    tr.insert .ln {{ background: var(--add-line); }}
    tr.delete td {{ background: var(--del-bg); }}
    tr.delete .ln {{ background: var(--del-line); }}
    tr.skip td {{ background: #f6f8fa; color: var(--muted); }}
    @media (max-width: 760px) {{
      main {{ padding: 14px; }}
      .file summary {{ align-items: flex-start; }}
      .file-title {{ align-items: flex-start; flex-direction: column; }}
      .file summary .numbers {{ margin-left: 26px; }}
      col.line-col {{ width: 42px; }}
      .ln {{ width: 42px; padding: 0 6px; }}
    }}
  </style>
</head>
<body>
  <main>
    <h1>Verilog Diff Report</h1>
    <div class="meta">Generated at {html.escape(generated_at)}. Patch file: {html.escape(str(output_dir / "diff.patch"))}</div>
    <section class="overview">
      <h2>Comparisons</h2>
      <ul>{comparison_rows}</ul>
      <div class="stats">
        <span>{changed_count} changed files</span>
        <span>+{total_added} additions</span>
        <span>-{total_deleted} deletions</span>
      </div>
    </section>
    {warning_html}
    <section class="files">
      {file_items}
    </section>
  </main>
</body>
</html>
"""


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd()
    output_dir = Path(args.out)
    output_dir.mkdir(parents=True, exist_ok=True)
    exts = normalize_extensions(args.ext)
    raw_pairs = args.pair or (
        ("single-cycle", args.base_sc, args.student_sc),
        ("pipeline", args.base_pl, args.student_pl),
    )
    comparisons = [
        (name, Path(base), Path(student))
        for name, base, student in raw_pairs
    ]

    all_diffs: list[FileDiff] = []
    warnings: list[str] = []
    for name, base, student in comparisons:
        diffs, pair_warnings = diff_pair(
            name,
            base if base.is_absolute() else repo_root / base,
            student if student.is_absolute() else repo_root / student,
            exts,
            args.context,
            args.include_unchanged,
        )
        all_diffs.extend(diffs)
        warnings.extend(pair_warnings)

    patch_text = "\n".join(item.patch for item in all_diffs if item.patch)
    patch_path = output_dir / "diff.patch"
    patch_path.write_text(patch_text, encoding="utf-8", newline="\n")

    html_text = render_html(all_diffs, warnings, output_dir, args.context, comparisons)
    html_path = output_dir / "report.html"
    html_path.write_text(html_text, encoding="utf-8", newline="\n")

    changed = sum(1 for item in all_diffs if item.status != "unchanged")
    additions = sum(item.added for item in all_diffs)
    deletions = sum(item.deleted for item in all_diffs)
    print(f"Compared extensions: {', '.join(exts)}")
    print(f"Changed files: {changed}, additions: {additions}, deletions: {deletions}")
    print(f"Wrote {patch_path}")
    print(f"Wrote {html_path}")
    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
