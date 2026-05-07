#!/usr/bin/env python3
"""Deterministic "what should I do next?" picker for the test-status drill-down.

The picker turns the contents of `port.sqlite` (`test_status`,
`methods`, `dependencies`) into a single deterministic next action.
Algorithm (matches the user-spec):

    1. Find every proc currently marked **red** in `test_status`.
    2. Sort the red procs by `methods.method_layer` ASC (then key ASC),
       so the **deepest red** wins.  "Deepest" = lowest layer number
       in the call graph; this is the proc closest to the actual bug.
    3. Look at the chosen red proc's direct dependencies (the rows
       `dependencies.primary_key = <red>` with a call-graph
       `edge_kind` of static / virtual / override) and join them to
       `test_status` (defaulting to **yellow** when not recorded).
    4. Decide one of three task kinds:
         - **TEST_DEP**: the red has at least one yellow dependency.
           Yellow means UNKNOWN, not "the bug."  The next move is
           to *classify every yellow sibling first* via a
           FIXTURE-DRIVEN GOLDEN TEST (see llm-instructions.md
           §"How to classify a yellow proc"): either prove coverage
           by an existing passing snapshot (instrument-and-rerun),
           or write a targeted test that loads a real before.json,
           calls the proc with the parent's actual call-site
           arguments, and value-compares outputs to a golden
           derived from Java.  Crash-only / non-nil / non-empty /
           trivial-input asserts are FORBIDDEN as proof of green —
           if you cannot build a real golden test, leave the proc
           yellow.  Only after every yellow sibling has been
           classified does the picker drill into a confirmed red
           (which will surface automatically as the new deepest red
           on the next call) — or pop up to INVESTIGATE_PROC if
           every sibling came back green.  The picker lists yellow
           siblings deepest-first purely as a stable visit order;
           the order does not imply that the deepest yellow is the
           bug.
         - **INVESTIGATE_PROC**: every dep is green (or there are
           no recorded deps).  The bug is inside this proc itself —
           re-read the original Java, diff against the Odin port.
         - **NO_REDS**: the `test_status` table has no red entries
           (either nothing has been drilled into yet, or every
           visited node is currently green).  The picker suggests a
           seed action.

Output:
    $ python3 scripts/next_task.py            # human-readable report
    $ python3 scripts/next_task.py --json     # machine-readable JSON
    $ python3 scripts/next_task.py --top 3    # top-N candidate reds

The picker is intentionally pure-read: it never mutates the database.
Use `scripts/mark_test_status.py` to flip a status after acting.
"""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_DB = os.path.join(os.path.dirname(_HERE), "port.sqlite")

# Edge kinds that count as "this proc calls that proc" for picker
# purposes.  `extends` / `field` / `cp_ref` are class-level edges and
# don't represent a runtime invocation.
_CALL_EDGE_KINDS = ("static", "virtual", "override")


def _open_db() -> sqlite3.Connection:
    conn = sqlite3.connect(_DB)
    conn.row_factory = sqlite3.Row
    return conn


def _ensure_test_status(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS test_status (
            entity_key TEXT PRIMARY KEY,
            status     TEXT NOT NULL DEFAULT 'yellow'
                       CHECK(status IN ('green','red','yellow')),
            note       TEXT,
            updated_at TEXT NOT NULL
        )
        """
    )


def _fetch_reds(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    """All red procs joined to method metadata, deepest first.

    LEFT JOIN against `methods` so that a red `test_status` entry
    whose key doesn't match any method (e.g. typo, signature drift)
    still surfaces — it'll have NULL layer / paths and sort last.
    """
    return list(
        conn.execute(
            """
            SELECT  ts.entity_key       AS key,
                    ts.note             AS note,
                    ts.updated_at       AS updated_at,
                    m.method_layer      AS layer,
                    m.java_file_path    AS java_path,
                    m.java_lines        AS java_lines,
                    m.odin_file_path    AS odin_path
            FROM    test_status ts
            LEFT JOIN methods m ON m.method_key = ts.entity_key
            WHERE   ts.status = 'red'
            ORDER BY
                    CASE WHEN m.method_layer IS NULL THEN 1 ELSE 0 END,
                    m.method_layer ASC,
                    ts.entity_key ASC
            """
        )
    )


def _resolve_dep_key(conn: sqlite3.Connection, dep_key: str) -> str | None:
    """Return a `methods.method_key` matching `dep_key` directly, or its
    nearest ancestor that does have a methods row.

    Java declares some methods on a superclass (e.g. `AbstractBattle#getBattleType()`)
    while the dependency scanner records the call under the receiver's
    static type at the call site (e.g. `MustFightBattle#getBattleType()`).
    The methods table only has a row for the declarer, so a naive
    `JOIN methods ON method_key = depends_on_key` silently drops the
    dep. We walk the `extends` chain on the receiver class and try
    `<ancestor>#<sig>` until a methods row hits.

    Returns None if no resolution exists; the caller treats that as
    "not a real method dep" and skips it.
    """
    cur = conn.cursor()
    if cur.execute(
        "SELECT 1 FROM methods WHERE method_key = ? LIMIT 1", (dep_key,)
    ).fetchone():
        return dep_key
    # Parse "proc:<FQCN>#<sig>" — only `proc:` keys are method calls.
    if not dep_key.startswith("proc:") or "#" not in dep_key:
        return None
    fqcn_sig = dep_key[len("proc:"):]
    fqcn, sig = fqcn_sig.split("#", 1)
    visited: set[str] = set()
    stack = [f"struct:{fqcn}"]
    while stack:
        struct_key = stack.pop()
        if struct_key in visited:
            continue
        visited.add(struct_key)
        # Materialise the row list before issuing the inner check
        # query — using a single shared cursor for both iter and check
        # would reset the outer iterator on every inner execute().
        parents = [
            row[0]
            for row in conn.execute(
                "SELECT depends_on_key FROM dependencies "
                "WHERE primary_key = ? AND edge_kind = 'extends'",
                (struct_key,),
            )
        ]
        for parent_struct in parents:
            if not parent_struct.startswith("struct:"):
                continue
            parent_fqcn = parent_struct[len("struct:"):]
            candidate = f"proc:{parent_fqcn}#{sig}"
            if conn.execute(
                "SELECT 1 FROM methods WHERE method_key = ? LIMIT 1", (candidate,)
            ).fetchone():
                return candidate
            stack.append(parent_struct)
    return None


def _fetch_children(conn: sqlite3.Connection, parent_key: str) -> list[sqlite3.Row]:
    """Direct call-graph callees of `parent_key`, with current status.

    For each raw `dependencies.depends_on_key` we first try to find a
    direct `methods` row, then fall back to walking the receiver's
    `extends` chain to locate the declaring superclass — this handles
    the common case where Java declares a method on an abstract
    parent (AbstractBattle#getBattleType) but the dep was scanned
    against the receiver type (MustFightBattle#getBattleType).
    Without this resolution the picker silently drops yellow deps and
    falsely reports INVESTIGATE_PROC on the parent red.

    `test_status` is keyed by the resolved (canonical) key — so a
    single test_status('AbstractBattle#getBattleType()' -> green) will
    correctly satisfy any descendant call site.

    Edges of the same parent->callee with multiple `edge_kind`s
    (e.g. both `virtual` and `override`) collapse to a single row;
    edge_kinds is GROUP_CONCATed for visibility.
    """
    cur = conn.cursor()
    raw = list(
        cur.execute(
            f"""
            SELECT  d.depends_on_key   AS dep_key,
                    GROUP_CONCAT(DISTINCT d.edge_kind) AS edge_kinds
            FROM    dependencies d
            WHERE   d.primary_key = ?
              AND   d.edge_kind IN ({",".join("?" * len(_CALL_EDGE_KINDS))})
            GROUP BY d.depends_on_key
            """,
            (parent_key, *_CALL_EDGE_KINDS),
        )
    )

    rows: list[dict] = []
    seen: set[str] = set()
    for r in raw:
        resolved = _resolve_dep_key(conn, r["dep_key"])
        if resolved is None:
            continue  # struct/cp_ref leak or unknown method — skip
        if resolved in seen:
            continue
        seen.add(resolved)
        meta = cur.execute(
            "SELECT method_layer, java_file_path, java_lines, odin_file_path "
            "FROM methods WHERE method_key = ?",
            (resolved,),
        ).fetchone()
        ts = cur.execute(
            "SELECT status, note FROM test_status WHERE entity_key = ?",
            (resolved,),
        ).fetchone()
        rows.append(
            {
                "key": resolved,
                "edge_kinds": r["edge_kinds"],
                "layer": meta["method_layer"] if meta else None,
                "java_path": meta["java_file_path"] if meta else None,
                "java_lines": meta["java_lines"] if meta else None,
                "odin_path": meta["odin_file_path"] if meta else None,
                "status": (ts["status"] if ts else "yellow"),
                "note": (ts["note"] if ts else None),
            }
        )

    # Sort: yellow first (we care most about untested deps),
    # then red, then green; within each, deepest layer first.
    order = {"yellow": 0, "red": 1, "green": 2}
    rows.sort(
        key=lambda r: (
            order.get(r["status"], 3),
            r["layer"] if r["layer"] is not None else 1 << 30,
            r["key"],
        )
    )
    return rows


def _fetch_summary(conn: sqlite3.Connection) -> dict:
    counts = {"green": 0, "red": 0, "yellow": 0}
    for status, n in conn.execute(
        "SELECT status, COUNT(*) FROM test_status GROUP BY status"
    ):
        counts[status] = n
    counts["recorded"] = sum(counts.values())
    return counts


def pick_next(conn: sqlite3.Connection) -> dict:
    """Return a JSON-shaped task description for the next action.

    Shape (always present): {"kind": str, "summary": dict}.
    Per kind:
      TEST_DEP:           red, deepest_yellow_children[], all_children[]
      INVESTIGATE_PROC:   red, all_children[]
      NO_REDS:            (no extra fields)
    """
    summary = _fetch_summary(conn)
    reds = _fetch_reds(conn)

    if not reds:
        return {
            "kind": "NO_REDS",
            "summary": summary,
            "hint": (
                "No red procs in test_status. Either nothing has been "
                "drilled into yet, or every visited node is currently "
                "green. Mark the failing snapshot's top-of-stack proc "
                "red with `scripts/mark_test_status.py <KEY> red --note ...` "
                "to seed the next iteration."
            ),
        }

    chosen = reds[0]
    children = _fetch_children(conn, chosen["key"])
    yellows = [c for c in children if c["status"] == "yellow"]

    chosen_payload = {
        "key": chosen["key"],
        "layer": chosen["layer"],
        "java_path": chosen["java_path"],
        "java_lines": chosen["java_lines"],
        "odin_path": chosen["odin_path"],
        "note": chosen["note"],
        "updated_at": chosen["updated_at"],
    }
    children_payload = [
        {
            "key": c["key"],
            "layer": c["layer"],
            "status": c["status"],
            "edge_kinds": c["edge_kinds"],
            "java_path": c["java_path"],
            "java_lines": c["java_lines"],
            "odin_path": c["odin_path"],
            "note": c["note"],
        }
        for c in children
    ]

    if yellows:
        # Deepest yellow first — that's the next dep to test.
        deepest_layer = min(
            (y["layer"] for y in yellows if y["layer"] is not None),
            default=None,
        )
        deepest = [
            y for y in yellows
            if (y["layer"] == deepest_layer) or (y["layer"] is None and deepest_layer is None)
        ]
        return {
            "kind": "TEST_DEP",
            "summary": summary,
            "red": chosen_payload,
            "deepest_yellow_children": [
                {
                    "key": y["key"],
                    "layer": y["layer"],
                    "edge_kinds": y["edge_kinds"],
                    "java_path": y["java_path"],
                    "java_lines": y["java_lines"],
                    "odin_path": y["odin_path"],
                }
                for y in deepest
            ],
            "all_children": children_payload,
        }

    # No yellow deps left.  If there's still a red dep, the picker's
    # ordering invariant is intact — that red dep will already have
    # been chosen as `reds[0]` since it's deeper than any non-leaf
    # parent.  So at this point all deps are green (or there are
    # none): the bug is inside the chosen proc itself.
    return {
        "kind": "INVESTIGATE_PROC",
        "summary": summary,
        "red": chosen_payload,
        "all_children": children_payload,
    }


# ---------- Human-readable formatter ----------------------------------------


def _fmt_path(path: str | None, lines: str | None = None) -> str:
    if not path:
        return "(no path recorded)"
    if lines:
        return f"{path}:{lines}"
    return path


def _format(task: dict, top: int = 0, conn: sqlite3.Connection | None = None) -> str:
    out: list[str] = []
    s = task["summary"]
    out.append(
        f"test_status: green={s.get('green',0)}  "
        f"red={s.get('red',0)}  yellow={s.get('yellow',0)}  "
        f"(recorded={s.get('recorded',0)})"
    )
    out.append("")

    kind = task["kind"]
    if kind == "NO_REDS":
        out.append("=== NEXT TASK: NO_REDS ===")
        out.append(task["hint"])
        return "\n".join(out)

    red = task["red"]
    layer_str = "?" if red["layer"] is None else str(red["layer"])
    out.append(f"=== NEXT TASK: {kind} ===")
    out.append(f"Red proc:  {red['key']}")
    out.append(f"  layer:   {layer_str}")
    if red["note"]:
        out.append(f"  note:    {red['note']}")
    out.append(f"  java:    {_fmt_path(red['java_path'], red['java_lines'])}")
    out.append(f"  odin:    {_fmt_path(red['odin_path'])}")
    out.append("")

    if kind == "TEST_DEP":
        n_yellow = sum(1 for c in task['all_children'] if c['status'] == 'yellow')
        deepest = task["deepest_yellow_children"]
        out.append(
            f"This red has {n_yellow} yellow (unclassified) "
            f"dependency/dependencies."
        )
        out.append(
            "  Yellow means UNKNOWN, not \"the bug.\"  You MUST classify"
        )
        out.append(
            "  EVERY yellow sibling via a FIXTURE-DRIVEN GOLDEN TEST"
        )
        out.append(
            "  (see llm-instructions.md §\"How to classify a yellow proc\")"
        )
        out.append(
            "  before drilling.  Only drill into a sibling once it is confirmed red."
        )
        out.append("")
        out.append("Suggested visit order (deepest-yellow first, for stability):")
        for c in deepest:
            cl = "?" if c["layer"] is None else str(c["layer"])
            out.append(f"  - layer={cl:<3}  {c['key']}")
            out.append(f"        edge:    {c['edge_kinds']}")
            out.append(f"        java:    {_fmt_path(c['java_path'], c['java_lines'])}")
            out.append(f"        odin:    {_fmt_path(c['odin_path'])}")
        out.append("")
        out.append("Action (per yellow sibling) — fixture-driven golden test:")
        out.append(
            "  1. Try coverage first: instrument the dep with a temporary"
        )
        out.append(
            "     eprintln, re-run the full snapshot suite, and check whether"
        )
        out.append(
            "     a passing snapshot fires it.  If yes, mark green with note"
        )
        out.append(
            "     `covered by snapshot <id>` and remove the instrumentation."
        )
        out.append(
            "  2. Otherwise write a targeted test that:"
        )
        out.append(
            "       a. Loads a real before.json via tc.load_game_state."
        )
        out.append(
            "       b. Calls the dep with the parent's actual call-site"
        )
        out.append(
            "          arguments (capture via temporary trace in the parent)."
        )
        out.append(
            "       c. VALUE-COMPARES outputs / observable side effects to a"
        )
        out.append(
            "          golden derived from the Java method body."
        )
        out.append(
            "  3. FORBIDDEN as proof of green: \"no crash\", `!= nil`, "
            "`len > 0`,"
        )
        out.append(
            "     headless / nil-channel / empty-list early-return paths,"
        )
        out.append(
            "     synthesized nil/zero inputs.  If that's all you can write,"
        )
        out.append(
            "     LEAVE THE PROC YELLOW — never mark green to make progress."
        )
        out.append(
            "  4. Mark the result: "
            "`scripts/mark_test_status.py <KEY> {green|red} --note '...'`."
        )
        out.append(
            "  5. Re-run `scripts/next_task.py`.  If a sibling came back red "
            "the picker will choose it as the new deepest red and you drill in."
        )
        out.append(
            "     If every sibling came back green the picker pops up to "
            "INVESTIGATE_PROC on the parent red — the bug is in its own body."
        )
    else:  # INVESTIGATE_PROC
        n_green = sum(1 for c in task["all_children"] if c["status"] == "green")
        n_total = len(task["all_children"])
        if n_total == 0:
            out.append("This red has NO recorded call-graph dependencies "
                      "(leaf proc).  The bug must be in its own body.")
        else:
            out.append(
                f"All {n_green}/{n_total} dependencies are green — the bug "
                f"is inside this proc itself."
            )
        out.append("")
        out.append("Action:")
        out.append(
            "  1. Open the Java source above and read the method in full."
        )
        out.append(
            "  2. Diff line-by-line against the Odin port. Stay faithful "
            "to Java semantics."
        )
        out.append("  3. Apply the fix; re-run the failing snapshot / test.")
        out.append(
            "  4. Mark green: `scripts/mark_test_status.py "
            f"'{red['key']}' green --note 'fixed: <one-line summary>'`."
        )

    if task["all_children"]:
        out.append("")
        out.append(f"All {len(task['all_children'])} dependencies "
                  "(deepest yellow → red → green):")
        for c in task["all_children"]:
            cl = "?" if c["layer"] is None else str(c["layer"])
            out.append(f"  [{c['status']:<6}] layer={cl:<3} {c['key']}")

    if top and conn is not None:
        out.append("")
        out.append(f"=== Top {top} red candidates (deepest first) ===")
        reds = _fetch_reds(conn)[:top]
        for r in reds:
            cl = "?" if r["layer"] is None else str(r["layer"])
            marker = " <-- chosen" if r["key"] == red["key"] else ""
            out.append(f"  layer={cl:<3} {r['key']}{marker}")
            if r["note"]:
                out.append(f"           note: {r['note']}")
    return "\n".join(out)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__,
                               formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--json", action="store_true",
                  help="Emit JSON (for the dashboard / tooling).")
    p.add_argument("--top", type=int, default=0,
                  help="Also show the top-N red candidates after the chosen one.")
    args = p.parse_args(argv)

    if not os.path.isfile(_DB):
        print(f"error: db not found at {_DB}", file=sys.stderr)
        return 1
    conn = _open_db()
    try:
        _ensure_test_status(conn)
        task = pick_next(conn)
        if args.json:
            print(json.dumps(task, indent=2))
        else:
            print(_format(task, top=args.top, conn=conn))
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
