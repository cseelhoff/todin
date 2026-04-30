package game

// Port of inner interface games.strategy.engine.data.GameData.Unlocker.
// In Java this is a functional interface extending Closeable; instances are
// produced by GameData.acquireLock(Lock) and call lock.unlock() on close().
// The Odin port is single-threaded (Game_Data has no read_write_lock field),
// so close() reduces to a no-op, mirroring acquire_read_lock /
// acquire_write_lock.

Game_Data_Unlocker :: struct {
	game_data: ^Game_Data,
}

// games.strategy.engine.data.GameData$Unlocker#close()
//
// Java body (lambda from acquireLock): lock.unlock()
// This unlocker is bound to the read lock from acquireReadLock(); since the
// Odin port has no real lock, releasing the read lock is a no-op.
game_data_unlocker_close :: proc(self: ^Game_Data_Unlocker) {
	_ = self
}
