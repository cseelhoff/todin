#!/usr/bin/env python3
"""build_called_layered_tables.py
================================================================================
From `entities` + `dependencies`, produce two new tables restricted to entities
that JaCoCo observed actually executing:

    methods(method_key, owner_struct_key, java_file_path, java_lines,
            odin_file_path, is_implemented, method_layer)
    structs(struct_key, java_file_path, java_lines, odin_file_path,
            is_implemented, struct_layer, scc_id, id_design_layer)

Layer numbers are computed via Tarjan SCC condensation + topological depth on
each table's induced subgraph. All members of a strongly-connected component
share a layer (cycles become layer-bands).

Usage:
    python3 build_called_layered_tables.py [--db PATH]

Env vars:
    PORT_DB     sqlite database (default: ./port.sqlite)
================================================================================
"""

import argparse
import os
import sqlite3
import sys
from collections import defaultdict

# ---------- iterative Tarjan SCC ----------
def tarjan_sccs(nodes, adj):
    sys.setrecursionlimit(50_000)
    index_counter = [0]
    stack: list[str] = []
    on_stack: set[str] = set()
    index: dict[str, int] = {}
    low: dict[str, int] = {}
    sccs: list[list[str]] = []

    for start in nodes:
        if start in index:
            continue
        work = [(start, iter(adj.get(start, ())))]
        index[start] = index_counter[0]
        low[start] = index_counter[0]
        index_counter[0] += 1
        stack.append(start)
        on_stack.add(start)
        while work:
            v, it = work[-1]
            try:
                w = next(it)
            except StopIteration:
                work.pop()
                if work:
                    parent = work[-1][0]
                    if low[v] < low[parent]:
                        low[parent] = low[v]
                if low[v] == index[v]:
                    comp = []
                    while True:
                        x = stack.pop()
                        on_stack.discard(x)
                        comp.append(x)
                        if x == v:
                            break
                    sccs.append(comp)
                continue
            if w not in index:
                index[w] = index_counter[0]
                low[w] = index_counter[0]
                index_counter[0] += 1
                stack.append(w)
                on_stack.add(w)
                work.append((w, iter(adj.get(w, ()))))
            elif w in on_stack:
                if index[w] < low[v]:
                    low[v] = index[w]
    return sccs


def assign_layers(nodes, adj, sccs):
    scc_of = {n: i for i, comp in enumerate(sccs) for n in comp}
    cond_out: dict[int, set[int]] = defaultdict(set)
    for u in nodes:
        su = scc_of[u]
        for v in adj.get(u, ()):
            if v not in scc_of:
                continue
            sv = scc_of[v]
            if sv != su:
                cond_out[su].add(sv)
    layer_of_scc: dict[int, int] = {}
    for i in range(len(sccs)):
        outs = cond_out.get(i)
        layer_of_scc[i] = 0 if not outs else 1 + max(layer_of_scc[j] for j in outs)
    return {n: layer_of_scc[scc_of[n]] for n in nodes}, scc_of


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.environ.get("PORT_DB", "port.sqlite"))
    args = ap.parse_args()

    conn = sqlite3.connect(args.db)
    cur = conn.cursor()

    # ---- preserve is_implemented flags across rebuild ----
    # The structs/methods tables hold the authoritative port-progress flags;
    # entities.is_fully_implemented_error_free_no_todo_no_stub is only
    # populated for the initial seed. Snapshot the flags before DROP so we
    # don't clobber porting progress.
    saved_struct_impl: dict[str, int] = {}
    saved_method_impl: dict[str, int] = {}
    try:
        saved_struct_impl = {
            k: v for k, v in cur.execute(
                "SELECT struct_key, is_implemented FROM structs "
                "WHERE is_implemented = 1"
            )
        }
    except sqlite3.OperationalError:
        pass
    try:
        saved_method_impl = {
            k: v for k, v in cur.execute(
                "SELECT method_key, is_implemented FROM methods "
                "WHERE is_implemented = 1"
            )
        }
    except sqlite3.OperationalError:
        pass
    print(f"preserving {len(saved_struct_impl)} implemented structs, "
          f"{len(saved_method_impl)} implemented methods across rebuild")

    print("recreating methods & structs tables...")
    cur.executescript("""
        DROP TABLE IF EXISTS methods;
        DROP TABLE IF EXISTS structs;
        CREATE TABLE methods (
            method_key       TEXT PRIMARY KEY,
            owner_struct_key TEXT NOT NULL,
            java_file_path   TEXT,
            java_lines       TEXT,
            odin_file_path   TEXT,
            is_implemented   INTEGER NOT NULL DEFAULT 0,
            method_layer     INTEGER
        );
        CREATE TABLE structs (
            struct_key       TEXT PRIMARY KEY,
            java_file_path   TEXT,
            java_lines       TEXT,
            odin_file_path   TEXT,
            is_implemented   INTEGER NOT NULL DEFAULT 0,
            struct_layer     INTEGER,
            scc_id           INTEGER,
            id_design_layer  INTEGER
        );
    """)

    cur.execute("""
        INSERT INTO methods (method_key, owner_struct_key, java_file_path,
                             java_lines, odin_file_path, is_implemented)
        SELECT primary_key,
               'struct:' || substr(primary_key, 6, instr(primary_key,'#') - 6),
               java_file_path, java_lines, odin_file_path,
               is_fully_implemented_error_free_no_todo_no_stub
        FROM entities
        WHERE primary_key LIKE 'proc:%' AND actually_called_in_ai_test = 1
          AND is_ui = 0
    """)
    n_methods = cur.execute("SELECT COUNT(*) FROM methods").fetchone()[0]
    print(f"  methods (JaCoCo seed): {n_methods}")

    # ---- include lambda$* siblings of any included class ----
    # Lambda methods are invoked exclusively via invokedynamic, which we
    # don't capture as proc->proc edges. JaCoCo records most lambdas, but
    # factory-style lambdas (e.g. `() -> new TwoIfBySeaEndTurnDelegate()`
    # inside `XmlGameElementMapper.newTwoIfBySeaDelegateFactories()`) are
    # constructed during setup but never executed in the AI snapshot, so
    # they're filtered out -- yet their body's `new T()` references are
    # the only way `T` enters the struct graph. Include every lambda$
    # method of any class that already has at least one included method,
    # regardless of the JaCoCo flag, so static struct dependencies
    # transitively reach into the lambda bodies.
    added_lambdas = cur.execute("""
        INSERT OR IGNORE INTO methods
            (method_key, owner_struct_key, java_file_path, java_lines,
             odin_file_path, is_implemented)
        SELECT e.primary_key,
               'struct:' || substr(e.primary_key, 6, instr(e.primary_key,'#') - 6),
               e.java_file_path, e.java_lines, e.odin_file_path,
               e.is_fully_implemented_error_free_no_todo_no_stub
        FROM entities e
        WHERE e.primary_key LIKE 'proc:%'
          AND e.is_ui = 0
          AND substr(e.primary_key,
                     instr(e.primary_key,'#') + 1,
                     7) = 'lambda$'
          AND ('struct:' || substr(e.primary_key, 6,
                                   instr(e.primary_key,'#') - 6))
              IN (SELECT DISTINCT owner_struct_key FROM methods)
    """).rowcount
    print(f"  + lambda$ siblings: {added_lambdas}")

    # ---- transitive proc->proc closure ----
    # Pull in any non-UI proc that an already-included method calls,
    # regardless of the JaCoCo flag. This fixes two systemic gaps:
    #  - private static helpers (e.g. XmlGameElementMapper#handleMissingObject)
    #    that JaCoCo missed because the AI snapshot never hits the error
    #    path, but whose callers are included.
    #  - interface methods (e.g. IEditableProperty#getValue()) only
    #    recorded against the concrete subclass; callers that hold the
    #    interface type need the abstract proc to call into.
    # The first pass also folds in `struct -> proc` edges from constant-
    # pool method references (`Foo::new`, `Foo::bar`) attributed at
    # class scope by extract_entities.py: any struct whose method is in
    # `methods` may cp-reference further procs through method-reference
    # syntax that javap's `-c` invokedynamic comment doesn't expose.
    while True:
        added_calls = cur.execute("""
            INSERT OR IGNORE INTO methods
                (method_key, owner_struct_key, java_file_path, java_lines,
                 odin_file_path, is_implemented)
            SELECT DISTINCT
                   e.primary_key,
                   'struct:' || substr(e.primary_key, 6, instr(e.primary_key,'#') - 6),
                   e.java_file_path, e.java_lines, e.odin_file_path,
                   e.is_fully_implemented_error_free_no_todo_no_stub
            FROM entities e
            JOIN dependencies d ON d.depends_on_key = e.primary_key
            WHERE e.primary_key LIKE 'proc:%'
              AND e.is_ui = 0
              AND (
                   d.primary_key IN (SELECT method_key FROM methods)
                OR d.primary_key IN (SELECT owner_struct_key FROM methods)
              )
              AND d.depends_on_key NOT IN (SELECT method_key FROM methods)
        """).rowcount
        if not added_calls:
            break
        print(f"  + transitive proc calls: {added_calls}")
    n_methods = cur.execute("SELECT COUNT(*) FROM methods").fetchone()[0]
    print(f"  methods (with closure): {n_methods}")

    cur.execute("""
        INSERT INTO structs (struct_key, java_file_path, java_lines,
                             odin_file_path, is_implemented)
        SELECT DISTINCT e.primary_key, e.java_file_path, e.java_lines,
                        e.odin_file_path,
                        e.is_fully_implemented_error_free_no_todo_no_stub
        FROM entities e
        WHERE e.primary_key LIKE 'struct:%'
          AND e.is_ui = 0
          AND (e.primary_key IN (SELECT owner_struct_key FROM methods)
               OR e.primary_key IN (
                  SELECT d.depends_on_key FROM dependencies d
                  WHERE d.primary_key IN (SELECT method_key FROM methods)
                    AND d.depends_on_key LIKE 'struct:%'
               ))
    """)
    n_structs = cur.execute("SELECT COUNT(*) FROM structs").fetchone()[0]
    print(f"  structs (direct): {n_structs}")

    # ---- transitively include struct-graph ancestors ----
    # The above query only pulls structs that own a tested method or are
    # directly referenced by such a method. That misses abstract base classes
    # whose methods are only invoked via subclass dispatch (e.g.
    # AbstractConditionsAttachment, AbstractPlayerRulesAttachment), leaving
    # subclasses unable to express `using parent: Parent`. Walk the
    # struct->struct dependency graph from the current set and pull in any
    # ancestors that exist in `entities`.
    while True:
        added = cur.execute("""
            INSERT OR IGNORE INTO structs
                (struct_key, java_file_path, java_lines, odin_file_path,
                 is_implemented)
            SELECT DISTINCT e.primary_key, e.java_file_path, e.java_lines,
                            e.odin_file_path,
                            e.is_fully_implemented_error_free_no_todo_no_stub
            FROM entities e
            JOIN dependencies d ON d.depends_on_key = e.primary_key
            WHERE e.primary_key LIKE 'struct:%'
              AND e.is_ui = 0
              AND d.primary_key IN (SELECT struct_key FROM structs)
              AND d.depends_on_key NOT IN (SELECT struct_key FROM structs)
        """).rowcount
        if not added:
            break
        print(f"  + transitive ancestors: {added}")
    n_structs = cur.execute("SELECT COUNT(*) FROM structs").fetchone()[0]
    print(f"  structs (with ancestors): {n_structs}")
    conn.commit()

    # ---- layer the structs (full reference graph) ----
    print("layering structs (reference graph)...")
    struct_set = {r[0] for r in cur.execute("SELECT struct_key FROM structs")}
    s_adj: dict[str, list[str]] = defaultdict(list)
    for u, v in cur.execute(
        "SELECT primary_key, depends_on_key FROM dependencies "
        "WHERE primary_key LIKE 'struct:%' AND depends_on_key LIKE 'struct:%'"
    ):
        if u in struct_set and v in struct_set and u != v:
            s_adj[u].append(v)
    sccs_s = tarjan_sccs(list(struct_set), s_adj)
    layers_s, _ = assign_layers(struct_set, s_adj, sccs_s)
    big = [s for s in sccs_s if len(s) > 1]
    print(f"  struct SCCs: {len(sccs_s)}, cycles: {len(big)}, "
          f"largest = {max((len(s) for s in big), default=1)}")
    cur.executemany(
        "UPDATE structs SET struct_layer = ? WHERE struct_key = ?",
        [(L, k) for k, L in layers_s.items()],
    )

    # ---- layer the methods ----
    print("layering methods...")
    method_set = {r[0] for r in cur.execute("SELECT method_key FROM methods")}
    m_adj: dict[str, list[str]] = defaultdict(list)
    for u, v in cur.execute(
        "SELECT primary_key, depends_on_key FROM dependencies "
        "WHERE primary_key LIKE 'proc:%' AND depends_on_key LIKE 'proc:%'"
    ):
        if u in method_set and v in method_set and u != v:
            m_adj[u].append(v)
    sccs_m = tarjan_sccs(list(method_set), m_adj)
    layers_m, _ = assign_layers(method_set, m_adj, sccs_m)
    big = [s for s in sccs_m if len(s) > 1]
    print(f"  method SCCs: {len(sccs_m)}, cycles: {len(big)}, "
          f"largest = {max((len(s) for s in big), default=1)}")
    cur.executemany(
        "UPDATE methods SET method_layer = ? WHERE method_key = ?",
        [(L, k) for k, L in layers_m.items()],
    )
    conn.commit()

    # ---- restore preserved is_implemented flags ----
    if saved_struct_impl:
        restored_s = cur.executemany(
            "UPDATE structs SET is_implemented = 1 WHERE struct_key = ?",
            [(k,) for k in saved_struct_impl],
        ).rowcount
        print(f"restored is_implemented on {restored_s}/"
              f"{len(saved_struct_impl)} structs")
    if saved_method_impl:
        restored_m = cur.executemany(
            "UPDATE methods SET is_implemented = 1 WHERE method_key = ?",
            [(k,) for k in saved_method_impl],
        ).rowcount
        print(f"restored is_implemented on {restored_m}/"
              f"{len(saved_method_impl)} methods")
    conn.commit()

    print("\n--- struct layer summary ---  layer | impl | total")
    for L, t, im in cur.execute(
        "SELECT struct_layer, COUNT(*), "
        "SUM(CASE WHEN is_implemented=1 THEN 1 ELSE 0 END) "
        "FROM structs GROUP BY struct_layer ORDER BY struct_layer"
    ):
        print(f"  {L:>3} | {im:>4} | {t:>4}")

    print("\n--- method layer summary ---  layer | impl | total")
    for L, t, im in cur.execute(
        "SELECT method_layer, COUNT(*), "
        "SUM(CASE WHEN is_implemented=1 THEN 1 ELSE 0 END) "
        "FROM methods GROUP BY method_layer ORDER BY method_layer"
    ):
        print(f"  {L:>3} | {im:>4} | {t:>4}")
    conn.close()


if __name__ == "__main__":
    main()
