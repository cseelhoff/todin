package game

Game :: struct {
	info:                  ^Info,
	triplea:               ^Triplea,
	attachment_list:       ^Attachment_List,
	dice_sides:            ^Dice_Sides,
	game_play:             ^Game_Play,
	initialize:            ^Initialize,
        map_element:           ^Map,
	property_list:         ^Property_List,
	variable_list:         ^Variable_List,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Game

