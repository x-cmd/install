#!/usr/bin/env python3
"""
Add footprint.platform.{win,linux,darwin} and footprint.resource.disk.size.download
to x-cmd/install yml files, using install sizes from
x-cmd-install-stat/stat/.x-cmd/all.tsv.

For each row in all.tsv:
  - locate the matching yml by basename across x-cmd/install/src/
  - merge `footprint.platform.{win,linux,darwin}: full|none` based on the
    platform column
  - merge `footprint.resource.disk.size.download.{estimate, desc}` using the
    reference size (bytes) and description column

Existing keys (footprint.platform / download) are preserved if present;
values from all.tsv overwrite them so reruns stay idempotent.

Usage:
  python3 add-download-size.py
  python3 add-download-size.py --tsv /path/to/all.tsv --root /path/to/x-cmd/install
"""

import argparse
import os
import sys
from pathlib import Path

import ruamel.yaml
from ruamel.yaml.comments import CommentedMap


def human_bytes(n: int) -> str:
    """Format bytes as a clean human-readable string (KB/MB/GB), rounded to int."""
    if n < 1024:
        return f"{n} B"
    for unit, scale in (("KB", 1024), ("MB", 1024 ** 2), ("GB", 1024 ** 3), ("TB", 1024 ** 4)):
        if n < scale * 1024:
            return f"{round(n / scale)} {unit}"
    return f"{n} B"


def load_tsv(path: Path):
    rows = []
    with path.open() as f:
        header = f.readline().rstrip("\n").split("\t")
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) != len(header):
                continue
            rows.append(dict(zip(header, parts)))
    return rows


def find_yml(root: Path, name: str):
    """Find the yml file matching `name` (basename) under root/src/."""
    matches = list(root.glob(f"src/**/{name}.yml"))
    if not matches:
        return None
    # Prefer category directories that look like the topic (best-effort: shortest path wins)
    matches.sort(key=lambda p: (len(p.parts), str(p)))
    return matches[0]


def ensure_path(root, *keys):
    """Walk down a ruamel.yaml mapping, creating CommentedMap along the way."""
    cur = root
    for k in keys:
        nxt = cur.get(k)
        if nxt is None:
            nxt = CommentedMap()
            cur[k] = nxt
        cur = nxt
    return cur


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tsv", default="/Users/l/.x-repo/github.com/x-cmd-install/x-cmd-install-stat/stat/.x-cmd/all.tsv")
    ap.add_argument("--root", default="/Users/l/.x-repo/github.com/x-cmd/install")
    ap.add_argument("--write", action="store_true",
                    help="Actually write changes (default: dry-run)")
    args = ap.parse_args()

    tsv_path = Path(args.tsv)
    install_root = Path(args.root)

    yaml = ruamel.yaml.YAML()
    # The corpus uses both column-0 ('- x') and indented ('  - x') top-level seq
    # styles. sequence=0 + offset=0 minimizes churn for the majority column-0
    # case; the 1155 indented-seq files may shift by 2 spaces but YAML parses
    # identically. Mapping indent stays at 2.
    yaml.indent(mapping=2, sequence=0, offset=0)
    yaml.preserve_quotes = True
    yaml.width = 4096

    rows = load_tsv(tsv_path)
    updated = 0
    missing = []
    skipped = []

    for row in rows:
        name = row["software"]
        size_b = int(row["download-size"])
        desc = row["description"]            # e.g. linux/x64, macos/arm64, dmg
        platform_set = set((row.get("platform") or "").split(",")) - {""}

        yml_path = find_yml(install_root, name)
        if yml_path is None:
            missing.append(name)
            continue

        with yml_path.open() as f:
            data = yaml.load(f)

        if not isinstance(data, CommentedMap):
            skipped.append((name, "not a mapping"))
            continue

        # Ensure footprint: top-level
        fp = ensure_path(data, "footprint")

        # footprint.platform.{win,linux,darwin}: full|none
        plat = ensure_path(fp, "platform")
        for os_key in ("win", "linux", "darwin"):
            plat[os_key] = "full" if os_key in platform_set else "none"

        # footprint.resource.disk.size.download.{estimate, desc}
        size = ensure_path(fp, "resource", "disk", "size")
        download = ensure_path(size, "download")
        download["estimate"] = human_bytes(size_b)
        desc_cn = f"约 {human_bytes(size_b)} 下载 ({desc})"
        desc_en = f"~{human_bytes(size_b)} download ({desc})"
        ddesc = ensure_path(download, "desc")
        ddesc["cn"] = desc_cn
        ddesc["en"] = desc_en

        if args.write:
            with yml_path.open("w") as f:
                yaml.dump(data, f)
        updated += 1

    print(f"matched & updated: {updated}")
    print(f"missing yml in install repo: {len(missing)}")
    if missing:
        print("  sample:", ", ".join(missing[:10]))
    print(f"skipped: {len(skipped)}")
    if not args.write:
        print("(dry-run; pass --write to apply)")


if __name__ == "__main__":
    main()
