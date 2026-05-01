package game

Technology_Frontier :: struct {
	using game_data_component: Game_Data_Component,
	techs: [dynamic]^Tech_Advance,
	name:  string,
}

// Java: TechnologyFrontier(String name, GameData data) — primary constructor.
technology_frontier_new :: proc(name: string, data: ^Game_Data) -> ^Technology_Frontier {
	self := new(Technology_Frontier)
	self.game_data_component = make_Game_Data_Component(data)
	self.name = name
	self.techs = make([dynamic]^Tech_Advance)
	return self
}

// Java: TechnologyFrontier(TechnologyFrontier other) — copy constructor.
technology_frontier_new_copy :: proc(other: ^Technology_Frontier) -> ^Technology_Frontier {
	self := new(Technology_Frontier)
	self.game_data_component = make_Game_Data_Component(
		game_data_component_get_data(&other.game_data_component),
	)
	self.name = other.name
	self.techs = make([dynamic]^Tech_Advance, 0, len(other.techs))
	for t in other.techs {
		append(&self.techs, t)
	}
	return self
}

// Java: TechnologyFrontier#lambda$getAdvanceByProperty$0 — predicate
// `ta -> ta.getProperty().equals(property)` from `getAdvanceByProperty(property)`.
technology_frontier_lambda_get_advance_by_property_0 :: proc(property: string, ta: ^Tech_Advance) -> bool {
	return tech_advance_get_property(ta) == property
}

// Java: TechnologyFrontier#reorderTechsToMatchGameTechsOrder() — sorts this
// frontier's techs to match the order they appear in
// gameData.getTechnologyFrontier().getTechs(). When data is null (detached
// frontier) this is a no-op, mirroring Java's null guard.
technology_frontier_reorder_techs_to_match_game_techs_order :: proc(self: ^Technology_Frontier) {
	game_data := game_data_component_get_data(&self.game_data_component)
	if game_data == nil {
		return
	}
	master := game_data_get_technology_frontier(game_data)
	if master == nil {
		return
	}
	master_techs := master.techs
	index_of :: proc(list: [dynamic]^Tech_Advance, t: ^Tech_Advance) -> int {
		for x, i in list {
			if x == t {
				return i
			}
		}
		return -1
	}
	// Insertion sort by index in master_techs (mirrors Java
	// Comparator.comparingInt(masterTechs::indexOf)).
	n := len(self.techs)
	for i in 1 ..< n {
		j := i
		for j > 0 && index_of(master_techs, self.techs[j - 1]) > index_of(master_techs, self.techs[j]) {
			tmp := self.techs[j - 1]
			self.techs[j - 1] = self.techs[j]
			self.techs[j] = tmp
			j -= 1
		}
	}
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
