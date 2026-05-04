package game

// Java owner: games.strategy.triplea.ai.pro.ProData

Pro_Data :: struct {
	is_simulation:          bool,
	win_percentage:         f64,
	min_win_percentage:     f64,
	my_capital:             ^Territory,
	my_unit_territories:    [dynamic]^Territory,
	unit_territory_map:     map[^Unit]^Territory,
	unit_value_map:         map[^Unit_Type]i32,
	purchase_options:       ^Pro_Purchase_Option_Map,
	units_to_be_consumed:   map[^Unit]struct {},
	min_cost_per_hit_point: f64,
	pro_ai:                 ^Abstract_Pro_Ai,
	data:                   ^Game_Data,
	player:                 ^Game_Player,
}

pro_data_get_my_capital :: proc(self: ^Pro_Data) -> ^Territory {
	return self.my_capital
}


pro_data_get_data :: proc(self: ^Pro_Data) -> ^Game_Data {
	return self.data
}


pro_data_get_pro_ai :: proc(self: ^Pro_Data) -> ^Abstract_Pro_Ai {
	return self.pro_ai
}

pro_data_get_min_cost_per_hit_point :: proc(self: ^Pro_Data) -> f64 {
	return self.min_cost_per_hit_point
}


pro_data_get_player :: proc(self: ^Pro_Data) -> ^Game_Player {
	return self.player
}


pro_data_get_my_unit_territories :: proc(self: ^Pro_Data) -> [dynamic]^Territory {
	return self.my_unit_territories
}


pro_data_get_pro_territory :: proc(self: ^Pro_Data, move_map: map[^Territory]^Pro_Territory, t: ^Territory) -> ^Pro_Territory {
	move_map := move_map
	if existing, ok := move_map[t]; ok {
		return existing
	}
	created := pro_data_lambda_get_pro_territory_0(self, t, t)
	move_map[t] = created
	return created
}

// Java synthetic: lambda$getProTerritory$0 — body of `k -> new ProTerritory(t, this)`
// captured: this (self), t; lambda parameter: k (unused, the map key)
pro_data_lambda_get_pro_territory_0 :: proc(self: ^Pro_Data, t: ^Territory, k: ^Territory) -> ^Pro_Territory {
	return pro_territory_new(t, self)
}


pro_data_get_units_to_be_consumed :: proc(self: ^Pro_Data) -> map[^Unit]struct {} {
	return self.units_to_be_consumed
}


pro_data_get_unit_territory_map :: proc(self: ^Pro_Data) -> map[^Unit]^Territory {
	return self.unit_territory_map
}

pro_data_is_simulation :: proc(self: ^Pro_Data) -> bool {
	return self.is_simulation
}


pro_data_get_purchase_options :: proc(self: ^Pro_Data) -> ^Pro_Purchase_Option_Map {
	return self.purchase_options
}


pro_data_get_unit_value_map :: proc(self: ^Pro_Data) -> map[^Unit_Type]i32 {
	return self.unit_value_map
}


pro_data_get_unit_territory :: proc(self: ^Pro_Data, unit: ^Unit) -> ^Territory {
	if t, ok := self.unit_territory_map[unit]; ok {
		return t
	}
	return nil
}


pro_data_get_win_percentage :: proc(self: ^Pro_Data) -> f64 {
	return self.win_percentage
}


// games.strategy.triplea.ai.pro.ProData#<init>()
// Java: implicit default constructor; field initializers set the
// defaults below (isSimulation=false, winPercentage=95,
// minWinPercentage=75, myCapital=null, empty collections,
// minCostPerHitPoint=Double.MAX_VALUE).
pro_data_new :: proc() -> ^Pro_Data {
	self := new(Pro_Data)
	self.is_simulation = false
	self.win_percentage = 95
	self.min_win_percentage = 75
	self.my_capital = nil
	self.my_unit_territories = make([dynamic]^Territory)
	self.unit_territory_map = make(map[^Unit]^Territory)
	self.unit_value_map = make(map[^Unit_Type]i32)
	self.purchase_options = nil
	self.units_to_be_consumed = make(map[^Unit]struct{})
	self.min_cost_per_hit_point = max(f64)
	return self
}


// games.strategy.triplea.ai.pro.ProData#getUnitValue(games.strategy.engine.data.UnitType)
// Java: return unitValueMap.getInt(type);
// IntegerMap.getInt returns 0 for absent keys, matching the Odin
// map default for an unset i32 value.
pro_data_get_unit_value :: proc(self: ^Pro_Data, type: ^Unit_Type) -> i32 {
	if v, ok := self.unit_value_map[type]; ok {
		return v
	}
	return 0
}


// games.strategy.triplea.ai.pro.ProData#newUnitTerritoryMap(games.strategy.engine.data.GameState)
// Java: iterate every territory on the map and record each unit's
// owning territory in a fresh HashMap.
pro_data_new_unit_territory_map :: proc(data: ^Game_State) -> map[^Unit]^Territory {
	unit_territory_map := make(map[^Unit]^Territory)
	for t in game_map_get_territories(game_state_get_map(data)) {
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			unit_territory_map[u] = t
		}
	}
	return unit_territory_map
}


// games.strategy.triplea.ai.pro.ProData#getMinCostPerHitPoint(java.util.List)
// Java: scan the provided land purchase options and return the
// smallest cost-per-hit-point, defaulting to Double.MAX_VALUE when
// the list is empty.
pro_data_get_min_cost_per_hit_point_from :: proc(self: ^Pro_Data, land_purchase_options: [dynamic]^Pro_Purchase_Option) -> f64 {
	min_cost_per_hit_point := max(f64)
	for ppo in land_purchase_options {
		c := pro_purchase_option_get_cost_per_hit_point(ppo)
		if c < min_cost_per_hit_point {
			min_cost_per_hit_point = c
		}
	}
	return min_cost_per_hit_point
}
