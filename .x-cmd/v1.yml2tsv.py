#!/usr/bin/env python3
"""
yml → tsv conversion for x-cmd install data.

Output TSV columns:
  name, category, lang, source, desc_cn, desc_en, binlist, rule, other

Usage:
    python3 yml2tsv.py                       # use defaults (./src → ./all.tsv)
    python3 yml2tsv.py /path/to/src          # custom src dir
    python3 yml2tsv.py /path/to/src -o out.tsv
    python3 yml2tsv.py /path/to/src -w 8     # 8 parallel workers
"""
import os
import sys
import json
import subprocess
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SRC = os.path.join(os.path.dirname(SCRIPT_DIR), "src")
DEFAULT_OUTPUT = os.path.join(os.getcwd(), "all.tsv")

# Single yq query per file — minimises subprocess overhead.
COMBINED_YQ_QUERY = (
    '{"lang": (.lang // ""), "homepage": (.homepage // ""), '
    '"desc_cn": (.desc.cn // ""), "desc_en": (.desc.en // ""), '
    '"binlist": .binlist, "rule": .rule, "license": .license, "x": .x, '
    '"footprint": .footprint}'
)
HEADER = ["name", "category", "lang", "source", "desc_cn", "desc_en", "binlist", "rule", "other"]


def escape_tsv(value):
    """Escape TSV special characters (backslash last)."""
    if not value:
        return ""
    value = value.replace('\\', '\\\\')
    value = value.replace('"', '\\"')
    value = value.replace('\n', '\\n')
    value = value.replace('\r', '\\r')
    value = value.replace('\t', '\\t')
    return value


def yq_query_all(file_path):
    """Run a single yq query and parse the JSON result."""
    try:
        result = subprocess.run(
            ['yq', '-o=json', COMBINED_YQ_QUERY, file_path],
            capture_output=True, text=True, timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
    except Exception:
        pass
    return None


def process_file(file_path):
    """Convert one yml file to a TSV row (list)."""
    name = os.path.basename(file_path)[:-4]   # strip .yml
    category = os.path.basename(os.path.dirname(file_path))

    data = yq_query_all(file_path) or {}

    lang = (data.get("lang") or "").strip()
    homepage = (data.get("homepage") or "").strip()
    desc_cn = escape_tsv((data.get("desc_cn") or "").strip())
    desc_en = escape_tsv((data.get("desc_en") or "").strip())

    binlist_raw = data.get("binlist")
    binlist = ",".join(str(x) for x in binlist_raw) if binlist_raw else name

    rule_raw = data.get("rule")
    rule = json.dumps(rule_raw, separators=(',', ':')) if rule_raw else ""

    other_obj = {}
    for k in ("homepage", "license", "x", "footprint"):
        v = data.get(k)
        if v is not None and v != "":
            other_obj[k] = v
    other = escape_tsv(json.dumps(other_obj, ensure_ascii=False, separators=(',', ':')))

    return [name, category, lang, homepage, desc_cn, desc_en, binlist, rule, other]


def collect_yml_files(src_dir):
    out = []
    for root, _, files in os.walk(src_dir):
        for f in files:
            if f.endswith('.yml'):
                out.append(os.path.join(root, f))
    return out


def main():
    parser = argparse.ArgumentParser(description='Convert yml files to TSV.')
    parser.add_argument('src_dir', nargs='?', default=DEFAULT_SRC,
                        help='Source directory containing yml files (default: ./src)')
    parser.add_argument('-o', '--output', default=DEFAULT_OUTPUT,
                        help='Output TSV file path (default: ./all.tsv)')
    parser.add_argument('-w', '--workers', type=int, default=0,
                        help='Parallel workers (default: cpu_count)')
    args = parser.parse_args()

    yml_files = collect_yml_files(args.src_dir)
    workers = args.workers if args.workers > 0 else (os.cpu_count() or 1)

    rows = []
    count = 0
    with ThreadPoolExecutor(max_workers=workers) as executor:
        future_to_file = {executor.submit(process_file, f): f for f in yml_files}
        for future in as_completed(future_to_file):
            file_path = future_to_file[future]
            try:
                row = future.result()
                rows.append(row)
                count += 1
                if count % 200 == 0:
                    print(f"Progress: {count}/{len(yml_files)}", file=sys.stderr)
            except Exception as e:
                print(f"Error processing {file_path}: {e}", file=sys.stderr)

    # as_completed returns rows in random order; sort by (category, name)
    # so the output is byte-stable across runs. The skip-if-unchanged
    # check downstream depends on this.
    rows.sort(key=lambda r: (r[1], r[0]))

    with open(args.output, 'w') as out:
        out.write('\t'.join(HEADER) + '\n')
        for row in rows:
            out.write('\t'.join(row) + '\n')

    print(f"Done. Output: {args.output}")
    print(f"Total: {count} entries")


if __name__ == "__main__":
    main()