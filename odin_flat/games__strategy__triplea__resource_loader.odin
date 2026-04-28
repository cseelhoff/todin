package game

// Java owners covered by this file:
//   - games.strategy.triplea.ResourceLoader

Resource_Loader :: struct {
	loader:      rawptr, // java.net.URLClassLoader (opaque in Odin)
	asset_paths: [dynamic]string,
}

