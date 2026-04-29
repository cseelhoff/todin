package game

// Java owners covered by this file:
//   - games.strategy.triplea.ResourceLoader

Resource_Loader :: struct {
	loader:      ^Url_Class_Loader,
	asset_paths: [dynamic]string,
}

