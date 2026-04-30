package game

Pro_Territory_Value_Utils_1 :: struct {
	using breadth_first_search_visitor: Breadth_First_Search_Visitor,
	current_distance: i32,
	enemy_capitals_and_factories: map[^Territory]struct{},
	found: map[^Territory]struct{},
}

pro_territory_value_utils_1_visit :: proc(self: ^Breadth_First_Search_Visitor, territory: ^Territory, distance: i32) -> bool {
	this := cast(^Pro_Territory_Value_Utils_1)self
	if _, ok := this.enemy_capitals_and_factories[territory]; ok {
		this.found[territory] = {}
	}
	if distance != this.current_distance {
		this.current_distance = distance
		if !pro_territory_value_utils_1_should_continue_search(this) {
			return false
		}
	}
	return true
}

pro_territory_value_utils_1_new :: proc(enemy_capitals_and_factories: map[^Territory]struct{}, found: map[^Territory]struct{}) -> ^Pro_Territory_Value_Utils_1 {
	self := new(Pro_Territory_Value_Utils_1)
	self.visit = pro_territory_value_utils_1_visit
	self.current_distance = -1
	self.enemy_capitals_and_factories = enemy_capitals_and_factories
	self.found = found
	return self
}

pro_territory_value_utils_1_should_continue_search :: proc(self: ^Pro_Territory_Value_Utils_1) -> bool {
	// MIN_FACTORY_CHECK_DISTANCE = 9 (from ProTerritoryValueUtils)
	return self.current_distance <= 9 || len(self.found) == 0
}

