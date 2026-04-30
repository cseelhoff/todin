package game

Installed_Maps_Listing_Installed_Maps_Listing_Builder :: struct {
	installed_maps: [dynamic]^Installed_Map,
}

make_Installed_Maps_Listing_Installed_Maps_Listing_Builder :: proc() -> Installed_Maps_Listing_Installed_Maps_Listing_Builder {
	return Installed_Maps_Listing_Installed_Maps_Listing_Builder{}
}
