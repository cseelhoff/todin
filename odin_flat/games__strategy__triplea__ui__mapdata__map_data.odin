package game

// games.strategy.triplea.ui.mapdata.MapData
//
// JDK boundary: java.awt.{Point, Polygon, Image} are modeled as opaque ^u8
// pointers. java.util.Properties is modeled as map[string]string.

Map_Data :: struct {
	player_colors:             ^Player_Colors,
	ignore_transforming_units: map[string]struct{},
	place:                     map[string]Tuple([dynamic]^u8, bool),
	polys:                     map[string][dynamic]^u8,
	centers:                   map[string]^u8,
	vc_place:                  map[string]^u8,
	blockade_place:            map[string]^u8,
	convoy_place:              map[string]^u8,
	comment_place:             map[string]^u8,
	pu_place:                  map[string]^u8,
	name_place:                map[string]^u8,
	kamikaze_place:            map[string]^u8,
	capitol_place:             map[string]^u8,
	contains:                  map[string]map[string]struct{},
	map_properties:            map[string]string,
	territory_effects:         map[string][dynamic]^u8,
	undrawn_units:             map[string]struct{},
	undrawn_territories_names: map[string]struct{},
	decorations:               map[^u8][dynamic]^u8,
	territory_name_images:     map[string]^u8,
	effect_images:             map[string]^u8,
	vc_image:                  ^u8,
	blockade_image:            ^u8,
	error_image:               ^u8,
	warning_image:             ^u8,
	loader:                    ^Resource_Loader,
}
