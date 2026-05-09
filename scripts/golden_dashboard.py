#!/usr/bin/env python3
"""Phase 2 acceptance gate of golden_testing_plan.md: dashboard for Tier-A
golden testing progress.

Stdlib-only.

Usage:
    python3 scripts/golden_dashboard.py --once     # one-shot text report
    python3 scripts/golden_dashboard.py --port 8766  # HTTP dashboard

The text report (--once) is the single command that satisfies the
Phase 1 acceptance gate (§10 of the plan).
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


def collect_summary() -> dict:
    con = sqlite3.connect(_DB)
    con.row_factory = sqlite3.Row

    fixtures_total = con.execute("SELECT COUNT(*) FROM golden_fixtures").fetchone()[0]
    fixtures_by_status = dict(con.execute(
        "SELECT COALESCE(last_replay_status,'unknown'), COUNT(*) "
        "FROM golden_fixtures GROUP BY last_replay_status"
    ).fetchall())

    capture_state_counts = dict(con.execute(
        "SELECT COALESCE(capture_state,'NULL'), COUNT(*) "
        "FROM methods WHERE is_implemented=1 AND is_abstract=0 AND is_test_harness=0 "
        "GROUP BY capture_state"
    ).fetchall())

    tier_a_status = dict(con.execute(
        "SELECT status, COUNT(*) FROM test_status WHERE test_tier='A' GROUP BY status"
    ).fetchall())

    by_class = con.execute("""
        SELECT
            substr(m.owner_struct_key, 8) AS klass,
            COUNT(DISTINCT m.method_key) AS impl_methods,
            SUM(CASE WHEN m.capture_state='captured'  THEN 1 ELSE 0 END) AS captured,
            SUM(CASE WHEN m.capture_state='generated' THEN 1 ELSE 0 END) AS generated,
            SUM(CASE WHEN ts.test_tier='A' AND ts.status='green' THEN 1 ELSE 0 END) AS green,
            SUM(CASE WHEN ts.test_tier='A' AND ts.status='red'   THEN 1 ELSE 0 END) AS red
        FROM methods m
        LEFT JOIN test_status ts ON ts.entity_key = m.method_key
        WHERE m.is_implemented=1 AND m.is_abstract=0 AND m.is_test_harness=0
          AND m.capture_state != 'skip'
        GROUP BY klass
        ORDER BY (green + red) DESC, generated DESC, captured DESC
    """).fetchall()

    fixture_aggs = con.execute("""
        SELECT m.method_key, COUNT(*) AS n,
               SUM(CASE WHEN gf.last_replay_status='pass' THEN 1 ELSE 0 END) AS pass_n,
               SUM(CASE WHEN gf.last_replay_status='fail' THEN 1 ELSE 0 END) AS fail_n
        FROM golden_fixtures gf
        JOIN methods m ON m.method_key = gf.method_key
        GROUP BY m.method_key
        ORDER BY n DESC
        LIMIT 20
    """).fetchall()

    con.close()
    return {
        "fixtures_total": fixtures_total,
        "fixtures_by_status": fixtures_by_status,
        "capture_state_counts": capture_state_counts,
        "tier_a_status": tier_a_status,
        "by_class": [dict(r) for r in by_class],
        "fixture_aggs": [dict(r) for r in fixture_aggs],
    }


def render_text(summary: dict) -> str:
    out = []
    out.append("=" * 70)
    out.append("Tier-A golden testing dashboard (port.sqlite)")
    out.append("=" * 70)
    out.append("")
    out.append(f"  total fixtures:              {summary['fixtures_total']}")
    out.append(f"  fixtures by replay status:   {summary['fixtures_by_status']}")
    out.append(f"  methods.capture_state:       {summary['capture_state_counts']}")
    out.append(f"  test_status (test_tier='A'): {summary['tier_a_status']}")
    out.append("")
    out.append("Per-class progress (only classes with capture in flight):")
    out.append(f"  {'class':<60} {'impl':>5} {'cap':>4} {'gen':>4} {'green':>5} {'red':>3}")
    for r in summary["by_class"]:
        out.append(
            f"  {r['klass']:<60} "
            f"{r['impl_methods']:>5} {r['captured']:>4} {r['generated']:>4} "
            f"{r['green']:>5} {r['red']:>3}"
        )
    if not summary["by_class"]:
        out.append("  (none yet — run scripts/bb_agent_whitelist.py add <FQCN>)")
    out.append("")
    if summary["fixture_aggs"]:
        out.append("Top methods by fixture count:")
        for a in summary["fixture_aggs"]:
            mk = a["method_key"]
            short = mk.split("#", 1)[-1].split("(", 1)[0]
            out.append(f"  {short:<55}  n={a['n']:>4}  pass={a['pass_n']:>4}  fail={a['fail_n']:>3}")
    return "\n".join(out)


PAGE = """<!doctype html><html><head><meta charset=utf-8>
<title>Golden Testing Dashboard</title>
<style>body{font:14px monospace;padding:1em}td,th{padding:.2em .8em}</style>
</head><body><pre id=out>loading...</pre>
<script>
async function tick(){
  const r = await fetch('/api/text');
  document.getElementById('out').textContent = await r.text();
  setTimeout(tick, 2500);
}
tick();
</script></body></html>"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(PAGE.encode())
        elif self.path == "/api/text":
            try:
                txt = render_text(collect_summary())
            except Exception as e:
                txt = f"error: {e}"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(txt.encode())
        elif self.path == "/api/json":
            data = json.dumps(collect_summary(), default=str)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(data.encode())
        else:
            self.send_response(404); self.end_headers()

    def log_message(self, *a, **kw):
        pass


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--once", action="store_true",
                    help="Print one-shot text report and exit")
    ap.add_argument("--port", type=int, default=8766)
    args = ap.parse_args()
    if args.once:
        print(render_text(collect_summary()))
        return 0
    print(f"Tier-A golden dashboard at http://localhost:{args.port}/")
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
