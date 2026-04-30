package game

Map_Download_Item :: struct {
	download_url:                  string,
	preview_image_url:             string,
	map_name:                      string,
	last_commit_date_epoch_milli:  i64,
	description:                   string,
	map_tags:                      [dynamic]^Map_Tag,
	download_size_in_bytes:        i64,
}
// Java owners covered by this file:
//   - org.triplea.http.client.maps.listing.MapDownloadItem

