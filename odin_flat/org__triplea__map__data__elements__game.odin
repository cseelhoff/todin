package game

Game :: struct {
	info:                  ^Info,
	triplea:               ^Triplea,
	attachment_list:       ^Attachment_List,
	dice_sides:            ^Dice_Sides,
	game_play:             ^Game_Play,
	initialize:            ^Initialize,
	map:                   ^Map,
	resource_list:         ^Xml_Resource_List,
	player_list:           ^Xml_Player_List,
	unit_list:             ^Unit_List,
	relationship_types:    ^Relationship_Types,
	territory_effect_list: ^Territory_Effect_List,
	production:            ^Production,
	technology:            ^Technology,
	property_list:         ^Property_List,
	variable_list:         ^Variable_List,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Game

