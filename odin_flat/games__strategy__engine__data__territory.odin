package game

// games.strategy.engine.data.Territory
//
// A map territory (sea or land). Owns its UnitCollection and references the
// optional TerritoryAttachment.

Territory :: struct {
	using named:           Named,
	water:                 bool,
	owner:                 ^Game_Player,
	unit_collection:       ^Unit_Collection,
	territory_attachment:  ^Territory_Attachment,
	neighbors:             [dynamic]^Territory,
}
