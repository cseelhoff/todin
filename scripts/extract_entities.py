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

# Test-source class roots. The smoke-testing module's test classes hold
# the actual entry-point of the JaCoCo trace (`Ww2v5JacocoRun.run`,
# `SnapshotHarness.wrapStep`, `GameTestUtils.setUpGameWithAis`). They are
# NOT scanned by default because we don't port them to Odin (the Odin
# port uses its own `test_server_game.odin` harness). Set
# `INCLUDE_TEST_CLASSES=1` (or pass `--include-tests`) to add them so
# layering captures the full call chain from the harness top down
# through the engine. Test-class entities are tagged `is_test_harness=1`
# so reporting + auto-impl scripts can skip them.
TEST_CLASS_DIR_GLOBS = [
    "game-app/*/build/classes/java/test",
    "lib/*/build/classes/java/test",
    "http-clients/*/build/classes/java/test",
]

EXCLUDED_PACKAGE_PREFIXES = (
    "java.", "javax.", "jakarta.", "lombok.",
    "org.slf4j.", "ch.qos.", "com.google.",
    "org.apache.", "org.eclipse.", "org.junit.",
    "io.netty.", "kotlin.", "scala.",
)

# UI-taint detection: TripleA classes whose ancestry roots in Swing/AWT
# widgets are statically referenced by the snapshot harness's setup code
# (constructors, factory wiring) but never actually rendered or interacted
# with at runtime. JaCoCo records their class-init invocation, so they
# leak into `actually_called_in_ai_test`. We tag them `is_ui = 1` here
# and `build_called_layered_tables.py` skips them when building the
# port-target structs/methods tables.
#
# Exception: java.awt.Point and java.awt.Color are pure value types used
# throughout engine math (territory centers, player colors) and are
# explicitly allowed as fields/parents.
UI_PACKAGE_PREFIXES = ("javax.swing.", "java.awt.")
UI_ALLOWED_TYPES = {"java.awt.Point", "java.awt.Color"}
# TripleA's own Swing helper package (`org.triplea.swing.*`) is also a UI
# boundary: any engine class that takes one of its types as a field or
# method-signature element is real UI client code (e.g. the startup-mc /
# selector-panel models that thread a Swing parent through their public
# API). Treat those references the same as raw javax.swing/java.awt refs
# when seeding the taint set.
UI_TRIPLEA_PREFIXES = ("org.triplea.swing.",)


def _is_ui_jdk(fqcn: str) -> bool:
    """Direct Swing/AWT JDK widget type, excluding the Point/Color value types."""
    if not fqcn or fqcn in UI_ALLOWED_TYPES:
        return False
    return fqcn.startswith(UI_PACKAGE_PREFIXES)


def _is_ui_taint_source(fqcn: str) -> bool:
    """Type whose appearance as a field/method-signature element should taint
    the referencing TripleA class. Same as `_is_ui_jdk` plus the TripleA-side
    `org.triplea.swing.*` helper package."""
    if not fqcn or fqcn in UI_ALLOWED_TYPES:
        return False
    return fqcn.startswith(UI_PACKAGE_PREFIXES) or fqcn.startswith(UI_TRIPLEA_PREFIXES)


def find_class_dirs(triplea: Path,
                    include_tests: bool = False) -> list[tuple[Path, bool]]:
    """Locate every .../build/classes/java/{main,test} directory.

    Returns list of (path, is_test) pairs. Test roots are only included
    when `include_tests=True`.
    """
    out: list[tuple[Path, bool]] = []
    for pattern in CLASS_DIR_GLOBS:
        for p in triplea.glob(pattern):
            if p.is_dir():
                out.append((p, False))
    if include_tests:
        for pattern in TEST_CLASS_DIR_GLOBS:
            for p in triplea.glob(pattern):
                if p.is_dir():
                    out.append((p, True))
    return out


def walk_class_files(roots: list[tuple[Path, bool]]) -> list[tuple[Path, str, bool]]:
    """Yield (absolute path, fqcn-from-relative-path, is_test) for every .class file."""
    found: list[tuple[Path, str, bool]] = []
    for root, is_test in roots:
        for cf in root.rglob("*.class"):
            rel = cf.relative_to(root)
            fqcn = str(rel.with_suffix("")).replace(os.sep, ".")
            found.append((cf, fqcn, is_test))
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


# Source-form FQCN matcher used to pull generic type-argument classes from
# javap's source-style declarations (e.g.
#   `private java.util.List<org.triplea.foo.Bar$Baz> elements;`).
# Bytecode descriptors lose generic info under type erasure, so the
# `descriptor:` line for that field is just `Ljava/util/List;` — the
# `Bar$Baz` reference would be invisible without harvesting the source
# line. Inner classes are emitted by javap with `$` here, matching the
# `struct:<fqcn>` keys we use elsewhere.
SOURCE_FQCN_RE = re.compile(r"\b([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*)+(?:\$[A-Za-z_][\w]*)*)\b")


def source_form_classes(text: str) -> list[str]:
    """Extract every dotted-FQCN-looking token from a javap source-form line.

    Used on field declarations and method headers to recover classes that
    appear inside generic angle brackets (lost in the erased descriptor).
    Excluded packages (java.*, javax.*, etc.) are filtered by the caller
    via `_excluded`.
    """
    return [m.group(1) for m in SOURCE_FQCN_RE.finditer(text)]


# ---------------------------------------------------------------------------
# javap parser
# ---------------------------------------------------------------------------

# Class signature line. javap emits this two ways:
#   non-verbose (`-c`): one line ending in `{`, e.g.
#     `public class games.strategy.engine.data.Unit extends ... {`
#   verbose (`-v`): the signature line has no trailing `{` (the `{` opens
#     the body 400+ lines later, after the constant pool dump).
# `SIG_RE` matches both forms (the trailing `{` is optional).
SIG_RE = re.compile(
    r"^[\w\s]*?(?:class|interface|enum)\s+(\S+?)(?:\<.*?\>)?"
    r"(?:\s+extends\s+([^{]+?))?"
    r"(?:\s+implements\s+([^{]+?))?\s*\{?\s*$",
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
# javap formats invocations one of two ways:
#  (a) `// Method games/.../X.foo:(args)ret`  -- explicit owner, common case
#  (b) `// Method foo:(args)ret`             -- owner-less, used when the
#       caller invokes a method on the same class (most often `new`+
#       `<init>`, but also any plain `this.foo()` / `super.foo()` site).
# We must capture both; otherwise every same-class call edge is silently
# dropped, including all constructor invocations after `new`.
INVOKE_RE = re.compile(
    r"//\s*(?:Method|InterfaceMethod)\s+([\w/$]+)(?:\.|\#)([^:]+):(\([^)]*\)[^\s]*)"
)
INVOKE_NO_OWNER_RE = re.compile(
    r"//\s*(?:Method|InterfaceMethod)\s+(\"<init>\"|[A-Za-z_$][\w$]*):(\([^)]*\)[^\s]*)"
)
NEW_RE = re.compile(r"//\s*class\s+([\w/$\[\];]+)")
FIELD_REF_RE = re.compile(r"//\s*Field\s+(?:[\w/$]+\.)?[\w$]+:([^;\s]+;)")

# Constant-pool method references (only visible with `javap -v`). These
# appear for every method reference (`Foo::bar`, `Foo::new`) used in the
# class, including the targets of method-reference-style lambdas which
# javap's `-c` invokedynamic comment doesn't expose. Captures both
# Methodref / InterfaceMethodref pool entries and MethodHandle entries
# resolving to them.
CP_METHODREF_RE = re.compile(
    r"=\s*(?:Methodref|InterfaceMethodref|MethodHandle)\b.*?//\s*"
    r"(?:REF_\w+\s+)?"
    r"([\w/$]+)\.[\w<>\"$]+:(\([^)]*\)[^\s]*)"
)


def _normalize_method_name(name: str) -> str:
    """javap quotes special method names like `"<init>"`. Strip quotes so
    method-key lookups match the entity row that `_extract_method_name`
    emits (which uses the unquoted form)."""
    if name.startswith('"') and name.endswith('"'):
        name = name[1:-1]
    return name


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
    struct_kind: str = "class"  # default if we fail to detect

    i = 0
    n = len(lines)
    # Find the class signature line. With `-c`, the sig line ends in `{`.
    # With `-v`, the sig line has no trailing `{` (the `{` opens the body
    # 400+ lines later, past the constant pool). We accept either: scan
    # for the first line whose `(class|interface|enum) <fqcn>` pattern
    # matches SIG_RE.
    sig_idx = -1
    while i < n:
        s = lines[i].strip()
        if re.search(r"\b(class|interface|enum)\s+[\w$.]+", s):
            m = SIG_RE.search(lines[i])
            if m:
                sig_idx = i
                break
        i += 1
    if sig_idx >= 0:
        m = SIG_RE.search(lines[sig_idx])
        if m:
            fqcn = m.group(1)
            ext_raw = (m.group(2) or "").strip()
            impl_raw = (m.group(3) or "").strip()
            ext = _split_types(ext_raw)
            impl = _split_types(impl_raw)
        # Determine the struct kind from the signature line.
        #   `interface` -> 'interface'
        #   `enum`      -> 'enum'
        #   `abstract class` -> 'abstract_class'
        #   `class` (without abstract) -> 'class'
        sig_text = lines[sig_idx]
        if re.search(r"\binterface\s+[\w$.]+", sig_text):
            struct_kind = "interface"
        elif re.search(r"\benum\s+[\w$.]+", sig_text):
            struct_kind = "enum"
        elif re.search(r"\babstract\s+class\s+[\w$.]+", sig_text):
            struct_kind = "abstract_class"
        else:
            struct_kind = "class"
        i = sig_idx + 1
        # In verbose mode the actual class body opens 400+ lines later
        # with a standalone `{` after the constant pool dump. Skip past
        # the constant pool so we don't try to parse pool entries as
        # field/method declarations.
        if not lines[sig_idx].rstrip().endswith("{"):
            while i < n and lines[i].strip() != "{":
                i += 1
            if i < n:
                i += 1  # step past the `{` line

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
            # Also harvest generic type-argument classes from the source
            # line (e.g. `List<org.triplea.Foo$Bar>` → Foo$Bar). These are
            # invisible in the erased descriptor.
            for c in source_form_classes(line):
                if not _excluded(c) and c != fqcn:
                    struct_deps_from_fields.add(c)
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

            mname = _extract_method_name(line, fqcn)
            if mname:
                args = decode_args(descriptor.split(":", 1)[0]
                                   if ":" in descriptor else descriptor)
                # gather deps from bytecode
                proc_deps: set[str] = set()
                struct_deps: set[str] = set()
                for bl in body:
                    matched = False
                    for m_inv in INVOKE_RE.finditer(bl):
                        matched = True
                        owner = m_inv.group(1).replace("/", ".")
                        meth = _normalize_method_name(m_inv.group(2))
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
                    if not matched:
                        # Fallback for owner-less invokes — owner is the
                        # current class. This catches every `<init>` after
                        # `new`, plus same-class virtual / static calls.
                        for m_inv2 in INVOKE_NO_OWNER_RE.finditer(bl):
                            meth = _normalize_method_name(m_inv2.group(1))
                            mdesc = m_inv2.group(2)
                            try:
                                margs = decode_args(mdesc)
                            except Exception:
                                margs = []
                            if fqcn and not _excluded(fqcn):
                                proc_deps.add(
                                    f"proc:{fqcn}#{meth}({','.join(margs)})"
                                )
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
                # and harvest generic type-argument classes from the
                # source-form method header (recovers types lost to erasure
                # in the descriptor, e.g. `List<Foo$Bar>` return types or
                # parameters).
                for c in source_form_classes(line):
                    if not _excluded(c) and c != fqcn:
                        struct_deps.add(c)

                methods.append({
                    "name": mname,
                    "args_java": args,
                    "deps_struct": struct_deps,
                    "deps_proc": proc_deps,
                    # Abstract / interface methods have a `descriptor:` line
                    # but no `Code:` block — javap emits no bytecode for
                    # them, so the `body` we collected is empty. This signal
                    # is what `build_called_layered_tables.py` uses to
                    # synthesize virtual-dispatch edges to concrete
                    # overriders, so the abstract proc participates in
                    # layering instead of bottoming out at layer 0.
                    "is_abstract": (len(body) == 0)
                            or (" abstract " in line)
                            or line.lstrip().startswith("abstract "),
                })
            i = k
            continue

        i += 1

    # field-type deps belong to the struct itself, expressed as edges
    # struct:fqcn -> struct:T for each field type T (including generic
    # type-arguments harvested from javap's source-form lines).
    #
    # Constant-pool method references: every `Foo::bar` / `Foo::new`
    # (method-reference-style lambda) shows up as a Methodref +
    # MethodHandle entry in the verbose constant pool. The InvokeDynamic
    # bytecode comment omits the target class, so without the constant
    # pool we can't see (e.g.) `TwoIfBySeaEndTurnDelegate::new` in
    # `XmlGameElementMapper.newTwoIfBySeaDelegateFactories()`. We harvest
    # them as class-level struct deps + class-level proc deps; per-method
    # attribution would need bootstrap-method table parsing which isn't
    # worth the complexity for the gain.
    cp_struct_deps: set[str] = set()
    cp_proc_deps: set[str] = set()
    for ln in lines:
        m_cp = CP_METHODREF_RE.search(ln)
        if not m_cp:
            continue
        owner = m_cp.group(1).replace("/", ".")
        # extract the method name between `.` and `:`
        # we re-find it in the // comment
        cm = re.search(r"//\s*(?:REF_\w+\s+)?[\w/$]+\.([\w<>\"$]+):(\([^)]*\)[^\s]*)", ln)
        if cm and not _excluded(owner):
            meth = _normalize_method_name(cm.group(1))
            mdesc = cm.group(2)
            try:
                margs = decode_args(mdesc)
            except Exception:
                margs = []
            cp_proc_deps.add(f"proc:{owner}#{meth}({','.join(margs)})")
            cp_struct_deps.add(owner)
            for c in descriptor_classes(mdesc):
                if not _excluded(c):
                    cp_struct_deps.add(c)
    return fqcn, ext, impl, methods, struct_deps_from_fields, cp_struct_deps, cp_proc_deps, struct_kind


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


def _extract_method_name(sig_line: str, fqcn: str = "") -> str:
    """From `  public java.lang.String foo(int, int);` extract `foo`.
    For `  public games.strategy.engine.data.Unit(UnitType, GamePlayer);`
    (constructor) extract `<init>` so the method-key matches the form
    javap uses on call sites (`Method "<init>":...`)."""
    sig = sig_line.strip().rstrip(";")
    paren = sig.find("(")
    if paren < 0:
        return ""
    head = sig[:paren].strip()
    parts = head.split()
    name = parts[-1] if parts else ""
    if not name:
        return ""
    # Constructor heuristic: javap emits the FQ class name (or the simple
    # name for inner classes via `Outer.Inner` form) where a normal method
    # would have a return type + name. Match either against `fqcn`.
    if fqcn:
        simple = fqcn.split(".")[-1].split("$")[-1]
        last = name.split(".")[-1].split("$")[-1]
        if name == fqcn or last == simple:
            return "<init>"
    return name


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

def _javap_one(class_file: str, is_test: bool = False):
    try:
        out = subprocess.run(
            ["javap", "-p", "-c", "-s", "-v", class_file],
            capture_output=True, text=True, check=True, timeout=60,
        ).stdout
    except Exception:
        return class_file, "", [], [], [], set(), set(), set(), "class", is_test
    fqcn, ext, impl, methods, field_deps, cp_structs, cp_procs, struct_kind = parse_javap(out)
    return class_file, fqcn, ext, impl, methods, field_deps, cp_structs, cp_procs, struct_kind, is_test


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.environ.get("PORT_DB", "port.sqlite"))
    ap.add_argument("--triplea",
                    default=os.environ.get("TRIPLEA_DIR", "triplea"))
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4)
    ap.add_argument(
        "--include-tests",
        action="store_true",
        default=os.environ.get("INCLUDE_TEST_CLASSES", "0") == "1",
        help=("also scan build/classes/java/test roots; harness entries "
              "are tagged is_test_harness=1"),
    )
    args = ap.parse_args()

    triplea = Path(args.triplea).resolve()
    db_path = Path(args.db).resolve()

    if not triplea.is_dir():
        sys.exit(f"TRIPLEA_DIR not a directory: {triplea}")

    class_dirs = find_class_dirs(triplea, include_tests=args.include_tests)
    if not class_dirs:
        sys.exit(f"no compiled .class roots under {triplea}; "
                 f"run `gradle compileJava` first")
    print(f"scanning {len(class_dirs)} class roots "
          f"(include_tests={args.include_tests})...")
    cls_files = walk_class_files(class_dirs)
    print(f"  {len(cls_files)} .class files")

    java_idx = build_java_source_index(triplea)
    print(f"  java source index: {len(java_idx)} top-level classes")

    # parallel javap
    print(f"running javap with {args.workers} workers...")
    parsed: list = []
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(_javap_one, str(p), is_test): p for p, _, is_test in cls_files}
        done = 0
        for fut in as_completed(futs):
            (_, fqcn, ext, impl, methods, field_deps,
             cp_structs, cp_procs, struct_kind, is_test) = fut.result()
            if fqcn:
                parsed.append((fqcn, ext, impl, methods, field_deps,
                               cp_structs, cp_procs, struct_kind, is_test))
            done += 1
            if done % 500 == 0:
                print(f"    {done}/{len(cls_files)}")
    print(f"  parsed {len(parsed)} classes")

    # write to sqlite — preserve any sibling tables (structs/methods) so
    # `build_called_layered_tables.py` can carry over `is_implemented` flags
    # across re-runs. We only own `entities` and `dependencies` here.
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript(
        """
        DROP TABLE IF EXISTS dependencies;
        DROP TABLE IF EXISTS entities;
        CREATE TABLE entities (
            primary_key   TEXT PRIMARY KEY,
            java_file_path TEXT,
            java_lines     TEXT,
            odin_file_path TEXT,
            layer_number   INTEGER,
            is_fully_implemented_error_free_no_todo_no_stub
                            INTEGER NOT NULL DEFAULT 0,
            included        INTEGER NOT NULL DEFAULT 1,
            actually_called_in_ai_test INTEGER NOT NULL DEFAULT 0,
            is_ui          INTEGER NOT NULL DEFAULT 0,
            -- Struct kind for struct: rows: 'class' | 'abstract_class'
            -- | 'interface' | 'enum'. NULL for proc: rows.
            struct_kind    TEXT,
            -- Abstract / interface methods have no Code: block in javap
            -- output. Used by build_called_layered_tables.py to
            -- synthesize virtual-dispatch edges into concrete overrider
            -- impls so the abstract proc participates in layering.
            -- 0 for struct: rows and concrete methods.
            is_abstract    INTEGER NOT NULL DEFAULT 0,
            -- 1 for entries scanned from build/classes/java/test (the
            -- JaCoCo entry-point harness: Ww2v5JacocoRun, SnapshotHarness,
            -- GameTestUtils, ...). These are NOT porting targets but
            -- are layered so the call-chain from harness top-of-stack
            -- down through the engine is visible for drill-down.
            is_test_harness INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE dependencies (
            primary_key   TEXT,
            depends_on_key TEXT,
            -- 'static'   = static call edge (invokestatic, invokespecial, lambda)
            -- 'virtual'  = virtual-dispatch edge (invokevirtual to a non-final
            --             method or invokeinterface), captured at the
            --             declared receiver type. Both this row AND the
            --             synthesized 'override' rows below participate in
            --             layering for callers, but only the synthesized
            --             row contributes the actual transitive dep on the
            --             implementation.
            -- 'override' = synthesized edge from an abstract / interface
            --             method to a concrete overrider. Generated by
            --             build_called_layered_tables.py.
            -- 'extends'  = struct->struct subclass / implements edge.
            -- 'field'    = struct->struct field type edge.
            -- 'cp_ref'   = struct->{struct,proc} constant-pool reference
            --             (Methodref / MethodHandle attributed at class
            --             scope; covers method-reference lambdas).
            edge_kind     TEXT NOT NULL DEFAULT 'static',
            PRIMARY KEY (primary_key, depends_on_key, edge_kind)
        );
        CREATE INDEX idx_dep_pk ON dependencies(primary_key);
        CREATE INDEX idx_dep_target ON dependencies(depends_on_key);
        CREATE INDEX idx_dep_kind ON dependencies(edge_kind);
        """
    )

    # ---- compute UI taint set ----
    # Step 1: a class is directly tainted if any of its ext/impl parents is
    # a Swing/AWT widget type (excluding Point/Color value types), OR if
    # any of its field types or any of its method-signature types (params
    # / return / generic args harvested from javap source-form lines) is a
    # UI boundary type. The signature-level seed catches engine classes
    # like ClientModel that never extend a Swing widget but thread
    # `java.awt.Component` / `java.awt.Frame` / `org.triplea.swing.*`
    # through their public API — those classes are real Swing client
    # code and must not enter the structs table.
    # Step 2: propagate transitively across TripleA-internal extends/implements
    # so a subclass of a tainted TripleA class is itself tainted.
    triplea_parents: dict[str, list[str]] = {}
    ui_tainted: set[str] = set()
    for fqcn, ext, impl, methods, field_deps, cp_structs, cp_procs, struct_kind, is_test in parsed:
        parents = ext + impl
        triplea_parents[fqcn] = [p for p in parents if not _excluded(p)]
        # the `org.triplea.swing.*` helper package is itself UI by
        # definition — taint regardless of ancestry, in case a helper
        # there doesn't directly extend a Swing widget.
        if fqcn.startswith(UI_TRIPLEA_PREFIXES):
            ui_tainted.add(fqcn)
            continue
        if any(_is_ui_jdk(p) for p in parents):
            ui_tainted.add(fqcn)
            continue
        # field-type seed
        if any(_is_ui_taint_source(t) for t in field_deps):
            ui_tainted.add(fqcn)
            continue
        # method-signature seed: scan every per-method struct dep, which
        # already includes the method's descriptor classes plus any
        # generic-erased classes harvested from the javap source-form
        # method header.
        sig_hit = False
        for m in methods:
            if any(_is_ui_taint_source(t) for t in m["deps_struct"]):
                sig_hit = True
                break
        if sig_hit:
            ui_tainted.add(fqcn)
    # transitive closure (TripleA-internal subclassing)
    changed = True
    while changed:
        changed = False
        for fqcn, parents in triplea_parents.items():
            if fqcn in ui_tainted:
                continue
            if any(p in ui_tainted for p in parents):
                ui_tainted.add(fqcn)
                changed = True
    print(f"  UI-tainted classes (Swing/AWT ancestry): {len(ui_tainted)}")

    entity_rows: list[tuple] = []
    dep_rows: set[tuple[str, str, str]] = set()

    for fqcn, ext, impl, methods, field_deps, cp_structs, cp_procs, struct_kind, is_test in parsed:
        # struct row
        top = fqcn.split("$", 1)[0]
        java_path = java_idx.get(top, "")
        is_ui = 1 if fqcn in ui_tainted else 0
        is_test_harness = 1 if is_test else 0
        entity_rows.append((
            f"struct:{fqcn}", java_path, "", "", None, 0, 1, 0, is_ui,
            struct_kind, 0, is_test_harness,
        ))
        # struct-level dep edges
        for parent in ext + impl:
            if not _excluded(parent):
                dep_rows.add((f"struct:{fqcn}", f"struct:{parent}", "extends"))
        # field-type dep edges (including generic type-arguments lost to
        # bytecode erasure but recovered from javap's source-form lines).
        for ft in field_deps:
            if not _excluded(ft) and ft != fqcn:
                dep_rows.add((f"struct:{fqcn}", f"struct:{ft}", "field"))
        # constant-pool method-reference targets (`Foo::new`, `Foo::bar`)
        # — attributed at class scope since javap doesn't tell us which
        # invokedynamic site uses each pool entry.
        for ft in cp_structs:
            if not _excluded(ft) and ft != fqcn:
                dep_rows.add((f"struct:{fqcn}", f"struct:{ft}", "cp_ref"))
        for pk in cp_procs:
            dep_rows.add((f"struct:{fqcn}", pk, "cp_ref"))
        # method rows + their deps
        for m in methods:
            args_str = ",".join(m["args_java"])
            mkey = f"proc:{fqcn}#{m['name']}({args_str})"
            entity_rows.append((
                mkey, java_path, "", "", None, 0, 1, 0, is_ui,
                None, 1 if m.get("is_abstract") else 0, is_test_harness,
            ))
            # owner edge (struct membership)
            dep_rows.add((mkey, f"struct:{fqcn}", "static"))
            for s in m["deps_struct"]:
                if not _excluded(s):
                    dep_rows.add((mkey, f"struct:{s}", "static"))
            for p in m["deps_proc"]:
                dep_rows.add((mkey, p, "static"))

    cur.executemany(
        "INSERT OR IGNORE INTO entities VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
        entity_rows,
    )
    cur.executemany(
        "INSERT OR IGNORE INTO dependencies VALUES (?,?,?)",
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
