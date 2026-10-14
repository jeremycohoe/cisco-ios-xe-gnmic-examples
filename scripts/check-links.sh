#!/usr/bin/env bash
# Validate local markdown links and heading anchors across the repo.
# Usage: scripts/check-links.sh   (run from the repository root)
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import os
import re
import sys

def slug(heading):
    return re.sub(r"[^\w\s-]", "", heading.strip().lower()).replace(" ", "-")

markdown_files = [
    os.path.join(directory, name)
    for directory, _, names in os.walk(".")
    if ".git" not in directory
    for name in names
    if name.endswith(".md")
]

anchors = {}
for path in markdown_files:
    headings = {
        slug(line.lstrip("#").strip())
        for line in open(path, encoding="utf-8").read().splitlines()
        if re.match(r"#{1,6}\s", line)
    }
    anchors[os.path.normpath(path)] = headings

link_pattern = re.compile(r"\]\(([^)]+)\)")
problems = []
for path in markdown_files:
    base = os.path.dirname(path)
    for link in link_pattern.findall(open(path, encoding="utf-8").read()):
        if link.startswith(("http://", "https://", "mailto:")):
            continue
        target_path, _, fragment = link.partition("#")
        target = (
            os.path.normpath(os.path.join(base, target_path))
            if target_path
            else os.path.normpath(path)
        )
        if target_path and not os.path.exists(target):
            problems.append(f"{path}: missing file -> {link}")
        elif fragment and target in anchors and fragment not in anchors[target]:
            problems.append(f"{path}: missing anchor -> {link}")

if problems:
    print("\n".join(problems))
    print(f"{len(problems)} broken link(s)")
    sys.exit(1)

print(f"All local links OK ({len(markdown_files)} markdown files checked).")
PY
