package game

// JDK shim: synchronous in-process implementation; the AI snapshot
// harness is single-threaded, so the lock is a no-op marker.
Reentrant_Read_Write_Lock :: struct {}

reentrant_read_write_lock_new :: proc() -> ^Reentrant_Read_Write_Lock {
	return new(Reentrant_Read_Write_Lock)
}
