#!/usr/bin/env python3
"""Realtime test-status dashboard for port.sqlite.

Run:
    python3 scripts/test_status_dashboard.py [--port 8765]

Then open http://localhost:8765/ in a browser. The page polls
`/api/tree` every 2 s and renders each red entity together with its
direct (one-layer-down) call dependencies, colored by `test_status`:

    green  = tests passing
    red    = tests failing / known cause of a downstream failure
    yellow = untested / unknown

Stdlib-only (http.server, sqlite3, json). No external deps.
"""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

_HERE = os.path.dirname(os.path.abspath(__file__))
_DB = os.path.join(os.path.dirname(_HERE), "port.sqlite")

# Keep the picker importable as a module so the dashboard reuses the
# exact same algorithm humans run from the CLI.  This guarantees the
# "next task" panel never drifts from `python3 scripts/next_task.py`.
sys.path.insert(0, _HERE)
import next_task as _next_task  # noqa: E402  (deliberate after sys.path tweak)


_INDEX_HTML = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>port.sqlite — test status</title>
<style>
  :root {
    color-scheme: dark light;
    --green: #2ea043;
    --red: #f85149;
    --yellow: #d29922;
    --bg: #0d1117;
    --fg: #c9d1d9;
    --muted: #8b949e;
    --panel: #161b22;
    --border: #30363d;
  }
  body { margin: 0; background: var(--bg); color: var(--fg);
         font: 13px/1.45 ui-monospace, SFMono-Regular, Menlo, monospace; }
  header { padding: 10px 16px; border-bottom: 1px solid var(--border);
           display: flex; gap: 16px; align-items: baseline;
           position: sticky; top: 0; background: var(--bg); z-index: 10; }
  header h1 { margin: 0; font-size: 14px; font-weight: 600; }
  .pill { padding: 2px 8px; border-radius: 999px; font-weight: 600;
          border: 1px solid var(--border); }
  .pill.green  { color: var(--green); }
  .pill.red    { color: var(--red); }
  .pill.yellow { color: var(--yellow); }
  main { padding: 12px 16px; }

  /* Tree visuals --------------------------------------------------- */
  details.tree-node { margin: 0; padding: 0; background: transparent;
                      border: none; border-radius: 0; }
  details.tree-node > summary { cursor: pointer; list-style: none;
                                padding: 3px 4px; border-radius: 4px;
                                display: flex; align-items: center; gap: 6px; }
  details.tree-node > summary::-webkit-details-marker { display: none; }
  /* Custom chevron */
  details.tree-node > summary::before {
    content: '▶'; display: inline-block; width: 12px;
    color: var(--muted); font-size: 10px;
    transition: transform 120ms ease; flex: 0 0 auto;
  }
  details.tree-node[open] > summary::before { transform: rotate(90deg); }
  details.tree-node > summary:hover { background: rgba(255,255,255,0.04); }
  /* Highlight red rows */
  details.tree-node.red    > summary { background: rgba(248,81,73,0.06); }
  details.tree-node.red    > summary:hover { background: rgba(248,81,73,0.12); }

  .leaf { padding: 3px 4px 3px 22px; /* indent matches chevron+gap */ }
  .children { padding-left: 18px; margin-left: 6px;
              border-left: 1px dashed var(--border); }

  .row.node-row { display: flex; align-items: baseline; gap: 8px;
                  flex: 1 1 auto; min-width: 0; }
  .dot { width: 10px; height: 10px; border-radius: 50%;
         display: inline-block; flex: 0 0 auto; }
  .dot.green  { background: var(--green); }
  .dot.red    { background: var(--red); }
  .dot.yellow { background: var(--yellow); }
  .layer { color: var(--muted); font-size: 11px; min-width: 32px;
           text-align: right; flex: 0 0 auto; }
  .key { word-break: break-all; }
  .note { color: var(--muted); font-style: italic;
          margin-left: 46px; margin-top: 1px; font-size: 11px; }
  .meta { color: var(--muted); font-size: 11px; margin-left: 4px; }
  .meta.cycle { color: var(--yellow); }
  .subtree-meta { margin-left: auto; font-size: 11px; color: var(--muted);
                  flex: 0 0 auto; }
  .subtree-meta b { font-weight: 700; }
  .t-red    { color: var(--red); }
  .t-yellow { color: var(--yellow); }
  .t-green  { color: var(--green); }

  .empty { color: var(--muted); padding: 16px; text-align: center; }
  .controls { margin-left: auto; }
  .controls button { background: var(--panel); color: var(--fg);
                     border: 1px solid var(--border); padding: 3px 8px;
                     border-radius: 4px; cursor: pointer; font: inherit; }
  .controls button:hover { background: rgba(255,255,255,0.06); }
  input[type="search"] { background: var(--panel); border: 1px solid var(--border);
         color: var(--fg); padding: 3px 8px; border-radius: 4px;
         font: inherit; min-width: 240px; margin-right: 8px; }
  /* Next-task panel: mirrors `python3 scripts/next_task.py`. */
  .next-task { margin: 12px 16px 0; padding: 10px 14px;
               border: 1px solid var(--border); border-radius: 6px;
               background: var(--panel); }
  .next-task .kind { display: inline-block; padding: 1px 8px;
                     border-radius: 4px; font-weight: 700;
                     letter-spacing: 0.04em; font-size: 11px;
                     margin-right: 8px; }
  .next-task .kind.TEST_DEP        { background: #d29922; color: #0d1117; }
  .next-task .kind.INVESTIGATE_PROC { background: #f85149; color: #0d1117; }
  .next-task .kind.NO_REDS          { background: #2ea043; color: #0d1117; }
  .next-task h2 { margin: 0 0 6px; font-size: 13px; font-weight: 600; }
  .next-task .red-key { word-break: break-all; }
  .next-task ul { list-style: none; padding: 4px 0 0 18px;
                  margin: 6px 0 0; border-left: 2px solid var(--border); }
  .next-task li { padding: 2px 0; }
  .next-task .path { color: var(--muted); font-size: 11px;
                     margin-left: 22px; }
  .next-task .action { margin-top: 6px; color: var(--muted);
                       font-size: 12px; }
</style>
</head>
<body>
<header>
  <h1>port.sqlite test status</h1>
  <span class="pill green"  id="count-green">green 0</span>
  <span class="pill red"    id="count-red">red 0</span>
  <span class="pill yellow" id="count-yellow">yellow 0</span>
  <span class="meta" id="updated">never updated</span>
  <div class="controls">
    <input type="search" id="filter" placeholder="filter (regex)" />
    <button id="expand-all" title="Expand every node">expand all</button>
    <button id="collapse-all" title="Collapse every node">collapse all</button>
  </div>
</header>
<section id="next-task" class="next-task"><div class="empty">computing next task…</div></section>
<main id="root"><div class="empty">loading…</div></main>
<script>
const root = document.getElementById('root');
const $ = id => document.getElementById(id);
let lastSig = '';

function dot(status) {
  const d = document.createElement('span');
  d.className = 'dot ' + status;
  return d;
}

// Recursively render a tree node as a nested <details open>.
// Leaves (no children) render as a single <div> with no chevron.
function renderNode(node, openSet) {
  const hasKids = node.children && node.children.length > 0;
  const labelRow = document.createElement('div');
  labelRow.className = 'row node-row ' + node.status;
  labelRow.appendChild(dot(node.status));

  const layerStr = (node.layer == null) ? '?' : node.layer;
  const layerSpan = document.createElement('span');
  layerSpan.className = 'layer';
  layerSpan.textContent = 'L' + layerStr;
  labelRow.appendChild(layerSpan);

  const keySpan = document.createElement('span');
  keySpan.className = 'key';
  keySpan.textContent = node.key;
  labelRow.appendChild(keySpan);

  if (node.edge_kind && node.edge_kind !== 'root') {
    const ek = document.createElement('span');
    ek.className = 'meta';
    ek.textContent = node.edge_kind;
    labelRow.appendChild(ek);
  }
  if (node.cycle) {
    const c = document.createElement('span');
    c.className = 'meta cycle';
    c.textContent = '↺ cycle';
    labelRow.appendChild(c);
  }

  if (!hasKids) {
    // No children — render as a flat row, no chevron.
    const wrap = document.createElement('div');
    wrap.className = 'leaf';
    wrap.appendChild(labelRow);
    if (node.note) {
      const n = document.createElement('div');
      n.className = 'note';
      n.textContent = node.note;
      wrap.appendChild(n);
    }
    return wrap;
  }

  const det = document.createElement('details');
  det.className = 'tree-node ' + node.status;
  det.dataset.key = node.key;
  // Default to OPEN for every node; preserve user-collapsed state
  // across polls via openSet (which records which keys ARE open).
  det.open = openSet.has(node.key) || !openSet.has('__seen__:' + node.key);
  const sum = document.createElement('summary');
  sum.appendChild(labelRow);
  // Counts of each status in the subtree, shown next to chevron.
  const counts = subtreeCounts(node);
  const total = counts.red + counts.yellow + counts.green;
  const summaryMeta = document.createElement('span');
  summaryMeta.className = 'subtree-meta';
  const parts = [];
  if (counts.red)    parts.push('<b class="t-red">'    + counts.red    + '</b>');
  if (counts.yellow) parts.push('<b class="t-yellow">' + counts.yellow + '</b>');
  if (counts.green)  parts.push('<b class="t-green">'  + counts.green  + '</b>');
  summaryMeta.innerHTML = parts.join(' / ') + ' (' + total + ')';
  sum.appendChild(summaryMeta);
  det.appendChild(sum);

  if (node.note) {
    const n = document.createElement('div');
    n.className = 'note';
    n.textContent = node.note;
    det.appendChild(n);
  }

  const kidsBox = document.createElement('div');
  kidsBox.className = 'children';
  for (const c of node.children) {
    kidsBox.appendChild(renderNode(c, openSet));
  }
  det.appendChild(kidsBox);
  return det;
}

function subtreeCounts(node) {
  const out = { red: 0, yellow: 0, green: 0 };
  out[node.status] = (out[node.status] || 0) + 1;
  for (const c of (node.children || [])) {
    const sub = subtreeCounts(c);
    out.red    += sub.red;
    out.yellow += sub.yellow;
    out.green  += sub.green;
  }
  return out;
}

function render(data) {
  // Cheap signature so we don't clobber open/closed state on every poll.
  const sig = JSON.stringify({s: data.summary, r: (data.roots || []).map(rootSig)});
  if (sig === lastSig) {
    $('updated').textContent = 'updated ' + new Date().toLocaleTimeString();
    return;
  }
  lastSig = sig;

  $('count-green').textContent  = 'green '  + (data.summary.green  || 0);
  $('count-red').textContent    = 'red '    + (data.summary.red    || 0);
  $('count-yellow').textContent = 'yellow ' + (data.summary.yellow || 0);
  $('updated').textContent      = 'updated ' + new Date().toLocaleTimeString();

  // Snapshot which <details> the user has explicitly toggled.
  // We track open keys; nodes not yet seen default to OPEN (per spec).
  const openKeys = new Set(
    Array.from(root.querySelectorAll('details[data-key]'))
         .filter(d => d.open)
         .map(d => d.dataset.key));
  const seenKeys = new Set(
    Array.from(root.querySelectorAll('details[data-key]'))
         .map(d => '__seen__:' + d.dataset.key));
  const openSet = new Set([...openKeys, ...seenKeys]);

  const frag = document.createDocumentFragment();
  const roots = (data.roots || []);
  if (roots.length === 0) {
    const e = document.createElement('div');
    e.className = 'empty';
    e.textContent = 'no red entities — nothing failing right now';
    frag.appendChild(e);
  }
  for (const r of roots) {
    frag.appendChild(renderNode(r, openSet));
  }
  root.replaceChildren(frag);
}

function rootSig(n) {
  return [n.key, n.status, n.layer, (n.children || []).map(rootSig)];
}

function renderNextTask(t) {
  const panel = $('next-task');
  if (!t) { panel.replaceChildren(); return; }
  const frag = document.createDocumentFragment();
  const head = document.createElement('h2');
  const kindSpan = document.createElement('span');
  kindSpan.className = 'kind ' + t.kind;
  kindSpan.textContent = t.kind;
  head.appendChild(kindSpan);
  if (t.kind === 'NO_REDS') {
    head.appendChild(document.createTextNode('no red entities recorded'));
    frag.appendChild(head);
    const hint = document.createElement('div');
    hint.className = 'action';
    hint.textContent = t.hint || '';
    frag.appendChild(hint);
  } else {
    const layer = (t.red && t.red.layer != null) ? ('layer=' + t.red.layer) : 'layer=?';
    head.appendChild(document.createTextNode(layer + '  '));
    const k = document.createElement('span');
    k.className = 'red-key';
    k.textContent = t.red.key;
    head.appendChild(k);
    frag.appendChild(head);
    if (t.red.note) {
      const n = document.createElement('div');
      n.className = 'note';
      n.textContent = t.red.note;
      frag.appendChild(n);
    }
    if (t.kind === 'TEST_DEP') {
      const action = document.createElement('div');
      action.className = 'action';
      action.textContent = 'Test the deepest yellow dependency, then `scripts/mark_test_status.py <KEY> {green|red}`:';
      frag.appendChild(action);
      const ul = document.createElement('ul');
      for (const c of t.deepest_yellow_children) {
        const li = document.createElement('li');
        const cl = (c.layer == null) ? '?' : c.layer;
        const row = document.createElement('div');
        row.className = 'row';
        row.appendChild(dot('yellow'));
        const ck = document.createElement('span');
        ck.className = 'key';
        ck.textContent = 'layer=' + cl + '  ' + c.key;
        row.appendChild(ck);
        li.appendChild(row);
        if (c.odin_path || c.java_path) {
          const p = document.createElement('div');
          p.className = 'path';
          p.textContent = (c.odin_path || '') + (c.java_path ? '  ←  ' + c.java_path + (c.java_lines ? ':' + c.java_lines : '') : '');
          li.appendChild(p);
        }
        ul.appendChild(li);
      }
      frag.appendChild(ul);
    } else if (t.kind === 'INVESTIGATE_PROC') {
      const ngreen = (t.all_children || []).filter(c => c.status === 'green').length;
      const ntotal = (t.all_children || []).length;
      const action = document.createElement('div');
      action.className = 'action';
      action.textContent = (ntotal === 0)
        ? 'No recorded call-graph dependencies. Bug is in the proc body itself — read the Java in full and diff against the Odin port.'
        : ('All ' + ngreen + '/' + ntotal + ' deps green. Bug is inside this proc — read the Java and diff against the Odin port.');
      frag.appendChild(action);
      if (t.red.java_path) {
        const p = document.createElement('div');
        p.className = 'path';
        p.textContent = 'java: ' + t.red.java_path + (t.red.java_lines ? ':' + t.red.java_lines : '');
        frag.appendChild(p);
      }
      if (t.red.odin_path) {
        const p = document.createElement('div');
        p.className = 'path';
        p.textContent = 'odin: ' + t.red.odin_path;
        frag.appendChild(p);
      }
    }
  }
  panel.replaceChildren(frag);
}

async function poll() {
  try {
    const [tr, nx] = await Promise.all([
      fetch('/api/tree', { cache: 'no-store' }),
      fetch('/api/next', { cache: 'no-store' }),
    ]);
    if (tr.ok) render(await tr.json());
    if (nx.ok) renderNextTask(await nx.json());
  } catch (e) {
    $('updated').textContent = 'fetch error: ' + e;
  }
}
$('expand-all').addEventListener('click', () => {
  root.querySelectorAll('details.tree-node').forEach(d => d.open = true);
});
$('collapse-all').addEventListener('click', () => {
  root.querySelectorAll('details.tree-node').forEach(d => d.open = false);
});
$('filter').addEventListener('input', () => {
  const v = $('filter').value.trim();
  let re = null;
  if (v) { try { re = new RegExp(v, 'i'); } catch {} }
  root.querySelectorAll('.row.node-row').forEach(r => {
    const key = r.querySelector('.key').textContent;
    const match = !re || re.test(key);
    // Hide rows that don't match; ancestors stay visible because
    // their summary row matches its own key.
    const host = r.closest('details.tree-node, .leaf');
    if (host) host.style.display = match || !re ? '' : 'none';
  });
});
poll();
setInterval(poll, 2000);
</script>
</body>
</html>
"""


def _open_db() -> sqlite3.Connection:
    conn = sqlite3.connect(_DB)
    conn.row_factory = sqlite3.Row
    return conn


def _build_tree() -> dict:
    """Forward drill-down call-tree rooted at each top-most red proc.

    Mirrors `scripts/next_task.py`'s methodology: walk the call graph
    FORWARD from each red that has no red ancestor (the topmost red),
    recursing through any node that lies on a path to a red so the
    deeper reds appear nested in their natural call context. Yellow /
    green leaves directly under a red render as immediate context;
    yellow / green nodes that are NOT on a path to any red are not
    expanded further. Every method_key renders at most ONCE across
    the forest — repeats become `cycle=true` placeholder leaves — so
    a high-fan-in proc like `MustFightBattle#fight` shows up once.
    """
    conn = _open_db()
    try:
        conn.execute(
            """CREATE TABLE IF NOT EXISTS test_status (
                entity_key TEXT PRIMARY KEY,
                status TEXT NOT NULL DEFAULT 'yellow'
                       CHECK(status IN ('green','red','yellow')),
                note TEXT,
                updated_at TEXT NOT NULL
            )"""
        )

        summary = {"green": 0, "red": 0, "yellow": 0}
        for row in conn.execute("SELECT status, COUNT(*) FROM test_status GROUP BY status"):
            summary[row[0]] = row[1]

        status_map: dict[str, tuple[str, str | None]] = {}
        for row in conn.execute("SELECT entity_key, status, note FROM test_status"):
            status_map[row["entity_key"]] = (row["status"], row["note"])

        red_keys = [k for k, (s, _) in status_map.items() if s == "red"]
        if not red_keys:
            return {"summary": summary, "roots": []}

        # --- Reverse BFS from every red to collect ancestors -----------
        # Any node that transitively calls a red has a red descendant
        # and is therefore "on a path to a red" — we recurse through
        # those when building the tree. We also note, per red, which
        # OTHER reds appear in its ancestor set, so a red R is topmost
        # iff no other red is among its ancestors.
        ancestors: set[str] = set()                            # nodes with a red descendant
        red_ancestors_per_red: dict[str, set[str]] = {r: set() for r in red_keys}
        red_set = set(red_keys)
        for r in red_keys:
            sub_seen: set[str] = {r}
            frontier = [r]
            while frontier:
                ph = ",".join("?" * len(frontier))
                rows = conn.execute(
                    f"""SELECT DISTINCT primary_key
                        FROM dependencies
                        WHERE depends_on_key IN ({ph})
                          AND edge_kind IN ('static','virtual','override')""",
                    frontier,
                ).fetchall()
                next_frontier: list[str] = []
                for row in rows:
                    p = row["primary_key"]
                    if p in sub_seen:
                        continue
                    sub_seen.add(p)
                    next_frontier.append(p)
                    ancestors.add(p)
                    if p in red_set:
                        red_ancestors_per_red[r].add(p)
                frontier = next_frontier
                if len(sub_seen) > 20000:  # safety cap
                    break

        top_reds = [r for r in red_keys if not red_ancestors_per_red[r]]
        if not top_reds:  # all reds form a cycle
            top_reds = list(red_keys)

        # Method-metadata cache, lazily populated.
        meta_map: dict[str, dict] = {}

        def load_meta(keys: list[str]) -> None:
            todo = [k for k in keys if k not in meta_map]
            if not todo:
                return
            chunk = 800
            for i in range(0, len(todo), chunk):
                part = todo[i:i + chunk]
                php = ",".join("?" * len(part))
                for row in conn.execute(
                    f"""SELECT method_key, method_layer, java_file_path,
                              java_lines, odin_file_path
                       FROM methods WHERE method_key IN ({php})""",
                    part,
                ):
                    meta_map[row["method_key"]] = {
                        "layer": row["method_layer"],
                        "java_path": row["java_file_path"],
                        "java_lines": row["java_lines"],
                        "odin_path": row["odin_file_path"],
                    }
                for k in part:
                    meta_map.setdefault(k, {"layer": None, "java_path": None,
                                            "java_lines": None, "odin_path": None})

        load_meta(list(red_keys) + list(ancestors))

        def fetch_call_children(parent_key: str) -> list[dict]:
            rows = list(conn.execute(
                """SELECT d.depends_on_key AS key,
                          GROUP_CONCAT(DISTINCT d.edge_kind) AS edge_kinds
                   FROM dependencies d
                   JOIN methods m ON m.method_key = d.depends_on_key
                   WHERE d.primary_key = ?
                     AND d.edge_kind IN ('static','virtual','override')
                   GROUP BY d.depends_on_key""",
                (parent_key,),
            ))
            load_meta([r["key"] for r in rows])
            out: list[dict] = []
            for row in rows:
                k = row["key"]
                st, note = status_map.get(k, ("yellow", None))
                m = meta_map.get(k, {})
                out.append({
                    "key": k,
                    "status": st,
                    "note": note,
                    "layer": m.get("layer"),
                    "edge_kind": row["edge_kinds"],
                    "java_path": m.get("java_path"),
                    "java_lines": m.get("java_lines"),
                    "odin_path": m.get("odin_path"),
                })
            # red first (drill targets), then yellow (next tests),
            # then green; within each band, deepest layer (lowest
            # number) first to mirror next_task.py's ordering.
            order = {"red": 0, "yellow": 1, "green": 2}
            out.sort(key=lambda c: (
                order.get(c["status"], 3),
                (c["layer"] if c["layer"] is not None else 1 << 30),
                c["key"],
            ))
            return out

        # Global dedup: each method_key renders fully once; later
        # occurrences become `cycle=true` placeholder leaves.
        rendered: set[str] = set()

        def build(key: str, edge_kind: str, parent_status: str, depth: int) -> dict:
            st, note = status_map.get(key, ("yellow", None))
            m = meta_map.get(key, {})
            node = {
                "key": key,
                "status": st,
                "note": note,
                "layer": m.get("layer"),
                "edge_kind": edge_kind,
                "java_path": m.get("java_path"),
                "java_lines": m.get("java_lines"),
                "odin_path": m.get("odin_path"),
                "cycle": False,
                "children": [],
            }
            if key in rendered:
                node["cycle"] = True
                return node
            rendered.add(key)
            if depth > 64:
                node["cycle"] = True
                return node
            # Recurse if this node is red OR sits on a path to a red.
            on_path = key in ancestors
            if st != "red" and not on_path:
                return node
            for child in fetch_call_children(key):
                # Keep the child if:
                #   * it's red (a deeper drill target),
                #   * it's on a path to some red (yellow spine), or
                #   * the parent itself is red (immediate context).
                ck = child["key"]
                cst = child["status"]
                if cst == "red" or ck in ancestors or st == "red":
                    node["children"].append(
                        build(ck, child["edge_kind"], st, depth + 1)
                    )
            return node

        # Top reds: deepest layer (highest number = closest to entry) first.
        top_reds_sorted = sorted(
            top_reds,
            key=lambda k: (
                -(meta_map.get(k, {}).get("layer")
                  if meta_map.get(k, {}).get("layer") is not None else -1),
                k,
            ),
        )
        roots = [build(k, "root", "root", 0) for k in top_reds_sorted]
        return {"summary": summary, "roots": roots}
    finally:
        conn.close()



class _Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path in ("/", "/index.html"):
            self._send(200, _INDEX_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return
        if self.path == "/api/tree":
            try:
                body = json.dumps(_build_tree()).encode("utf-8")
            except Exception as exc:  # pragma: no cover - debug aid
                body = json.dumps({"error": repr(exc)}).encode("utf-8")
                self._send(500, body, "application/json")
                return
            self._send(200, body, "application/json")
            return
        if self.path == "/api/next":
            try:
                conn = _open_db()
                _next_task._ensure_test_status(conn)
                payload = _next_task.pick_next(conn)
                conn.close()
                body = json.dumps(payload).encode("utf-8")
            except Exception as exc:  # pragma: no cover - debug aid
                body = json.dumps({"error": repr(exc)}).encode("utf-8")
                self._send(500, body, "application/json")
                return
            self._send(200, body, "application/json")
            return
        self._send(404, b"not found", "text/plain")

    def log_message(self, fmt: str, *args) -> None:  # silence default access log
        return


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--port", type=int, default=8765)
    p.add_argument("--host", default="127.0.0.1")
    args = p.parse_args(argv)
    srv = ThreadingHTTPServer((args.host, args.port), _Handler)
    print(f"serving http://{args.host}:{args.port}/  (db={_DB})", file=sys.stderr)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        srv.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
