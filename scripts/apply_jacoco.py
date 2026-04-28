#!/usr/bin/env python3
"""apply_jacoco.py
================================================================================
Parse a JaCoCo XML coverage report and mark every class/method that JaCoCo
observed actually executing during the test run with
`entities.actually_called_in_ai_test = 1`.

JaCoCo bytecode instrumentation is zero-miss (no sampling, no polling) — every
single invocation is recorded by construction. This is the ground-truth signal
for "code that the runtime actually exercises on the target map".

Usage:
    python3 apply_jacoco.py --db PATH --xml PATH

Env vars:
    PORT_DB     sqlite database (default: ./port.sqlite)
    JACOCO_XML  path to jacoco.xml (default: ./jacoco.xml)
================================================================================
"""

import argparse
import os
import sqlite3
import sys
import xml.etree.ElementTree as ET

PRIMS = {
    "B": "byte", "C": "char", "D": "double", "F": "float",
    "I": "int",  "J": "long", "S": "short",  "Z": "boolean",
    "V": "void",
}


def decode_one(buf: str, i: int) -> tuple[str, int]:
    arr = 0
    while i < len(buf) and buf[i] == "[":
        arr += 1
        i += 1
    c = buf[i]
    if c in PRIMS:
        out = PRIMS[c]; i += 1
    elif c == "L":
        end = buf.index(";", i)
        out = buf[i + 1:end].replace("/", ".")
        i = end + 1
    else:
        raise ValueError(f"bad descriptor {buf!r} at {i}")
    return out + ("[]" * arr), i


def decode_args(desc: str) -> str:
    end = desc.index(")")
    body = desc[1:end]
    out = []
    i = 0
    while i < len(body):
        t, i = decode_one(body, i)
        out.append(t)
    return ",".join(out)


def parse_xml(path: str) -> tuple[set[str], set[str]]:
    structs: set[str] = set()
    procs:   set[str] = set()
    root = ET.parse(path).getroot()
    for pkg in root.findall("package"):
        for cls in pkg.findall("class"):
            fqcn = cls.attrib["name"].replace("/", ".")
            cls_called = False
            for m in cls.findall("method"):
                covered = 0
                for ctr in m.findall("counter"):
                    if ctr.attrib.get("type") == "INSTRUCTION":
                        covered = int(ctr.attrib.get("covered", "0"))
                        break
                if covered <= 0:
                    continue
                cls_called = True
                args = decode_args(m.attrib["desc"])
                procs.add(f"proc:{fqcn}#{m.attrib['name']}({args})")
            if cls_called:
                structs.add(f"struct:{fqcn}")
    return structs, procs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db",  default=os.environ.get("PORT_DB", "port.sqlite"))
    ap.add_argument("--xml", default=os.environ.get("JACOCO_XML", "jacoco.xml"))
    args = ap.parse_args()

    if not os.path.isfile(args.xml):
        sys.exit(f"missing {args.xml}")

    structs, procs = parse_xml(args.xml)
    print(f"jacoco: {len(structs)} classes touched, {len(procs)} methods touched")

    conn = sqlite3.connect(args.db)
    cur  = conn.cursor()
    cur.execute("UPDATE entities SET actually_called_in_ai_test = 0")
    called = list(structs | procs)
    matched = 0
    for i in range(0, len(called), 500):
        chunk = called[i:i + 500]
        ph = ",".join("?" * len(chunk))
        cur.execute(
            f"UPDATE entities SET actually_called_in_ai_test = 1 "
            f"WHERE primary_key IN ({ph})", chunk,
        )
        matched += cur.rowcount
    conn.commit()
    print(f"updated {matched} rows")
    cur.execute(
        "SELECT COUNT(*) FROM entities WHERE actually_called_in_ai_test = 1"
    )
    print(f"final: {cur.fetchone()[0]} entities marked called")
    conn.close()


if __name__ == "__main__":
    main()
