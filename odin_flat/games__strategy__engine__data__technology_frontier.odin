package game

Technology_Frontier :: struct {
	using game_data_component: Game_Data_Component,
	techs: [dynamic]^Tech_Advance,
	name:  string,
}

technology_frontier_get_techs :: proc(self: ^Technology_Frontier) -> [dynamic]^Tech_Advance {
	return self.techs
}

technology_frontier_is_empty :: proc(self: ^Technology_Frontier) -> bool {
	return len(self.techs) == 0
}

// Java: TechnologyFrontier#iterator() — returns getTechs().iterator().
// Odin convention (see production_frontier_iterator, game_map_iterator):
// expose the backing list and let callers `for t in technology_frontier_iterator(tf)`.
technology_frontier_iterator :: proc(self: ^Technology_Frontier) -> [dynamic]^Tech_Advance {
	return technology_frontier_get_techs(self)
}

technology_frontier_get_name :: proc(self: ^Technology_Frontier) -> string {
	return self.name
}

technology_frontier_get_advance_by_name :: proc(self: ^Technology_Frontier, name: string) -> ^Tech_Advance {
	for ta in self.techs {
		if ta.named.base.name == name {
			return ta
		}
	}
	return nil
}

// Java: TechnologyFrontier#lambda$getAdvanceByName$1 — predicate
// `ta -> ta.getName().equals(name)` from `getAdvanceByName(name)`.
technology_frontier_lambda_get_advance_by_name_1 :: proc(name: string, advance: ^Tech_Advance) -> bool {
	return advance.name == name
}

technology_frontier_get_advance_by_property :: proc(self: ^Technology_Frontier, property: string) -> ^Tech_Advance {
	for ta in self.techs {
		if tech_advance_get_property(ta) == property {
			return ta
		}
	}
	return nil
}
