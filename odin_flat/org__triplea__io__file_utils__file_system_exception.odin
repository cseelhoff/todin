package game

// Ported from org.triplea.io.FileUtils.FileSystemException
// Runtime exception wrapping an IOException with a hint to check
// available disk space.

File_System_Exception :: struct {
	message: string,
	cause:   string,
}

