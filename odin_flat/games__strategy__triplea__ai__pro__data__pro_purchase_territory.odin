package game

import "core:fmt"
import "core:strings"

Pro_Purchase_Territory :: struct {
	territory:             ^Territory,
	unit_production:       i32,
	can_place_territories: [dynamic]^Pro_Place_Territory,
}

// Java: ProPurchaseTerritory(Territory, GameData, GamePlayer, int, boolean)
// Tracks unit purchase and the list of place territories. When not in the bid
// phase and the production territory has a factory and is not a conquered
// owned land, also include adjacent water territories — except enemy-occupied
// seas, unless WW2V2 or unitPlacementInEnemySeas is enabled.
pro_purchase_territory_new :: proc(
	territory: ^Territory,
	data: ^Game_Data,
	player: ^Game_Player,
	unit_production: i32,
	is_bid: bool,
) -> ^Pro_Purchase_Territory {
	self := new(Pro_Purchase_Territory)
	self.territory = territory
	self.unit_production = unit_production
	self.can_place_territories = make([dynamic]^Pro_Place_Territory)
	append(&self.can_place_territories, pro_place_territory_new(territory))
	if !is_bid {
		f_p, f_c := pro_matches_territory_has_factory_and_is_not_conquered_owned_land(player)
		if f_p(f_c, territory) {
			w_p, w_c := matches_territory_is_water()
			water_neighbors := game_map_get_neighbors_predicate(
				game_data_get_map(data),
				territory,
				w_p,
				w_c,
			)
			props := game_data_get_properties(data)
			ww2v2 := properties_get_ww2_v2(props)
			placement_in_enemy_seas := properties_get_unit_placement_in_enemy_seas(props)
			en_p, en_c := matches_enemy_unit(player)
			for t in water_neighbors {
				allow := ww2v2 || placement_in_enemy_seas
				if !allow {
					has_enemy := false
					for u in t.unit_collection.units {
						if en_p(en_c, u) {
							has_enemy = true
							break
						}
					}
					allow = !has_enemy
				}
				if allow {
					append(&self.can_place_territories, pro_place_territory_new(t))
				}
			}
		}
	}
	return self
}

pro_purchase_territory_get_territory :: proc(self: ^Pro_Purchase_Territory) -> ^Territory {
	return self.territory
}

pro_purchase_territory_get_unit_production :: proc(self: ^Pro_Purchase_Territory) -> i32 {
	return self.unit_production
}

pro_purchase_territory_set_unit_production :: proc(self: ^Pro_Purchase_Territory, unit_production: i32) {
	self.unit_production = unit_production
}

pro_purchase_territory_get_can_place_territories :: proc(self: ^Pro_Purchase_Territory) -> [dynamic]^Pro_Place_Territory {
	return self.can_place_territories
}

// Java: int getRemainingUnitProduction() — returns unitProduction minus the
// count of already-placed non-construction units across every can-place
// territory. Mirrors CollectionUtils.countMatches(ppt.getPlaceUnits(),
// Matches.unitIsNotConstruction()).
pro_purchase_territory_get_remaining_unit_production :: proc(self: ^Pro_Purchase_Territory) -> i32 {
	remaining := self.unit_production
	pred, pred_ctx := matches_unit_is_not_construction()
	for ppt in self.can_place_territories {
		for u in pro_place_territory_get_place_units(ppt) {
			if pred(pred_ctx, u) {
				remaining -= 1
			}
		}
	}
	return remaining
}

pro_purchase_territory_to_string :: proc(self: ^Pro_Purchase_Territory, allocator := context.allocator) -> string {
	sb := strings.builder_make(allocator)
	strings.write_string(&sb, "ProPurchaseTerritory(territory=")
	if self.territory != nil {
		strings.write_string(&sb, territory_to_string(self.territory))
	} else {
		strings.write_string(&sb, "null")
	}
	fmt.sbprintf(&sb, ", unitProduction=%d, canPlaceTerritories=[", self.unit_production)
	for ppt, i in self.can_place_territories {
		if i > 0 {
			strings.write_string(&sb, ", ")
		}
		if ppt != nil {
			s := pro_place_territory_to_string(ppt)
			strings.write_string(&sb, s)
		} else {
			strings.write_string(&sb, "null")
		}
	}
	strings.write_string(&sb, "])")
	return strings.to_string(sb)
}

