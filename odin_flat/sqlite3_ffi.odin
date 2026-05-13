package game

// Minimal C-FFI binding to libsqlite3.
//
// Odin's `core` and `vendor` libraries do not include a SQLite wrapper,
// so we declare just the handful of functions the precache needs and
// link against the system libsqlite3 (`-lsqlite3`).
//
// Only used by the battle precache code, which itself is gated behind
// the `BATTLE_PRECACHE_ENABLED` compile-time flag. When that flag is
// false, no caller pulls these symbols in, so the linker drops them.

import "core:c"

// sqlite3_open returns SQLITE_OK on success, otherwise an error code.
SQLITE_OK    :: 0
SQLITE_ERROR :: 1
SQLITE_BUSY  :: 5
SQLITE_ROW   :: 100
SQLITE_DONE  :: 101

// sqlite3_bind_text destructor sentinels.
//   SQLITE_STATIC   ((sqlite3_destructor_type)0)   — value lives forever.
//   SQLITE_TRANSIENT ((sqlite3_destructor_type)-1) — make a copy now.
SQLITE_TRANSIENT :: rawptr(~uintptr(0))

Sqlite3      :: distinct rawptr
Sqlite3_Stmt :: distinct rawptr

foreign import sqlite3 "system:sqlite3"

// We deliberately bind under explicitly-prefixed Odin names (`sqlite3_*`)
// so they cannot shadow Odin builtins like `free`/`open`.
foreign sqlite3 {
	sqlite3_open         :: proc "c" (filename: cstring, db: ^Sqlite3) -> c.int ---
	sqlite3_close        :: proc "c" (db: Sqlite3) -> c.int ---
	sqlite3_exec         :: proc "c" (db: Sqlite3, sql: cstring, callback: rawptr, arg: rawptr, errmsg: ^cstring) -> c.int ---
	sqlite3_prepare_v2   :: proc "c" (db: Sqlite3, zSql: cstring, nByte: c.int, ppStmt: ^Sqlite3_Stmt, pzTail: ^cstring) -> c.int ---
	sqlite3_step         :: proc "c" (stmt: Sqlite3_Stmt) -> c.int ---
	sqlite3_finalize     :: proc "c" (stmt: Sqlite3_Stmt) -> c.int ---
	sqlite3_reset        :: proc "c" (stmt: Sqlite3_Stmt) -> c.int ---
	sqlite3_clear_bindings :: proc "c" (stmt: Sqlite3_Stmt) -> c.int ---

	sqlite3_bind_text    :: proc "c" (stmt: Sqlite3_Stmt, idx: c.int, text: cstring, n: c.int, destructor: rawptr) -> c.int ---
	sqlite3_bind_int     :: proc "c" (stmt: Sqlite3_Stmt, idx: c.int, val: c.int) -> c.int ---
	sqlite3_bind_int64   :: proc "c" (stmt: Sqlite3_Stmt, idx: c.int, val: i64) -> c.int ---
	sqlite3_bind_null    :: proc "c" (stmt: Sqlite3_Stmt, idx: c.int) -> c.int ---

	sqlite3_column_text  :: proc "c" (stmt: Sqlite3_Stmt, col: c.int) -> cstring ---
	sqlite3_column_int   :: proc "c" (stmt: Sqlite3_Stmt, col: c.int) -> c.int ---
	sqlite3_column_int64 :: proc "c" (stmt: Sqlite3_Stmt, col: c.int) -> i64 ---

	sqlite3_errmsg       :: proc "c" (db: Sqlite3) -> cstring ---
	sqlite3_free         :: proc "c" (p: rawptr) ---
}
