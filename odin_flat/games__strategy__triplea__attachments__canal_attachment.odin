package game

Canal_Attachment :: struct {
	using parent: Default_Attachment,
	canal_name: string,
	land_territories: map[^Territory]struct{},
	excluded_units: map[^Unit_Type]struct{},
	can_not_move_through_during_combat_move: bool,
}
