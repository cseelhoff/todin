package game

Game :: struct {
	info:                  ^Info,
	triplea:               ^Triplea,
	attachment_list:       ^Attachment_List,
	dice_sides:            ^Dice_Sides,
	game_play:             ^Game_Play,
	initialize:            ^Initialize,
        map_element:           ^Map,
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

game_get_info :: proc(self: ^Game) -> ^Info {
        return self.info
}

game_get_triplea :: proc(self: ^Game) -> ^Triplea {
        return self.triplea
}

game_get_attachment_list :: proc(self: ^Game) -> ^Attachment_List {
        return self.attachment_list
}

game_get_dice_sides :: proc(self: ^Game) -> ^Dice_Sides {
        return self.dice_sides
}

game_get_game_play :: proc(self: ^Game) -> ^Game_Play {
        return self.game_play
}

game_get_initialize :: proc(self: ^Game) -> ^Initialize {
        return self.initialize
}

game_get_map :: proc(self: ^Game) -> ^Map {
        return self.map_element
}

game_get_resource_list :: proc(self: ^Game) -> ^Xml_Resource_List {
        return self.resource_list
}

game_get_player_list :: proc(self: ^Game) -> ^Xml_Player_List {
        return self.player_list
}

game_get_unit_list :: proc(self: ^Game) -> ^Unit_List {
        return self.unit_list
}

game_get_relationship_types :: proc(self: ^Game) -> ^Relationship_Types {
        return self.relationship_types
}

game_get_territory_effect_list :: proc(self: ^Game) -> ^Territory_Effect_List {
        return self.territory_effect_list
}

game_get_production :: proc(self: ^Game) -> ^Production {
        return self.production
}

game_get_technology :: proc(self: ^Game) -> ^Technology {
        return self.technology
}

game_get_property_list :: proc(self: ^Game) -> ^Property_List {
        return self.property_list
}

game_get_variable_list :: proc(self: ^Game) -> ^Variable_List {
        return self.variable_list
}
