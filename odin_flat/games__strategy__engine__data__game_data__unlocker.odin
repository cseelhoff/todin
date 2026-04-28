package game

// Port of inner interface games.strategy.engine.data.GameData.Unlocker.
// In Java this is a functional interface extending Closeable; instances are
// produced by GameData.acquireLock(Lock) and simply call lock.unlock() on
// close(). We model it as a small struct holding the user data (lock pointer)
// and a close procedure.

Game_Data_Unlocker :: struct {
	user_data: rawptr,
	close:     proc(user_data: rawptr),
}
