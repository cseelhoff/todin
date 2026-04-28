# Resume prompt — TripleA Java→Odin port

> **Copy the entire "PROMPT" block below and paste it into a fresh chat
> any time the context window fills up. It is idempotent: it always
> queries `port.sqlite` for the next unfinished work and dispatches one
> subagent per entity. Re-run until both `structs` and `methods` are
> 100% `is_implemented = 1`.**

---

## PROMPT (copy from here to end of file)

You are the **orchestrator** for the TripleA Java→Odin port. The
authoritative tracker is `port.sqlite` at the workspace root
(`/home/caleb/todin`). The full rules live in
[`llm-instructions.md`](./llm-instructions.md) — read that file once
at the start of the session, then proceed.

### Your loop (run until done, then call `task_complete`)

1. **Sanity check** the workspace and load progress notes:
   - View `/memories/session/triplea-port-progress.md` (create it if
     missing — see template at the bottom of this file).
   - Run:
     ```sh
     sqlite3 port.sqlite "SELECT \
       (SELECT COUNT(*) FROM structs) AS s_total, \
       (SELECT COUNT(*) FROM structs WHERE is_implemented=1) AS s_done, \
       (SELECT COUNT(*) FROM methods) AS m_total, \
       (SELECT COUNT(*) FROM methods WHERE is_implemented=1) AS m_done;"
     ```
   - Print one line: `phase A: s_done/s_total, phase B: m_done/m_total`.

2. **Pick the active phase**:
   - If `s_done < s_total` → **Phase A** (structs).
   - Else if `m_done < m_total` → **Phase B** (methods).
   - Else → **Phase C** (snapshot validation): compile + run the
     snapshot tests per `llm-instructions.md` §Phase C, then
     `task_complete`.

3. **Pull the next batch (12 entities)** from the DB.

   Phase A query:
   ```sh
   sqlite3 -separator '|' port.sqlite "
     SELECT struct_key, java_file_path, odin_file_path, struct_layer
     FROM structs WHERE is_implemented = 0
     ORDER BY struct_layer, scc_id, struct_key
     LIMIT 12;"
   ```

   Phase B query (NEVER cross a `method_layer` boundary in one batch —
   trim the batch at the layer change):
   ```sh
   sqlite3 -separator '|' port.sqlite "
     SELECT method_key, owner_struct_key, java_file_path, odin_file_path, method_layer
     FROM methods WHERE is_implemented = 0
     ORDER BY method_layer, method_key
     LIMIT 12;"
   ```

4. **Dispatch one subagent per row, in parallel**, using `runSubagent`
   with `agentName` omitted (the default coding subagent — `Explore`
   cannot write files). Use the prompt templates in the next section.
   All 12 calls go in a single tool-call block.

5. **Collect results.** Each subagent returns one line:
   `done: <referenced types>` or `blocked: <reason>`.

6. **Update the database** for every `done:` row in a single
   `sqlite3 ... "UPDATE ... WHERE ... IN (...)"` call. Remember to
   backslash-escape `$` in inner-class keys
   (e.g. `'struct:foo.Bar\$Baz'`). For `blocked:` rows, log the
   reason and leave `is_implemented = 0` (you'll revisit on the
   next loop iteration).

7. **Update session memory** (`/memories/session/triplea-port-progress.md`)
   with the new counters and any blockers.

8. **Loop back to step 1** until the phase changes or the context
   feels tight (~70%+ used). When stopping mid-port:
   - Save final counters into session memory.
   - Print: `Stopping at <s_done>/<s_total> structs, <m_done>/<m_total>
     methods. Re-run resume-prompt.md to continue.`
   - Call `task_complete`.

### Subagent dispatch templates

Every subagent prompt MUST tell the subagent:

- It is doing **one** entity. The orchestrator owns the DB; the
  subagent must NOT update `port.sqlite`.
- All previously-needed Odin dependencies are **already implemented**
  in `odin_flat/` (Phase A finishes before Phase B; methods are
  ordered by `method_layer`). The subagent should **reference
  existing types/procs**, not re-define them. If the subagent thinks
  a referenced type is missing, it should:
  1. Check `grep -l "<Type_Name> ::" /home/caleb/todin/odin_flat/`.
  2. If found, use it.
  3. Only if genuinely absent, return `blocked: missing <Type_Name>`.
  This protects against re-implementation drift.
- Forward references to types defined later in `odin_flat/` are fine
  — Odin resolves them at the package level.
- Read `/home/caleb/todin/llm-instructions.md` at the start of the
  subagent's work for the rules summary.
- Return exactly one line: `done: <comma-separated types referenced>`
  or `blocked: <reason>`.

#### Phase A subagent prompt template (struct)

```
Port one Java struct/interface/enum to Odin per
/home/caleb/todin/llm-instructions.md (read it first; obey all rules).

Entity: <STRUCT_KEY>
Java source: <JAVA_FILE_PATH>
Odin target: <ODIN_FILE_PATH>

Phase A: TYPE only — fields + nested types. NO method bodies.

Rules:
- Replace the existing TODO header with `package game`.
- Type name: PascalCase_with_underscores derived from the file name.
- Java primitives: boolean→bool, int→i32, long→i64, float→f32,
  double→f64, String→string, BigDecimal→f64.
- Cross-struct refs become `^Type` pointers. NO `*_Id` types.
- Collections: List<T>→[dynamic]^T, Map<K,V>→map[K]V,
  Set<T>→map[^T]struct{}.
- Single inheritance: `using parent: Parent` as the FIRST field.
- Interface with no fields → `Type_Name :: struct {}`.
- Java enum → Odin `enum`.
- Inner classes get their OWN file (already provisioned in
  odin_flat/) — do not include them inline.
- Functional interfaces → Odin `proc(...)` type literals as fields.
- Java implementing `Named` → embed `using named: Named` (Named is
  the 2-level form already on disk).

Already-ported dependencies: every type at a lower struct_layer is
ALREADY implemented in /home/caleb/todin/odin_flat/. Reference them;
do NOT re-define them. If you believe a referenced type is missing,
grep odin_flat/ first; only if truly absent, return
`blocked: missing <Type_Name>`.

DO NOT update port.sqlite. The orchestrator handles that.

Return exactly one line:
  done: <comma-separated cross-struct types referenced, or "none">
or:
  blocked: <reason>
```

#### Phase B subagent prompt template (method)

```
Port one Java method to Odin per /home/caleb/todin/llm-instructions.md
(read it first; obey all rules).

Entity: <METHOD_KEY>
Owner struct: <OWNER_STRUCT_KEY>
Java source: <JAVA_FILE_PATH> (focus on the method matching METHOD_KEY)
Odin target: <ODIN_FILE_PATH> (append the proc to this file)

Phase B: METHOD body. The owner struct already exists in the Odin
file with `package game` header — do NOT redefine it.

Rules:
- Instance Foo.bar(int x) → `foo_bar :: proc(self: ^Foo, x: i32) -> ...`.
- Static Foo.baz(...)     → `foo_baz :: proc(...) -> ...`.
- Constructor new Foo(...) → `foo_new :: proc(...) -> ^Foo`.
- `obj.method(args)` calls become `foo_method(obj, args)`.
- Functional interface → Odin `proc` type literal.
- No reflection. No stubs. No `panic("not impl")`. No `// TODO`. No
  logging-only stub. The body must be REAL behavior or return
  `blocked: <reason>`.

Already-ported dependencies: every method at a lower `method_layer`
is ALREADY implemented in /home/caleb/todin/odin_flat/, and ALL
structs are implemented (Phase A is complete). Reference existing
procs and types; do NOT re-implement them. If a referenced proc is
missing, run:
  grep -l "<proc_name> :: proc" /home/caleb/todin/odin_flat/
to confirm. Only if truly absent, return
`blocked: missing <proc_name>`.

DO NOT update port.sqlite.

Return exactly one line:
  done: <comma-separated procs/types referenced, or "none">
or:
  blocked: <reason>
```

### Session memory template (`/memories/session/triplea-port-progress.md`)

Create on first run if missing:

```md
# TripleA Java→Odin port progress

Workspace: /home/caleb/todin

## Phase A — structs
- Done: <S_DONE>/<S_TOTAL>
- Last batch ended at: <last struct_key>

## Phase B — methods
- Done: <M_DONE>/<M_TOTAL>
- Current method_layer: <N>

## Blocked entries
- (one per line: <key> — <reason>)
```

### Stop conditions (when to exit the loop)

- All structs and all methods `is_implemented = 1` AND Phase C
  passes 52/52 snapshot pairs → call `task_complete` with a final
  summary.
- A subagent reports a harness-level blocker (it asks to edit
  `triplea/conversion/odin_tests/test_common/`) → STOP. Per
  `llm-instructions.md`, fix `scripts/patch_triplea.py` and re-run
  bootstrap. Document the change in session memory before stopping.
- Context budget feels tight (~70% used) → save progress and
  `task_complete` with the resume instruction.

### Things you must NOT do

- Do NOT write Odin code yourself — always delegate to a subagent.
- Do NOT use the `Explore` agent for translation (read-only).
- Do NOT mark entities `is_implemented = 1` based on a `blocked:`
  reply.
- Do NOT cross `method_layer` boundaries within a single parallel
  batch in Phase B.
- Do NOT modify the snapshot harness or generated `.odin` test
  files under `triplea/conversion/odin_tests/`.
- Do NOT bypass safety flags (`--no-verify`, etc.) in any git
  operations.

---

(end of PROMPT)
