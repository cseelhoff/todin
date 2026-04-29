package game

// games.strategy.engine.data.Territory
//
// extends NamedAttachable implements NamedUnitHolder, Comparable<Territory>

Territory :: struct {
	using named_attachable: Named_Attachable,
	water:                bool,
	owner:                ^Game_Player,
	unit_collection:      ^Unit_Collection,
	territory_attachment: ^Territory_Attachment,
}
