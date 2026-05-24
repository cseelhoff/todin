package game

// Java: games.strategy.triplea.odds.calculator.precache.SqliteBattlePrecacheStore
//
// Persistent SQLite-backed memoisation of Stored_Scenarios. Schema is
// auto-created on open; all operations route through a single live
// connection guarded by a sync.Mutex; write failures are logged but
// never propagate (a failed store is functionally equivalent to a
// cache miss next time).

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import sp "core:path/slashpath"
import "core:strconv"
import "core:strings"
import "core:sync"
import "core:time"

// Bumped together with any incompatible schema change.
SQLITE_BATTLE_PRECACHE_STORE_SCHEMA_VERSION :: 1

Sqlite_Battle_Precache_Store :: struct {
	jdbc_url: string, // diagnostic only — mirrors Java field
	db:       Sqlite3,
	mutex:    sync.Mutex,
}

// Java: openAtFile(Path dbPath) — creates parent dir if missing,
// then delegates to openAtJdbcUrl("jdbc:sqlite:" + abs path).
sqlite_battle_precache_store_open_at_file :: proc(
	db_path: string, allocator := context.allocator,
) -> (^Sqlite_Battle_Precache_Store, bool) {
	parent := sp.dir(db_path, context.temp_allocator)
	if parent != "" && parent != "." {
		if mk_err := os.make_directory(parent); mk_err != nil && !os.is_directory(parent) {
			log.warnf("battle_precache: make_directory(%s) failed: %v", parent, mk_err)
		}
	}
	abs, abs_err := filepath.abs(db_path, context.temp_allocator)
	if abs_err != nil || abs == "" {
		log.warnf("battle_precache: filepath.abs(%s) failed; using db_path as-is", db_path)
		abs = db_path
	}
	log.infof("battle_precache: opening sqlite db at %s", abs)
	jdbc_url := strings.concatenate({"file:", abs}, allocator)
	return sqlite_battle_precache_store_open_at_url(jdbc_url, abs, allocator)
}

// Java: openAtJdbcUrl(String jdbcUrl) — primarily for tests using
// `jdbc:sqlite::memory:`. The Odin port takes a raw SQLite filename
// (or `:memory:`) directly; the `display_url` is the human-facing
// string saved on the struct.
sqlite_battle_precache_store_open_at_url :: proc(
	display_url, sqlite_filename: string, allocator := context.allocator,
) -> (^Sqlite_Battle_Precache_Store, bool) {
	self := new(Sqlite_Battle_Precache_Store, allocator)
	self.jdbc_url = strings.clone(display_url, allocator)

	// Promote `sqlite_filename` out of any temp_allocator backing store
	// the caller used — sqlite3_open keeps no copy, and downstream PRAGMA
	// / DDL calls churn the temp arena enough that the original slice
	// can be overwritten before sqlite3 has finished opening the file.
	stable_filename := strings.clone(sqlite_filename, allocator)
	c_path := strings.clone_to_cstring(stable_filename, context.temp_allocator)
	rc := sqlite3_open(c_path, &self.db)
	if rc != SQLITE_OK {
		log.warnf("sqlite3_open(%s) failed: rc=%d msg=%s", stable_filename, rc, sqlite3_errmsg(self.db))
		if self.db != nil { sqlite3_close(self.db) }
		free(self)
		return nil, false
	}
	if !sqlite_battle_precache_store_apply_pragmas(self) { /* logged, non-fatal */ }
	if !sqlite_battle_precache_store_create_schema_if_missing(self) {
		sqlite3_close(self.db)
		free(self)
		return nil, false
	}
	return self, true
}

// Java: applyPragmas() — WAL + synchronous=NORMAL + temp_store=MEMORY.
@(private = "file")
sqlite_battle_precache_store_apply_pragmas :: proc(
	self: ^Sqlite_Battle_Precache_Store,
) -> bool {
	pragmas := [?]string{
		"PRAGMA journal_mode=WAL",
		"PRAGMA synchronous=NORMAL",
		"PRAGMA temp_store=MEMORY",
	}
	for sql in pragmas {
		if !sqlite_exec(self.db, sql) {
			log.warnf("PRAGMA setup failed for %s: %s", self.jdbc_url, sqlite3_errmsg(self.db))
			return false
		}
	}
	return true
}

// Java: createSchemaIfMissing() — same DDL string-for-string.
@(private = "file")
sqlite_battle_precache_store_create_schema_if_missing :: proc(
	self: ^Sqlite_Battle_Precache_Store,
) -> bool {
	if !sqlite_exec(self.db,
		"CREATE TABLE IF NOT EXISTS scenarios (" +
		"  cache_key TEXT PRIMARY KEY," +
		"  schema_version INTEGER NOT NULL," +
		"  stored_run_count INTEGER NOT NULL," +
		"  created_at INTEGER NOT NULL," +
		"  scenario_json TEXT" +
		")") {
		log.errorf("scenarios DDL failed: %s", sqlite3_errmsg(self.db))
		return false
	}
	if !sqlite_exec(self.db,
		"CREATE TABLE IF NOT EXISTS scenario_results (" +
		"  cache_key TEXT NOT NULL," +
		"  result_idx INTEGER NOT NULL," +
		"  battle_rounds INTEGER NOT NULL," +
		"  who_won INTEGER NOT NULL," +
		"  remaining_attackers TEXT NOT NULL," +
		"  remaining_defenders TEXT NOT NULL," +
		"  PRIMARY KEY (cache_key, result_idx)," +
		"  FOREIGN KEY (cache_key) REFERENCES scenarios(cache_key)" +
		")") {
		log.errorf("scenario_results DDL failed: %s", sqlite3_errmsg(self.db))
		return false
	}
	return true
}

// Java: lookup(cacheKey) -> Optional<StoredScenario>.
//   Returns nil/false on missing key, schema-version mismatch, or any error.
sqlite_battle_precache_store_lookup :: proc(
	self: ^Sqlite_Battle_Precache_Store, cache_key: string,
	allocator := context.allocator,
) -> (^Stored_Scenario, bool) {
	sync.mutex_lock(&self.mutex)
	defer sync.mutex_unlock(&self.mutex)

	stmt: Sqlite3_Stmt
	sql := cstring("SELECT schema_version, stored_run_count, created_at FROM scenarios WHERE cache_key = ?")
	if rc := sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil); rc != SQLITE_OK {
		log.warnf("lookup prepare failed: %s", sqlite3_errmsg(self.db))
		return nil, false
	}
	defer sqlite3_finalize(stmt)

	c_key := strings.clone_to_cstring(cache_key, context.temp_allocator)
	sqlite3_bind_text(stmt, 1, c_key, -1, SQLITE_TRANSIENT)

	rc := sqlite3_step(stmt)
	if rc == SQLITE_DONE {
		return nil, false
	}
	if rc != SQLITE_ROW {
		log.warnf("lookup step failed: %s", sqlite3_errmsg(self.db))
		return nil, false
	}

	schema_version  := i32(sqlite3_column_int(stmt, 0))
	stored_run_count := i32(sqlite3_column_int(stmt, 1))
	created_at       := sqlite3_column_int64(stmt, 2)
	if schema_version != BATTLE_SCENARIO_KEY_SCHEMA_VERSION ||
	   schema_version != SQLITE_BATTLE_PRECACHE_STORE_SCHEMA_VERSION {
		return nil, false
	}

	results, ok := sqlite_battle_precache_store_load_results(self, cache_key, allocator)
	if !ok {
		return nil, false
	}

	stored := new(Stored_Scenario, allocator)
	stored.cache_key                = strings.clone(cache_key, allocator)
	stored.stored_run_count         = stored_run_count
	stored.schema_version           = schema_version
	stored.created_at_epoch_millis  = created_at
	stored.results                  = results
	return stored, true
}

@(private = "file")
sqlite_battle_precache_store_load_results :: proc(
	self: ^Sqlite_Battle_Precache_Store, cache_key: string,
	allocator: runtime.Allocator,
) -> ([dynamic]Stored_Scenario_Result, bool) {
	out := make([dynamic]Stored_Scenario_Result, allocator)
	stmt: Sqlite3_Stmt
	sql := cstring(
		"SELECT battle_rounds, who_won, remaining_attackers, remaining_defenders" +
		" FROM scenario_results WHERE cache_key = ? ORDER BY result_idx",
	)
	if rc := sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil); rc != SQLITE_OK {
		log.warnf("results prepare failed: %s", sqlite3_errmsg(self.db))
		return out, false
	}
	defer sqlite3_finalize(stmt)

	c_key := strings.clone_to_cstring(cache_key, context.temp_allocator)
	sqlite3_bind_text(stmt, 1, c_key, -1, SQLITE_TRANSIENT)

	for {
		rc := sqlite3_step(stmt)
		if rc == SQLITE_DONE { break }
		if rc != SQLITE_ROW {
			log.warnf("results step failed: %s", sqlite3_errmsg(self.db))
			return out, false
		}
		atk_text := sqlite3_column_text(stmt, 2)
		def_text := sqlite3_column_text(stmt, 3)
		append(&out, Stored_Scenario_Result{
			battle_rounds_fought = i32(sqlite3_column_int(stmt, 0)),
			who_won              = composition_codec_decode_who_won(i32(sqlite3_column_int(stmt, 1))),
			remaining_attackers  = composition_codec_decode(string(atk_text), allocator),
			remaining_defenders  = composition_codec_decode(string(def_text), allocator),
		})
	}
	return out, true
}

// Java: store(cacheKey, storedRunCount, results, scenarioJson).
//   Replaces any previous row for the same key. Failures logged + swallowed.
sqlite_battle_precache_store_store :: proc(
	self: ^Sqlite_Battle_Precache_Store,
	cache_key: string,
	stored_run_count: i32,
	results: []Stored_Scenario_Result,
	scenario_json: string,
) {
	sync.mutex_lock(&self.mutex)
	defer sync.mutex_unlock(&self.mutex)

	if !sqlite_exec(self.db, "BEGIN") {
		log.warnf("BEGIN failed: %s", sqlite3_errmsg(self.db))
		return
	}

	c_key := strings.clone_to_cstring(cache_key, context.temp_allocator)

	if !sqlite_battle_precache_store_exec_with_key(self, "DELETE FROM scenario_results WHERE cache_key = ?", c_key) ||
	   !sqlite_battle_precache_store_exec_with_key(self, "DELETE FROM scenarios        WHERE cache_key = ?", c_key) {
		sqlite_exec(self.db, "ROLLBACK")
		return
	}

	// INSERT scenarios
	{
		stmt: Sqlite3_Stmt
		sql := cstring("INSERT INTO scenarios (cache_key, schema_version, stored_run_count, created_at, scenario_json) VALUES (?, ?, ?, ?, ?)")
		if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) != SQLITE_OK {
			log.warnf("scenarios insert prepare failed: %s", sqlite3_errmsg(self.db))
			sqlite_exec(self.db, "ROLLBACK")
			return
		}
		now_ms := i64(time.time_to_unix_nano(time.now())) / 1_000_000
		sqlite3_bind_text(stmt, 1, c_key, -1, SQLITE_TRANSIENT)
		sqlite3_bind_int(stmt, 2, c.int(SQLITE_BATTLE_PRECACHE_STORE_SCHEMA_VERSION))
		sqlite3_bind_int(stmt, 3, c.int(stored_run_count))
		sqlite3_bind_int64(stmt, 4, now_ms)
		if scenario_json == "" {
			sqlite3_bind_null(stmt, 5)
		} else {
			c_json := strings.clone_to_cstring(scenario_json, context.temp_allocator)
			sqlite3_bind_text(stmt, 5, c_json, -1, SQLITE_TRANSIENT)
		}
		if rc := sqlite3_step(stmt); rc != SQLITE_DONE {
			log.warnf("scenarios insert step failed: %s", sqlite3_errmsg(self.db))
			sqlite3_finalize(stmt)
			sqlite_exec(self.db, "ROLLBACK")
			return
		}
		sqlite3_finalize(stmt)
	}

	// INSERT scenario_results — prepared once, rebound per row.
	{
		stmt: Sqlite3_Stmt
		sql := cstring("INSERT INTO scenario_results (cache_key, result_idx, battle_rounds, who_won, remaining_attackers, remaining_defenders) VALUES (?, ?, ?, ?, ?, ?)")
		if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) != SQLITE_OK {
			log.warnf("scenario_results insert prepare failed: %s", sqlite3_errmsg(self.db))
			sqlite_exec(self.db, "ROLLBACK")
			return
		}
		for r, i in results {
			sqlite3_reset(stmt)
			sqlite3_clear_bindings(stmt)
			sqlite3_bind_text(stmt, 1, c_key, -1, SQLITE_TRANSIENT)
			sqlite3_bind_int(stmt, 2, c.int(i))
			sqlite3_bind_int(stmt, 3, c.int(r.battle_rounds_fought))
			sqlite3_bind_int(stmt, 4, c.int(composition_codec_encode_who_won(r.who_won)))

			atk_str := composition_codec_encode(r.remaining_attackers, context.temp_allocator)
			def_str := composition_codec_encode(r.remaining_defenders, context.temp_allocator)
			c_atk := strings.clone_to_cstring(atk_str, context.temp_allocator)
			c_def := strings.clone_to_cstring(def_str, context.temp_allocator)
			sqlite3_bind_text(stmt, 5, c_atk, -1, SQLITE_TRANSIENT)
			sqlite3_bind_text(stmt, 6, c_def, -1, SQLITE_TRANSIENT)

			if rc := sqlite3_step(stmt); rc != SQLITE_DONE {
				log.warnf("scenario_results insert step failed: %s", sqlite3_errmsg(self.db))
				sqlite3_finalize(stmt)
				sqlite_exec(self.db, "ROLLBACK")
				return
			}
		}
		sqlite3_finalize(stmt)
	}

	if !sqlite_exec(self.db, "COMMIT") {
		log.warnf("COMMIT failed: %s", sqlite3_errmsg(self.db))
		sqlite_exec(self.db, "ROLLBACK")
	}
}

@(private = "file")
sqlite_battle_precache_store_exec_with_key :: proc(
	self: ^Sqlite_Battle_Precache_Store, sql: string, c_key: cstring,
) -> bool {
	stmt: Sqlite3_Stmt
	c_sql := strings.clone_to_cstring(sql, context.temp_allocator)
	if sqlite3_prepare_v2(self.db, c_sql, -1, &stmt, nil) != SQLITE_OK {
		log.warnf("prepare(%s) failed: %s", sql, sqlite3_errmsg(self.db))
		return false
	}
	defer sqlite3_finalize(stmt)
	sqlite3_bind_text(stmt, 1, c_key, -1, SQLITE_TRANSIENT)
	if rc := sqlite3_step(stmt); rc != SQLITE_DONE {
		log.warnf("step(%s) failed: %s", sql, sqlite3_errmsg(self.db))
		return false
	}
	return true
}

// Java: close()
sqlite_battle_precache_store_close :: proc(self: ^Sqlite_Battle_Precache_Store) {
	if self == nil { return }
	sync.mutex_lock(&self.mutex)
	defer sync.mutex_unlock(&self.mutex)
	if self.db != nil {
		if rc := sqlite3_close(self.db); rc != SQLITE_OK {
			log.warnf("Failed closing battle precache store at %s: rc=%d", self.jdbc_url, rc)
		}
		self.db = nil
	}
}

// Tiny wrapper around sqlite3_exec that returns ok/!ok and avoids the
// errmsg out-pointer (we read sqlite3_errmsg(db) on failure instead).
@(private = "file")
sqlite_exec :: proc(db: Sqlite3, sql: string) -> bool {
	c_sql := strings.clone_to_cstring(sql, context.temp_allocator)
	rc := sqlite3_exec(db, c_sql, nil, nil, nil)
	return rc == SQLITE_OK
}

//
// CompositionCodec — Java's static-nested SqliteBattlePrecacheStore.CompositionCodec.
// Format per entry: type|owner|hits|count, escaped so ',' '|' '\n' '\\'
// can appear in names.
//   '\\' -> "\\\\"
//   '|'  -> "\\p"
//   '\n' -> "\\n"
// Empty composition encodes as "".
//

// Java: CompositionCodec.encode(UnitComposition)
composition_codec_encode :: proc(
	comp: ^Unit_Composition, allocator := context.allocator,
) -> string {
	if comp == nil || len(comp.entries) == 0 {
		return strings.clone("", allocator)
	}
	sb: strings.Builder
	strings.builder_init(&sb, allocator)
	for e, i in comp.entries {
		if i > 0 { strings.write_byte(&sb, '\n') }
		strings.write_string(&sb, composition_codec_escape(e.unit_type_name, context.temp_allocator))
		strings.write_byte(&sb, '|')
		strings.write_string(&sb, composition_codec_escape(e.owner_name, context.temp_allocator))
		strings.write_byte(&sb, '|')
		fmt.sbprintf(&sb, "%d", e.hits)
		strings.write_byte(&sb, '|')
		fmt.sbprintf(&sb, "%d", e.count)
	}
	return strings.to_string(sb)
}

// Java: CompositionCodec.decode(String)
composition_codec_decode :: proc(
	encoded: string, allocator := context.allocator,
) -> ^Unit_Composition {
	if encoded == "" {
		out := new(Unit_Composition, allocator)
		out.entries = make([dynamic]Unit_Composition_Entry, allocator)
		return out
	}
	entries := make([dynamic]Unit_Composition_Entry, allocator)
	for line in strings.split(encoded, "\n", context.temp_allocator) {
		parts, ok := composition_codec_split_four(line)
		if !ok { continue }
		hits, hits_ok   := strconv.parse_i64(parts[2])
		count, count_ok := strconv.parse_i64(parts[3])
		if !hits_ok || !count_ok { continue }
		append(&entries, Unit_Composition_Entry{
			unit_type_name = composition_codec_unescape(parts[0], allocator),
			owner_name     = composition_codec_unescape(parts[1], allocator),
			hits           = i32(hits),
			count          = i32(count),
		})
	}
	out := new(Unit_Composition, allocator)
	out.entries = entries
	return out
}

@(private = "file")
composition_codec_escape :: proc(s: string, allocator := context.allocator) -> string {
	// '\\' first, then '|' -> "\\p", then '\n' -> "\\n".
	tmp1, _ := strings.replace_all(s,    "\\", "\\\\", allocator)
	tmp2, _ := strings.replace_all(tmp1, "|",  "\\p",  allocator)
	tmp3, _ := strings.replace_all(tmp2, "\n", "\\n",  allocator)
	return tmp3
}

@(private = "file")
composition_codec_unescape :: proc(s: string, allocator := context.allocator) -> string {
	sb: strings.Builder
	strings.builder_init(&sb, allocator)
	i := 0
	for i < len(s) {
		c := s[i]
		if c == '\\' && i + 1 < len(s) {
			n := s[i + 1]
			switch n {
			case '\\': strings.write_byte(&sb, '\\')
			case 'p':  strings.write_byte(&sb, '|')
			case 'n':  strings.write_byte(&sb, '\n')
			case:
				strings.write_byte(&sb, c)
				strings.write_byte(&sb, n)
			}
			i += 2
		} else {
			strings.write_byte(&sb, c)
			i += 1
		}
	}
	return strings.to_string(sb)
}

// Java: splitFour(line) — find 3 unescaped '|' positions.
@(private = "file")
composition_codec_split_four :: proc(line: string) -> ([4]string, bool) {
	pipes: [3]int
	found := 0
	i := 0
	for i < len(line) && found < 3 {
		c := line[i]
		if c == '\\' {
			i += 2 // skip the escaped char
			continue
		}
		if c == '|' {
			pipes[found] = i
			found += 1
		}
		i += 1
	}
	if found != 3 { return [4]string{}, false }
	return [4]string{
		line[:pipes[0]],
		line[pipes[0]+1 : pipes[1]],
		line[pipes[1]+1 : pipes[2]],
		line[pipes[2]+1:],
	}, true
}

// Java: encodeWhoWon(WhoWon) — ATTACKER=0 DEFENDER=1 DRAW=2 NOT_FINISHED=3.
composition_codec_encode_who_won :: proc(w: Stored_Scenario_Who_Won) -> i32 {
	switch w {
	case .ATTACKER:    return 0
	case .DEFENDER:    return 1
	case .DRAW:        return 2
	case .NOT_FINISHED: return 3
	}
	return 3
}

composition_codec_decode_who_won :: proc(v: i32) -> Stored_Scenario_Who_Won {
	switch v {
	case 0: return .ATTACKER
	case 1: return .DEFENDER
	case 2: return .DRAW
	case:   return .NOT_FINISHED
	}
}

