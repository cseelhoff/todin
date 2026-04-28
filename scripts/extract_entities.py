#!/usr/bin/env python3
"""extract_entities.py
================================================================================
Walk every compiled .class file under TRIPLEA_DIR (per gradle convention) and
populate two tables in PORT_DB:

  entities(primary_key, java_file_path, java_lines, odin_file_path,
           layer_number, is_fully_implemented_error_free_no_todo_no_stub,
           included, actually_called_in_ai_test)
  dependencies(primary_key, depends_on_key)

primary_key formats:
  struct:<fqcn>          # one row per class/interface/enum (incl. inner $)
  proc:<fqcn>#<name>(<comma-sep-arg-types-in-java-source-form>)

Edges added:
  struct A -> struct B   when A extends B, A implements B, or any A's field
                         has type B (these are the "type graph" edges)
  proc P  -> struct C    when P's body references class C (`new C(...)`,
                         `C.staticMethod`, etc.)
  proc P  -> proc Q      when P invokes Q (`invokevirtual`, `invokestatic`,
                         `invokespecial`, `invokeinterface`, `invokedynamic`)

Discovery uses `javap -p -c` (ships with every JDK). No build-time
deps beyond a JDK and Python 3.

Usage:
    python3 extract_entities.py [--db PATH] [--triplea PATH]

Env vars (used if flags omitted):
    PORT_DB       sqlite database to populate (default: ./port.sqlite)
    TRIPLEA_DIR   triplea checkout (must already be `gradle compileJava`'d)
================================================================================
"""

from __future__ import annotations

import argparse
import os
import re
import sqlite3
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

CLASS_DIR_GLOBS = [
    "game-app/*/build/classes/java/main",
    "lib/*/build/classes/java/main",
    "http-clients/*/build/classes/java/main",
]

EXCLUDED_PACKAGE_PREFIXES = (
    "java.", "javax.", "jakarta.", "lombok.",
    "org.slf4j.", "ch.qos.", "com.google.",
    "org.apache.", "org.eclipse.", "org.junit.",
    "io.netty.", "kotlin.", "scala.",
)


def find_class_dirs(triplea: Path) -> list[Path]:
    """Locate every .../build/classes/java/main directory below TRIPLEA_DIR."""
    out: list[Path] = []
    for pattern in CLASS_DIR_GLOBS:
        out.extend(p for p in triplea.glob(pattern) if p.is_dir())
    return out


def walk_class_files(roots: list[Path]) -> list[tuple[Path, str]]:
    """Yield (absolute path, fqcn-from-relative-path) for every .class file."""
    found: list[tuple[Path, str]] = []
    for root in roots:
        for cf in root.rglob("*.class"):
            rel = cf.relative_to(root)
            fqcn = str(rel.with_suffix("")).replace(os.sep, ".")
            found.append((cf, fqcn))
    return found


# ---------------------------------------------------------------------------
# JVM descriptor decoding
# ---------------------------------------------------------------------------

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
        out = PRIMS[c]
        i += 1
    elif c == "L":
        end = buf.index(";", i)
        out = buf[i + 1:end].replace("/", ".")
        i = end + 1
    else:
        raise ValueError(f"bad descriptor {buf!r} at {i}")
    return out + ("[]" * arr), i


def decode_args(desc: str) -> list[str]:
    """'(Ljava/lang/String;I)V' -> ['java.lang.String','int']."""
    assert desc.startswith("("), desc
    end = desc.index(")")
    body = desc[1:end]
    out: list[str] = []
    i = 0
    while i < len(body):
        t, i = decode_one(body, i)
        out.append(t)
    return out


def descriptor_classes(desc: str) -> list[str]:
    """Return every L...; class name in any descriptor (args or fields)."""
    return [
        m.group(1).replace("/", ".")
        for m in re.finditer(r"L([^;<>]+);", desc)
    ]


# ---------------------------------------------------------------------------
# javap parser
# ---------------------------------------------------------------------------

# Class signature line, e.g.:
#   public class games.strategy.engine.data.Unit extends games...GameDataComponent implements games...DynamicallyModifiable {
SIG_RE = re.compile(
    r"^[\w\s]*?(?:class|interface|enum)\s+(\S+?)(?:\<.*?\>)?"
    r"(?:\s+extends\s+([^{]+?))?"
    r"(?:\s+implements\s+([^{]+?))?\s*\{",
)

# Field declaration (rough, javap omits Code: for fields):
#   private final games.strategy.engine.data.UnitType type;
FIELD_RE = re.compile(
    r"^\s*(?:public|protected|private|static|final|transient|volatile|\s)+"
    r"([\w\.\$]+(?:\<[^>]*\>)?(?:\[\])*)\s+\w+\s*;\s*$",
)

# Bytecode comment patterns inside a method body:
#   invokevirtual #N                  // Method games/.../X.foo:(Lgames/...;)V
#   invokestatic  #N                  // Method games/.../X.foo:(I)V
#   invokespecial #N                  // Method games/.../X."<init>":()V
#   getfield      #N                  // Field type:Lgames/.../UnitType;
#   getstatic     #N                  // Field log:Lorg/slf4j/Logger;
#   new           #N                  // class games/strategy/engine/data/Unit
#   anewarray     #N                  // class games/.../Foo
#   checkcast     #N                  // class games/.../Foo
#   instanceof    #N                  // class games/.../Foo
INVOKE_RE = re.compile(
    r"//\s*(?:Method|InterfaceMethod)\s+([\w/$]+)(?:\.|\#)([^:]+):(\([^)]*\)[^\s]*)"
)
NEW_RE = re.compile(r"//\s*class\s+([\w/$\[\];]+)")
FIELD_REF_RE = re.compile(r"//\s*Field\s+(?:[\w/$]+\.)?[\w$]+:([^;\s]+;)")


def parse_javap(text: str) -> tuple[str, list[str], list[str], list[dict]]:
    """Parse one `javap -p -c` output. Returns:
        (fqcn, extends_list, implements_list, methods)
    where methods is a list of dicts:
        {"name": str, "args_java": list[str], "deps_struct": set[str],
         "deps_proc": set[str]}
    Field types are mixed into the class's struct deps via owner.
    """
    lines = text.splitlines()
    fqcn = ""
    ext: list[str] = []
    impl: list[str] = []
    methods: list[dict] = []
    struct_deps_from_fields: set[str] = set()

    i = 0
    n = len(lines)
    while i < n and not lines[i].strip().endswith("{"):
        i += 1
    if i < n:
        m = SIG_RE.search(lines[i])
        if m:
            fqcn = m.group(1)
            ext_raw = (m.group(2) or "").strip()
            impl_raw = (m.group(3) or "").strip()
            ext = _split_types(ext_raw)
            impl = _split_types(impl_raw)
        i += 1

    # Walk method blocks. javap -p -c emits methods alternating with their
    # bytecode. A method header looks like:
    #     public java.lang.String foo(int);
    #       descriptor: (I)Ljava/lang/String;
    #       Code:
    #          0: invokevirtual #N    // Method ...
    #          ...
    while i < n:
        line = lines[i]

        # field declaration (no descriptor / no Code)
        fm = FIELD_RE.match(line)
        if fm:
            t = fm.group(1).split("<", 1)[0].rstrip("[]")
            if t and "." in t:
                struct_deps_from_fields.add(t)
            i += 1
            continue

        # method header heuristic: a line ending in ");" (signature)
        # followed within a few lines by "descriptor:"
        if (line.rstrip().endswith(");") or line.rstrip().endswith(";")) \
                and "(" in line and not line.strip().startswith("//"):
            j = i + 1
            descriptor = ""
            while j < min(n, i + 4):
                ds = lines[j].strip()
                if ds.startswith("descriptor:"):
                    descriptor = ds[len("descriptor:"):].strip()
                    break
                j += 1
            if not descriptor:
                i += 1
                continue
            # collect bytecode until next blank line or next method header
            k = j + 1
            body: list[str] = []
            while k < n:
                if lines[k].strip() == "" or lines[k].rstrip() == "}":
                    break
                # next method header detection: indented signature
                if (lines[k].rstrip().endswith(");") and "(" in lines[k]
                        and not lines[k].lstrip().startswith("//")
                        and not lines[k].lstrip().startswith(("0:", "1:", "2:", "3:", "4:", "5:", "6:", "7:", "8:", "9:"))):
                    # peek next line — if it's "descriptor:" we hit a new method
                    if k + 1 < n and lines[k + 1].strip().startswith("descriptor:"):
                        break
                body.append(lines[k])
                k += 1

            mname = _extract_method_name(line)
            if mname:
                args = decode_args(descriptor.split(":", 1)[0]
                                   if ":" in descriptor else descriptor)
                # gather deps from bytecode
                proc_deps: set[str] = set()
                struct_deps: set[str] = set()
                for bl in body:
                    for m_inv in INVOKE_RE.finditer(bl):
                        owner = m_inv.group(1).replace("/", ".")
                        meth = m_inv.group(2)
                        mdesc = m_inv.group(3)
                        try:
                            margs = decode_args(mdesc)
                        except Exception:
                            margs = []
                        if not _excluded(owner):
                            proc_deps.add(
                                f"proc:{owner}#{meth}({','.join(margs)})"
                            )
                            struct_deps.add(owner)
                            for c in descriptor_classes(mdesc):
                                if not _excluded(c):
                                    struct_deps.add(c)
                    for m_new in NEW_RE.finditer(bl):
                        c = m_new.group(1).replace("/", ".").replace("[]", "")
                        if not _excluded(c):
                            struct_deps.add(c)
                    for m_fld in FIELD_REF_RE.finditer(bl):
                        for c in descriptor_classes(m_fld.group(1)):
                            if not _excluded(c):
                                struct_deps.add(c)
                # also add classes referenced in the method's own descriptor
                for c in descriptor_classes(descriptor):
                    if not _excluded(c):
                        struct_deps.add(c)

                methods.append({
                    "name": mname,
                    "args_java": args,
                    "deps_struct": struct_deps,
                    "deps_proc": proc_deps,
                })
            i = k
            continue

        i += 1

    # field-type deps belong to the struct itself, expressed as edges
    # struct:fqcn -> struct:T for each field type T
    return fqcn, ext, impl, methods


def _excluded(fqcn: str) -> bool:
    if not fqcn:
        return True
    if "." not in fqcn:
        return True   # primitive / unknown
    return fqcn.startswith(EXCLUDED_PACKAGE_PREFIXES)


def _split_types(s: str) -> list[str]:
    if not s:
        return []
    s = re.sub(r"<[^>]*>", "", s)
    return [t.strip() for t in s.split(",") if t.strip()]


def _extract_method_name(sig_line: str) -> str:
    """From `  public java.lang.String foo(int, int);` extract `foo`.
    For `  Unit(UnitType, GamePlayer);` (constructor) extract `<init>`."""
    sig = sig_line.strip().rstrip(";")
    paren = sig.find("(")
    if paren < 0:
        return ""
    head = sig[:paren].strip()
    parts = head.split()
    name = parts[-1] if parts else ""
    # constructor heuristic: name == simple class name (no return type)
    return name if name else ""


# ---------------------------------------------------------------------------
# Source-line lookup (best-effort: maps fqcn -> .java path on disk)
# ---------------------------------------------------------------------------

def build_java_source_index(triplea: Path) -> dict[str, str]:
    """Map FQCN (top-level only) -> absolute path to .java file."""
    idx: dict[str, str] = {}
    for jp in triplea.rglob("src/main/java/**/*.java"):
        # FQCN guess: directory after src/main/java + filename without .java
        parts = jp.parts
        try:
            anchor = parts.index("java")
        except ValueError:
            continue
        pkg = ".".join(parts[anchor + 1:-1])
        cls = jp.stem
        if pkg:
            idx[f"{pkg}.{cls}"] = str(jp)
        else:
            idx[cls] = str(jp)
    return idx


# ---------------------------------------------------------------------------
# Worker: run javap on one class file and return parsed result
# ---------------------------------------------------------------------------

def _javap_one(class_file: str) -> tuple[str, str, list[str], list[str], list[dict]]:
    try:
        out = subprocess.run(
            ["javap", "-p", "-c", "-s", class_file],
            capture_output=True, text=True, check=True, timeout=30,
        ).stdout
    except Exception as e:
        return class_file, "", [], [], []
    fqcn, ext, impl, methods = parse_javap(out)
    return class_file, fqcn, ext, impl, methods


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.environ.get("PORT_DB", "port.sqlite"))
    ap.add_argument("--triplea",
                    default=os.environ.get("TRIPLEA_DIR", "triplea"))
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4)
    args = ap.parse_args()

    triplea = Path(args.triplea).resolve()
    db_path = Path(args.db).resolve()

    if not triplea.is_dir():
        sys.exit(f"TRIPLEA_DIR not a directory: {triplea}")

    class_dirs = find_class_dirs(triplea)
    if not class_dirs:
        sys.exit(f"no compiled .class roots under {triplea}; "
                 f"run `gradle compileJava` first")
    print(f"scanning {len(class_dirs)} class roots...")
    cls_files = walk_class_files(class_dirs)
    print(f"  {len(cls_files)} .class files")

    java_idx = build_java_source_index(triplea)
    print(f"  java source index: {len(java_idx)} top-level classes")

    # parallel javap
    print(f"running javap with {args.workers} workers...")
    parsed: list[tuple[str, list[str], list[str], list[dict]]] = []
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(_javap_one, str(p)): p for p, _ in cls_files}
        done = 0
        for fut in as_completed(futs):
            _, fqcn, ext, impl, methods = fut.result()
            if fqcn:
                parsed.append((fqcn, ext, impl, methods))
            done += 1
            if done % 500 == 0:
                print(f"    {done}/{len(cls_files)}")
    print(f"  parsed {len(parsed)} classes")

    # write to sqlite
    db_path.unlink(missing_ok=True)
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript(
        """
        CREATE TABLE entities (
            primary_key   TEXT PRIMARY KEY,
            java_file_path TEXT,
            java_lines     TEXT,
            odin_file_path TEXT,
            layer_number   INTEGER,
            is_fully_implemented_error_free_no_todo_no_stub
                            INTEGER NOT NULL DEFAULT 0,
            included        INTEGER NOT NULL DEFAULT 1,
            actually_called_in_ai_test INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE dependencies (
            primary_key   TEXT,
            depends_on_key TEXT,
            PRIMARY KEY (primary_key, depends_on_key)
        );
        CREATE INDEX idx_dep_pk ON dependencies(primary_key);
        CREATE INDEX idx_dep_target ON dependencies(depends_on_key);
        """
    )

    entity_rows: list[tuple] = []
    dep_rows: set[tuple[str, str]] = set()

    for fqcn, ext, impl, methods in parsed:
        # struct row
        top = fqcn.split("$", 1)[0]
        java_path = java_idx.get(top, "")
        entity_rows.append((
            f"struct:{fqcn}", java_path, "", "", None, 0, 1, 0,
        ))
        # struct-level dep edges
        for parent in ext + impl:
            if not _excluded(parent):
                dep_rows.add((f"struct:{fqcn}", f"struct:{parent}"))
        # method rows + their deps
        for m in methods:
            args_str = ",".join(m["args_java"])
            mkey = f"proc:{fqcn}#{m['name']}({args_str})"
            entity_rows.append((mkey, java_path, "", "", None, 0, 1, 0))
            # owner edge
            dep_rows.add((mkey, f"struct:{fqcn}"))
            for s in m["deps_struct"]:
                if not _excluded(s):
                    dep_rows.add((mkey, f"struct:{s}"))
            for p in m["deps_proc"]:
                dep_rows.add((mkey, p))

    cur.executemany(
        "INSERT OR IGNORE INTO entities VALUES (?,?,?,?,?,?,?,?)",
        entity_rows,
    )
    cur.executemany(
        "INSERT OR IGNORE INTO dependencies VALUES (?,?)",
        list(dep_rows),
    )
    conn.commit()

    n_ent = cur.execute("SELECT COUNT(*) FROM entities").fetchone()[0]
    n_dep = cur.execute("SELECT COUNT(*) FROM dependencies").fetchone()[0]
    n_struct = cur.execute(
        "SELECT COUNT(*) FROM entities WHERE primary_key LIKE 'struct:%'"
    ).fetchone()[0]
    n_proc = cur.execute(
        "SELECT COUNT(*) FROM entities WHERE primary_key LIKE 'proc:%'"
    ).fetchone()[0]
    print(f"\nwrote {db_path}")
    print(f"  entities: {n_ent}  ({n_struct} structs, {n_proc} procs)")
    print(f"  dependencies: {n_dep}")
    conn.close()


if __name__ == "__main__":
    main()
