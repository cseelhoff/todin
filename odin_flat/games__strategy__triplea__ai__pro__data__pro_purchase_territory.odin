package game

import "core:fmt"
import "core:strings"

Pro_Purchase_Territory :: struct {
	territory:             ^Territory,
	unit_production:       i32,
	can_place_territories: [dynamic]^Pro_Place_Territory,
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

