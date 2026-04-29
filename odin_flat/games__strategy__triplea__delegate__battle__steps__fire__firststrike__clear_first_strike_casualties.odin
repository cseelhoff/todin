package game

Clear_First_Strike_Casualties :: struct {
	using parent:   Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	offense_state:  Clear_First_Strike_Casualties_State,
	defense_state:  Clear_First_Strike_Casualties_State,
}

