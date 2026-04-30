#!/usr/bin/env python3
"""auto_implement_trivial_methods.py
================================================================================
Auto-mark `methods.is_implemented = 1` for two categories of rows that have
no Odin work to do:

  1. Abstract Java interface methods. The Java declaration has no body
     (`ReturnType method(args);`) and the owner is a `public interface ...`
     without the `default` or `static` modifier. Odin dispatches through
     concrete types, so the abstract proc would never be called and porting
     a body is impossible. We mark these implemented so the orchestrator
     doesn't re-dispatch them forever.

  2. Methods that mention Swing/AWT/IO JDK boundary types in their argument
     list. Per llm-instructions §6, these are JaCoCo-filter regressions —
     UI/serialization code paths the AI snapshot harness never executes.
     Their bodies are dead code in the snapshot, so we mark implemented and
     move on.

This script reads `port.sqlite` directly (no bootstrap re-run required) and
is also wired into `bootstrap.sh` so future bootstraps stay consistent.

Usage:
    python3 scripts/auto_implement_trivial_methods.py [--db PATH] [--dry-run]

Env vars (used if flags omitted):
    PORT_DB     sqlite database (default: ./port.sqlite)
================================================================================
"""

from __future__ import annotations

import argparse
import os
import re
import sqlite3
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# UI / IO blocker patterns
# ---------------------------------------------------------------------------

# Argument-type substrings that mark a method as a UI/AWT-event lambda and
# therefore unreachable in the AI snapshot harness. We treat the full
# method_key as a string and check for substring matches; the method_key
# contains fully-qualified Java type names like
# `proc:Foo#bar(javax.swing.JCheckBox,java.awt.event.ActionEvent)`.
#
# This list is intentionally CONSERVATIVE:
# - `java.awt.Point` / `java.awt.Color` are pure value types used by the
#   engine — DO NOT treat them as UI. The patterns below avoid `java.awt.`
#   as a bare prefix.
# - `java.io.Serializable` is a marker interface used pervasively
#   (`GameProperties.set` lambdas); excluded.
# - `java.io.{Input,Output}Stream` and friends are NOT auto-marked here —
#   GameParser, GameDataManager, XmlMapper genuinely consume streams to
#   load the map XML / saved games during snapshot setup. Those need
#   case-by-case orchestrator analysis, not a blanket auto-implement.
# - NIO socket plumbing (`java.nio.channels.*`, `java.nio.ByteBuffer`,
#   `java.util.concurrent.BlockingQueue`) is wired up at construction time
#   but never exercises real I/O — orchestrator provisions opaque marker
#   shims for these per resume-prompt.md.
UI_IO_BLOCKED_TYPE_SUBSTRINGS = (
    "javax.swing.",
    "java.awt.event.",
    "java.awt.Component",
    "java.awt.Frame",
    "java.awt.Window",
    "java.awt.Dialog",
    "java.awt.Container",
    "java.awt.Graphics",
    "java.awt.Image",
    "org.triplea.swing.",
)

# A small explicit allowlist for UI/IO-adjacent lambdas that the user has
# specifically classified as JaCoCo-filter regressions. Add entries by full
# method_key; matched as substrings against the unimplemented method_key.
# Currently covers only the GameProperties property-editor stream lambdas
# (read/writeEditableProperties): the AI snapshot harness never serialises
# the editable-properties list to a stream, but the call chain leading to
# them does run during property iteration so JaCoCo marks them executed.
EXPLICIT_BLOCKED_METHOD_SUBSTRINGS = (
    "GameProperties#lambda$readEditableProperties$",
    "GameProperties#lambda$writeEditableProperties$",
)


# Tokens that, if they appear in a method's Java body or unstripped
# return type, mark the method as UI/Swing dead code in the snapshot
# harness. Substring-matched against the textual method body.
#
# These complement the arg-type check above. Examples caught:
#   - `getSystemLookAndFeels()` returns Collection<UIManager.LookAndFeelInfo>
#     and its body is `return List.of(UIManager.getInstalledLookAndFeels())`;
#     no javax.swing types appear in the args, but the body and return
#     type both reference UIManager.
#   - Any method that calls `JOptionPane.showMessageDialog(...)` from
#     a `*Component#someMethod` reachable only through UI listeners.
#
# Conservative — `Color`/`Point` are still allowed as value types, so we
# look for class names that only make sense in Swing/AWT widget context.
UI_BODY_TOKEN_SUBSTRINGS = (
    "UIManager.",
    "UIManager$",
    "JOptionPane.",
    "JFrame",
    "JDialog",
    "JPanel",
    "JComponent",
    "SwingUtilities.",
    "LookAndFeelInfo",
    "javax.swing.",
)


# Body tokens that mark a method as crypto / network-auth dead code in the
# AI snapshot harness. The harness loads a saved game snapshot from disk
# and replays it deterministically — it never opens sockets, never logs
# in to a lobby, never hashes credentials. Any method whose body invokes
# the JCE / JCA / SecureRandom / Base64 / network-auth APIs is therefore
# unreachable in the snapshot and safe to auto-mark.
#
# Conservative — these tokens only appear in genuine crypto/auth bodies.
# `MessageDigest` and `Mac` are dotted-class references, not common
# identifiers; `Socket` / `ServerSocket` / `DatagramSocket` are likewise
# specific to network plumbing.
NETWORK_AUTH_BODY_TOKEN_SUBSTRINGS = (
    "Mac.getInstance",
    "MessageDigest.getInstance",
    "Cipher.getInstance",
    "SecretKeyFactory",
    "KeyFactory.getInstance",
    "PBEKeySpec",
    "SecureRandom",
    "Base64.getEncoder",
    "Base64.getDecoder",
    "javax.crypto.",
    "java.security.spec.",
    "new Socket(",
    "new ServerSocket(",
    "new DatagramSocket(",
    "java.net.Socket",
    "java.net.ServerSocket",
)


# Argument-type substrings that mark a method as crypto/network-auth dead
# code. Matched against the parenthesised arg list only (so e.g. a value
# field of type `byte[]` passed unrelated to crypto isn't caught).
NETWORK_AUTH_ARG_TYPE_SUBSTRINGS = (
    "javax.crypto.",
    "java.security.Key",
    "java.security.SecureRandom",
    "java.security.MessageDigest",
    "java.security.spec.",
    "java.net.Socket",
    "java.net.ServerSocket",
    "java.net.DatagramSocket",
)


def _arg_list(method_key: str) -> str:
    """Extract the parenthesised arg-type list from a method_key, or `''`."""
    lparen = method_key.find("(")
    rparen = method_key.rfind(")")
    if lparen < 0 or rparen <= lparen:
        return ""
    return method_key[lparen + 1:rparen]


def _hits_ui_io(method_key: str) -> str | None:
    """Return the matching UI/IO substring if `method_key` mentions one,
    else None. Inspects both the parenthesised arg list (for type-based
    matches) and the full method_key (for explicit-allowlist matches)."""
    for needle in EXPLICIT_BLOCKED_METHOD_SUBSTRINGS:
        if needle in method_key:
            return needle
    args = _arg_list(method_key)
    if not args:
        return None
    for needle in UI_IO_BLOCKED_TYPE_SUBSTRINGS:
        if needle in args:
            return needle
    for needle in NETWORK_AUTH_ARG_TYPE_SUBSTRINGS:
        if needle in args:
            return needle
    return None


def _hits_network_auth_body(java_text: str, method_name: str) -> str | None:
    """Return the matching crypto/network token if the method body has one."""
    body = _method_body_text(java_text, method_name)
    if body is None:
        return None
    for tok in NETWORK_AUTH_BODY_TOKEN_SUBSTRINGS:
        if tok in body:
            return tok
    return None


def _split_method_name(method_key: str) -> str:
    """`proc:Foo#bar(args)` -> `bar`."""
    body = method_key[len("proc:"):]
    h = body.find("#")
    if h < 0:
        return ""
    rest = body[h + 1:]
    p = rest.find("(")
    return rest[:p] if p >= 0 else rest


def _method_body_text(java_text: str, method_name: str) -> str | None:
    """Return the Java source body of the named method, including the
    return-type/signature line preceding `{`, up to the matching `}`.
    Returns None if not found. Constructors map to method_name == '<init>'
    which doesn't appear literally in source — caller should skip those.
    """
    if not java_text or not method_name or method_name.startswith("<"):
        return None
    if method_name.startswith("lambda$"):
        # Lambdas are synthesised; their body lives inside another
        # method. We don't extract them here.
        return None
    # Find lines that look like `name(` declarations, then walk braces.
    lines = java_text.splitlines()
    name_paren = method_name + "("
    n = len(lines)
    for i, line in enumerate(lines):
        if name_paren not in line:
            continue
        # Skip likely call sites (method invocations) — heuristic: a
        # declaration begins with whitespace + modifiers/annotations and
        # is preceded by a return-type token. The simplest filter: the
        # line containing `name(` must also have a leading whitespace +
        # NOT start with `.` and the position of `name(` must come after
        # a non-identifier char (space, '<', etc.) so e.g. `getName(...)`
        # is preferred over `obj.getName(...)`.
        idx = line.index(name_paren)
        if idx > 0 and (line[idx - 1].isalnum() or line[idx - 1] == "_"):
            continue
        # Walk forward to find the `{` that opens the body.
        buf = line
        j = i
        while "{" not in buf and ";" not in buf and j + 1 < n:
            j += 1
            buf += "\n" + lines[j]
        if "{" not in buf:
            # Body-less declaration (abstract / interface): no body.
            continue
        # Brace-balance walk from after the first `{` to its matching `}`.
        body_chars: list[str] = [buf]
        depth = buf.count("{") - buf.count("}")
        k = j + 1
        while depth > 0 and k < n:
            body_chars.append(lines[k])
            depth += lines[k].count("{") - lines[k].count("}")
            k += 1
        return "\n".join(body_chars)
    return None


def _hits_ui_body(java_text: str, method_name: str) -> str | None:
    """Return the matching Swing/AWT token if the method's body or
    surrounding signature contains it; else None."""
    body = _method_body_text(java_text, method_name)
    if body is None:
        return None
    for tok in UI_BODY_TOKEN_SUBSTRINGS:
        if tok in body:
            return tok
    return None


# ---------------------------------------------------------------------------
# Abstract-interface-method detection
# ---------------------------------------------------------------------------

def _split_owner(method_key: str) -> tuple[str, str]:
    """`proc:com.foo.Bar$Baz#meth(args)` -> (`com.foo.Bar$Baz`, `meth`)."""
    body = method_key[len("proc:"):]
    hash_idx = body.find("#")
    if hash_idx < 0:
        return body, ""
    owner = body[:hash_idx]
    rest = body[hash_idx + 1:]
    paren = rest.find("(")
    name = rest[:paren] if paren >= 0 else rest
    return owner, name


# Match `(public|private|...) interface NAME...` for either the top-level
# class or any inner type. We don't track which inner the method belongs to
# beyond the simple name — the simple name is unique within a Java source
# file by the language rules.
_INTERFACE_DECL_RE = re.compile(
    r"\b(?:public\s+|protected\s+|private\s+|static\s+|abstract\s+|sealed\s+|non-sealed\s+)*"
    r"interface\s+([A-Za-z_][\w]*)\b"
)

# A method declaration line. Looks for a name + open-paren on the same
# line; the closing `;` (no body) is what flags it as abstract.
_METHOD_LINE_RE = re.compile(
    r"^\s*"
    r"(?P<modifiers>(?:[\w@]+\s+)*)"          # any leading modifiers/annotations
    r"(?:<[^>]+>\s+)?"                         # optional generic prefix `<T>`
    r"[\w\.\$<>\[\],\s\?]+?\s+"               # return type (loose)
    r"(?P<name>[A-Za-z_][\w]*)\s*"            # method name
    r"\("
)


def _interface_simple_names(java_text: str) -> set[str]:
    """All simple type-names declared as `interface` in the Java source."""
    return {m.group(1) for m in _INTERFACE_DECL_RE.finditer(java_text)}


def _is_abstract_interface_method(
    java_text: str, owner_fqcn: str, method_name: str
) -> bool:
    """Return True iff a declaration of `method_name(...)` in `java_text`
    is body-less (ends with `;` before any `{`) AND lacks `default`/`static`,
    AND either:
      - the declaration carries the explicit `abstract` modifier (abstract
        method on an abstract class), or
      - the owner type is declared as an `interface` in the file (interface
        methods are implicitly abstract when not `default`/`static`).

    The owner-fqcn check on the interface side prevents misclassifying a
    same-named method on a sibling concrete class declared in the same
    file (rare in TripleA but worth the guard).
    """
    if method_name in ("<init>", "<clinit>"):
        return False

    simple = owner_fqcn.split(".")[-1].split("$")[-1]
    owner_is_interface = simple in _interface_simple_names(java_text)

    lines = java_text.splitlines()
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        m = _METHOD_LINE_RE.match(line)
        if m and m.group("name") == method_name:
            # Stitch together the declaration until we hit `;` or `{`.
            buf = line
            j = i
            while ";" not in buf and "{" not in buf and j + 1 < n:
                j += 1
                buf += " " + lines[j]
            mod_tokens = m.group("modifiers").split()
            if "default" in mod_tokens or "static" in mod_tokens:
                i = j + 1
                continue
            semi = buf.find(";")
            brace = buf.find("{")
            body_less = semi >= 0 and (brace < 0 or semi < brace)
            if not body_less:
                i = j + 1
                continue
            # Body-less declaration. Accept it as abstract iff either
            # the modifier set says `abstract` or the owner is an
            # interface.
            if "abstract" in mod_tokens or owner_is_interface:
                return True
            i = j + 1
            continue
        i += 1
    return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.environ.get("PORT_DB", "port.sqlite"))
    ap.add_argument("--dry-run", action="store_true",
                    help="report counts without modifying the database")
    args = ap.parse_args()

    db_path = Path(args.db).resolve()
    if not db_path.exists():
        sys.exit(f"missing database: {db_path}")

    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()

    rows = cur.execute(
        "SELECT method_key, java_file_path FROM methods "
        "WHERE is_implemented = 0"
    ).fetchall()
    print(f"scanning {len(rows)} unimplemented methods...")

    # Cache Java sources to avoid re-reading the same file thousands of times.
    src_cache: dict[str, str] = {}

    def read_src(path: str) -> str:
        if not path:
            return ""
        if path in src_cache:
            return src_cache[path]
        try:
            text = Path(path).read_text(encoding="utf-8", errors="replace")
        except OSError:
            text = ""
        src_cache[path] = text
        return text

    abstract_hits: list[str] = []
    ui_io_hits: list[tuple[str, str]] = []  # (method_key, matched_substring)

    for method_key, java_path in rows:
        # UI / IO check first — cheap string match on the method_key.
        needle = _hits_ui_io(method_key)
        if needle is not None:
            ui_io_hits.append((method_key, needle))
            continue

        # Owner / method name + Java source needed for both remaining
        # checks (abstract-method and body-level UI scan).
        owner_fqcn, method_name = _split_owner(method_key)
        if not method_name:
            continue
        text = read_src(java_path)
        if not text:
            continue

        # Body-level UI token check: catches Swing/AWT methods whose
        # arg list looks innocent but whose body or return type calls
        # `UIManager`, `JOptionPane`, etc. Skips lambdas/<init>/<clinit>
        # because their bodies aren't extractable as standalone methods.
        body_needle = _hits_ui_body(text, method_name)
        if body_needle is not None:
            ui_io_hits.append((method_key, "body:" + body_needle))
            continue

        # Crypto / network-auth body-token check: catches methods whose
        # bodies invoke JCE/JCA/SecureRandom/Base64/Socket APIs that the
        # AI snapshot harness never executes.
        crypto_needle = _hits_network_auth_body(text, method_name)
        if crypto_needle is not None:
            ui_io_hits.append((method_key, "crypto:" + crypto_needle))
            continue

        # Abstract-method check (interface or abstract-class).
        if method_name.startswith("lambda$"):
            continue
        if _is_abstract_interface_method(text, owner_fqcn, method_name):
            abstract_hits.append(method_key)

    print(f"\nabstract interface methods: {len(abstract_hits)}")
    for k in abstract_hits[:20]:
        print(f"  {k}")
    if len(abstract_hits) > 20:
        print(f"  ... {len(abstract_hits) - 20} more")

    print(f"\nUI/IO boundary methods: {len(ui_io_hits)}")
    by_needle: dict[str, int] = {}
    for _, needle in ui_io_hits:
        by_needle[needle] = by_needle.get(needle, 0) + 1
    for needle, count in sorted(by_needle.items(), key=lambda x: -x[1]):
        print(f"  {count:>4}  {needle}")
    for k, _ in ui_io_hits[:20]:
        print(f"  {k}")
    if len(ui_io_hits) > 20:
        print(f"  ... {len(ui_io_hits) - 20} more")

    if args.dry_run:
        print("\n--dry-run: no changes written")
        conn.close()
        return

    keys_to_mark = [(k,) for k in abstract_hits] + [(k,) for k, _ in ui_io_hits]
    if not keys_to_mark:
        print("\nnothing to do")
        conn.close()
        return

    n = cur.executemany(
        "UPDATE methods SET is_implemented = 1 WHERE method_key = ?",
        keys_to_mark,
    ).rowcount
    conn.commit()
    print(f"\nmarked {n} methods is_implemented = 1")

    impl_total, total = cur.execute(
        "SELECT SUM(CASE WHEN is_implemented=1 THEN 1 ELSE 0 END), COUNT(*) "
        "FROM methods"
    ).fetchone()
    print(f"methods now: {impl_total}/{total}")
    conn.close()


if __name__ == "__main__":
    main()
