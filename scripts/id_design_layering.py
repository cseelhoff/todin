#!/usr/bin/env python3
"""id_design_layering.py
================================================================================
ID-based design what-if pass.

Given the `structs` table, run javap on each compiled .class and extract the
strict inheritance edges only (`extends X`, `implements I`). All other edges
(field types, method-body references) are dropped — under the ID-based design,
every cross-struct reference is replaced by a `*_Id :: distinct u32` and so
becomes a primitive, removing those edges from the type graph.

The resulting graph is (in practice) a DAG. We re-layer it and write
`scc_id` and `id_design_layer` back to the structs table.

Usage:
    python3 id_design_layering.py [--db PATH] [--triplea PATH]

Env vars:
    PORT_DB      sqlite database (default: ./port.sqlite)
    TRIPLEA_DIR  triplea checkout (default: ./triplea)
================================================================================
"""

import argparse
import os
import re
import sqlite3
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

# import SCC from sibling script
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from build_called_layered_tables import tarjan_sccs, assign_layers  # noqa: E402

CLASS_DIR_GLOBS = [
    "game-app/*/build/classes/java/main",
    "lib/*/build/classes/java/main",
    "http-clients/*/build/classes/java/main",
]

SIG_RE = re.compile(
    r"(?:class|interface|enum)\s+(\S+?)(?:\<.*?\>)?"
    r"(?:\s+extends\s+([^{]+?))?"
    r"(?:\s+implements\s+([^{]+?))?\s*\{",
)


def find_class_file(triplea: Path, fqcn: str) -> Path | None:
    rel = fqcn.replace(".", "/") + ".class"
    for pattern in CLASS_DIR_GLOBS:
        for root in triplea.glob(pattern):
            cand = root / rel
            if cand.is_file():
                return cand
    return None


def parse_javap(text: str) -> tuple[list[str], list[str]]:
    sig_line = ""
    for line in text.splitlines():
        if "{" in line and ("class " in line or "interface " in line or "enum " in line):
            sig_line = line
            break
    if not sig_line:
        return [], []
    m = SIG_RE.search(sig_line)
    if not m:
        return [], []
    ext_raw = (m.group(2) or "")
    impl_raw = (m.group(3) or "")
    def split(s):
        s = re.sub(r"<[^>]*>", "", s)
        return [t.strip() for t in s.split(",") if t.strip()]
    return split(ext_raw), split(impl_raw)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.environ.get("PORT_DB", "port.sqlite"))
    ap.add_argument("--triplea", default=os.environ.get("TRIPLEA_DIR", "triplea"))
    args = ap.parse_args()

    triplea = Path(args.triplea).resolve()
    conn = sqlite3.connect(args.db)
    cur = conn.cursor()

    structs = [r[0] for r in cur.execute("SELECT struct_key FROM structs")]
    struct_set = set(structs)
    print(f"resolving inheritance for {len(structs)} structs via javap...")

    inh_edges: dict[str, list[str]] = defaultdict(list)
    missing = parse_fail = 0
    for k in structs:
        fqcn = k[len("struct:"):]
        cf = find_class_file(triplea, fqcn)
        if cf is None:
            missing += 1
            continue
        try:
            out = subprocess.run(["javap", "-p", str(cf)],
                                 capture_output=True, text=True,
                                 check=True, timeout=10).stdout
        except Exception:
            parse_fail += 1
            continue
        ext, impl = parse_javap(out)
        for s in ext + impl:
            if s.startswith(("java.", "javax.", "lombok.")):
                continue
            tgt = "struct:" + s
            if tgt in struct_set and tgt != k:
                inh_edges[k].append(tgt)

    print(f"  missing class files: {missing}, javap failures: {parse_fail}")
    print(f"  inheritance-only edges retained: {sum(len(v) for v in inh_edges.values())}")

    sccs = tarjan_sccs(structs, inh_edges)
    layers, _ = assign_layers(struct_set, inh_edges, sccs)
    big = [s for s in sccs if len(s) > 1]
    print(f"  SCCs: {len(sccs)}, cycles: {len(big)}, "
          f"largest = {max((len(s) for s in big), default=1)}")

    scc_of = {n: i for i, comp in enumerate(sccs) for n in comp}
    cur.executemany(
        "UPDATE structs SET scc_id = ?, id_design_layer = ? WHERE struct_key = ?",
        [(scc_of[k], layers[k], k) for k in structs],
    )
    conn.commit()

    print("\n--- ID-design struct layers ---  layer | impl | total")
    for L, t, im in cur.execute(
        "SELECT id_design_layer, COUNT(*), "
        "SUM(CASE WHEN is_implemented=1 THEN 1 ELSE 0 END) "
        "FROM structs GROUP BY id_design_layer ORDER BY id_design_layer"
    ):
        print(f"  {L:>3} | {im:>4} | {t:>4}")

    if big:
        print("\nremaining cycles under ID design:")
        for comp in sorted(big, key=len, reverse=True):
            names = sorted(c[len('struct:'):] for c in comp)
            head = ", ".join(names[:5])
            tail = "..." if len(names) > 5 else ""
            print(f"  ({len(comp)}): {head}{tail}")
    conn.close()


if __name__ == "__main__":
    main()
