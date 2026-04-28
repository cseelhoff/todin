# triplea-port-bootstrap

A reproducible toolchain that takes an upstream
[TripleA](https://github.com/triplea-game/triplea) checkout and produces:

1. **`port.sqlite`** — a SQLite database with one row per Java class,
   interface, enum, and method that runs at game time, layered by
   dependency depth, with a column tracking implementation status.
2. **`odin_flat/*.odin`** — one blank Odin source file per Java owner
   class, named to match the database, ready for the porter to fill in.
3. A trace of what the running game actually executes (zero-miss bytecode
   instrumentation via JaCoCo, *not* sampling-based JFR).

The intended use: the resulting database becomes a perfect global
hit-list for an LLM-driven Java→Odin port, with a deterministic
porting order (layer 0 → layer 24) and an authoritative implementation
tracker.

---

## What the pipeline does (one paragraph)

We clone TripleA, inject a small JUnit test (`Ww2v5JacocoRun.java`) into the
smoke-testing module, patch its Gradle file (Groovy or Kotlin DSL — both
supported) so JaCoCo can produce a useful aggregated report, run that test
on the WW2v5_1942_2nd map for several rounds, and capture a JaCoCo XML.
The injected test depends only on stable upstream APIs
(`GameTestUtils.setUpGameWithAis`), so the bootstrap survives upstream
churn (default branch renames, DSL migrations, etc.). We then walk every
compiled `.class` file with `javap` to enumerate every type and method
plus its dependency edges, write that into a SQLite schema, mark the
subset that JaCoCo observed actually executing, and compute layer numbers
via Tarjan SCC condensation + topological depth on two graphs (the full
reference graph and a "what-if ID-based design" graph that drops field-
type edges, leaving only inheritance — the latter is a clean DAG and is
the recommended layout for the Odin port).

---

## Requirements

- Linux (tested on NixOS WSL)
- Internet access (to clone TripleA)
- ~4 GB RAM, ~3 GB disk
- Either:
  - **Nix** with flakes enabled (recommended; pulls JDK 21, Odin, gradle,
    Python, SQLite from a pinned `nixpkgs`), or
  - JDK 21, Python 3.11+, sqlite3, git installed manually. Odin is only
    needed if you intend to compile the produced stubs.

If using Nix:

```
nix develop
```

drops you into a shell with everything in `$PATH`.

---

## Quick start

```sh
nix develop
./bootstrap.sh
```

That's it. Total runtime: ~5 minutes (JaCoCo run dominates).

The script is idempotent — every step skips itself if its output already
exists.

---

## Step-by-step (single-line execution)

If you want to run each step manually (to inspect, to experiment, to
re-run after a code change), the steps are listed below. They use the
same env vars as `bootstrap.sh`. You can prefix any line with `WORK_DIR=...`
to redirect outputs.

### 1. Clone TripleA

```sh
git clone https://github.com/triplea-game/triplea
```

### 2. Patch TripleA's build files

Three edits, all idempotent:
- Inject `templates/Ww2v5JacocoRun.java` into
  `game-app/smoke-testing/src/test/java/org/triplea/portbootstrap/`. This
  is a small JUnit test that runs WW2v5_1942_2nd.xml for `--rounds`
  rounds using only the stable upstream API
  `GameTestUtils.setUpGameWithAis`.
- Append a JaCoCo aggregator block to
  `game-app/smoke-testing/build.gradle.kts` (or `.gradle`,
  auto-detected). Without this, the report is empty.

```sh
python3 scripts/patch_triplea.py --triplea triplea --rounds 8
```

### 3. Compile Java sources

```sh
( cd triplea && ./gradlew --no-daemon compileJava \
    -x checkstyleMain -x checkstyleTest -x pmdMain -x pmdTest )
```

### 4. Extract entities + dependencies via javap

This walks every `.class` file and parses `javap -p -c` output to extract:
- One `struct:fqcn` row per class/interface/enum.
- One `proc:fqcn#name(args)` row per method.
- One edge per `extends`/`implements`/`new`/`invoke*`/`get/putfield`
  reference.

```sh
python3 scripts/extract_entities.py \
    --db port.sqlite --triplea triplea
```

Output: ~12,000–14,000 entities, ~50,000–60,000 dependency edges.

### 5. Run Ww2v5JacocoRun under JaCoCo

```sh
( cd triplea && ./gradlew --no-daemon \
    :game-app:smoke-testing:test \
    --tests "*Ww2v5JacocoRun.run" \
    :game-app:smoke-testing:jacocoTestReport \
    --rerun-tasks \
    -x checkstyleMain -x checkstyleTest -x pmdMain -x pmdTest )
```

This produces `triplea/game-app/smoke-testing/build/jacoco.xml`.

### 6. Apply JaCoCo coverage

Sets `entities.actually_called_in_ai_test = 1` for every class/method
that JaCoCo observed executing.

```sh
python3 scripts/apply_jacoco.py \
    --db port.sqlite \
    --xml triplea/game-app/smoke-testing/build/jacoco.xml
```

### 7. Build the called-only `methods` + `structs` tables

Re-layers using only entities flagged `actually_called_in_ai_test=1`.
Uses Tarjan's algorithm so cycles collapse into single layer-bands.

```sh
python3 scripts/build_called_layered_tables.py --db port.sqlite
```

### 8. ID-based design layering

Re-runs the layering with only the inheritance edges (`extends` /
`implements`). Under the ID-based design — where every cross-struct field
becomes a `*_Id :: distinct u32` — these are the only unbreakable
edges, and the result is a clean DAG (depth ~5, zero cycles).

```sh
python3 scripts/id_design_layering.py --db port.sqlite --triplea triplea
```

### 9. Generate blank `.odin` files

One file per Java owner class, named with snake_case + `__` separators.
Each file gets a TODO header so file-level scans can detect it as
"not yet implemented" until the developer/LLM removes the marker.

```sh
python3 scripts/generate_odin_stubs.py \
    --db port.sqlite --out odin_flat
```

The path is also written to each row's `odin_file_path` column.

---

## Output

After a clean run:

```
$WORK_DIR/
  triplea/                # upstream checkout, patched
  port.sqlite             # the tracker database
  odin_flat/              # one blank .odin per Java class
  jacoco.exec, jacoco.xml # raw coverage artifacts (under triplea/...)
```

Schema highlights:

```sql
-- All entities ever seen (unfiltered)
entities(primary_key, java_file_path, java_lines, odin_file_path,
         layer_number, is_fully_implemented_error_free_no_todo_no_stub,
         included, actually_called_in_ai_test)

-- Edge list
dependencies(primary_key, depends_on_key)

-- Called-only, layered (the canonical hit list for porting)
structs(struct_key, java_file_path, java_lines, odin_file_path,
        is_implemented, struct_layer, scc_id, id_design_layer)

methods(method_key, owner_struct_key, java_file_path, java_lines,
        odin_file_path, is_implemented, method_layer)
```

Two layer columns are present for `structs`:

| column            | graph used         | meaning                                                  |
|-------------------|--------------------|----------------------------------------------------------|
| `struct_layer`    | full reference     | layer with cycles collapsed (will contain a 50-struct band) |
| `id_design_layer` | inheritance only   | layer in the cycle-free what-if DAG (recommended order)  |

Recommended porting order: ascending `id_design_layer`, then ascending
`scc_id`, then alphabetical.

---

## What the LLM does next

Once `port.sqlite` and `odin_flat/` exist, the LLM's job is mechanical.

**The next step after `bootstrap.sh` is to open a fresh chat and paste
the `PROMPT` block from [`resume-prompt.md`](./resume-prompt.md).** That
prompt is idempotent: it queries `port.sqlite` for unfinished work,
dispatches ~12 subagents in parallel (one per entity / `.odin` file),
updates `is_implemented` after each batch, and stops cleanly when the
context window fills. Re-paste the same prompt in a new chat to resume
until both `structs` and `methods` are 100% implemented and Phase C
snapshot validation passes.

What each subagent does:

1. Reads the Java source at `java_file_path`.
2. Translates it to Odin in `odin_file_path` (struct only in Phase A,
   method body in Phase B).
3. References — never re-implements — types/procs already on disk
   under `odin_flat/`; lower-layer entities are guaranteed complete
   before higher layers begin.
4. Reports `done` / `blocked`; the orchestrator updates the database.

Final verification is the snapshot harness: 52 paired before/after
JSON snapshots captured per delegate step during the JaCoCo run.

See [`llm-instructions.md`](./llm-instructions.md) for the full ruleset
and subagent dispatch model, [`resume-prompt.md`](./resume-prompt.md)
for the copy-paste resumable prompt, and [`plan.md`](./plan.md) for
the high-level plan template.

---

## Caveats

- **Coverage represents one seed × one map × one game.** A different RNG
  seed or map will exercise different code paths. To strengthen the
  hit list, run step 5 multiple times with different seeds and OR the
  results together. The schema already supports this: `apply_jacoco.py`
  uses an `UPDATE ... SET = 1`, so re-running with a second XML adds
  newly-covered entities without un-flagging existing ones.
- **`<clinit>`, anonymous inner classes (`Foo$1`), and lambdas
  (`lambda$N$M`) are not first-class entities** in the schema. JaCoCo
  reports them but the entity extractor folds them into their owner
  class. ~5% of JaCoCo's reported method count is unrepresented in
  the database for this reason.
- **The implementation flag is a heuristic** when set en masse — file
  exists ∧ no `FIXME|TODO|stub` marker. Per-symbol resolution requires
  a future pass.
