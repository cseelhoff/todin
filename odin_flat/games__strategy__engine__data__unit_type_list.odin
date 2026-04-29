package game

// games.strategy.engine.data.UnitTypeList

Unit_Type_List :: struct {
	using game_data_component: Game_Data_Component,
	unit_types: map[string]^Unit_Type,
	support_rules: map[^Unit_Support_Attachment]struct{},
	support_aa_rules: map[^Unit_Support_Attachment]struct{},
}
