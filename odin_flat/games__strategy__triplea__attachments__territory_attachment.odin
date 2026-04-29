package game

Territory_Attachment :: struct {
	using default_attachment: Default_Attachment,
	capital: string,
	original_factory: bool,
	production: i32,
	victory_city: i32,
	is_impassable: bool,
	original_owner: ^Game_Player,
	convoy_route: bool,
	convoy_attached: map[^Territory]struct{},
	change_unit_owners: [dynamic]^Game_Player,
	capture_unit_on_entering_by: [dynamic]^Game_Player,
	naval_base: bool,
	air_base: bool,
	kamikaze_zone: bool,
	unit_production: i32,
	blockade_zone: bool,
	territory_effect: [dynamic]^Territory_Effect,
	when_captured_by_goes_to: [dynamic]string,
	resources: ^Resource_Collection,
}
