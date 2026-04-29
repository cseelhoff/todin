package game

// JDK shim: java.util.UUID
//
// The TripleA port uses Uuid as a 16-byte value (canonical [16]u8) so it
// can be used directly as a map key. The authoritative definition lives
// in odin_flat/games__strategy__engine__data__game_data.odin so all
// callers share the same layout. This file remains as a placeholder
// owned by the JDK shim package path; it intentionally adds no
// declarations.
