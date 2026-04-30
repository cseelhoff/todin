package game

Pro_Purchase_Utils :: struct {}

// Java: public static Comparator<Unit> getCostComparator(final ProData proData)
//   return Comparator.comparingDouble((unit) -> ProPurchaseUtils.getCost(proData, unit));
//
// The lambda captures `proData`, so we use the rawptr-ctx closure-capture
// convention (see llm-instructions.md): a heap-allocated ctx struct holds
// the captured `^Pro_Data`, and the returned comparator is the
// non-capturing trampoline `pro_purchase_utils_cost_comparator_less`
// paired with the ctx pointer. Java's `Comparator<Unit>` maps to a
// less-than predicate `proc(rawptr, ^Unit, ^Unit) -> bool` (the shape
// consumed by Odin sort routines such as `slice.sort_by`).
Pro_Purchase_Utils_Cost_Comparator_Ctx :: struct {
	pro_data: ^Pro_Data,
}

pro_purchase_utils_cost_comparator_less :: proc(ctx: rawptr, a: ^Unit, b: ^Unit) -> bool {
	c := cast(^Pro_Purchase_Utils_Cost_Comparator_Ctx)ctx
	cost_a := pro_purchase_utils_get_cost(c.pro_data, a)
	cost_b := pro_purchase_utils_get_cost(c.pro_data, b)
	return cost_a < cost_b
}

pro_purchase_utils_get_cost_comparator :: proc(
	pro_data: ^Pro_Data,
) -> (
	proc(rawptr, ^Unit, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Pro_Purchase_Utils_Cost_Comparator_Ctx)
	ctx.pro_data = pro_data
	return pro_purchase_utils_cost_comparator_less, rawptr(ctx)
}

// Java: public static void incrementUnitProductionForBidTerritories(
//     final Map<Territory, ProPurchaseTerritory> purchaseTerritories) {
//   purchaseTerritories.values().forEach(
//       ppt -> ppt.setUnitProduction(ppt.getUnitProduction() + 1));
// }
//
// The forEach lambda is non-capturing, so it inlines as a simple loop
// over the map values.
pro_purchase_utils_increment_unit_production_for_bid_territories :: proc(
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) {
	for _, ppt in purchase_territories {
		pro_purchase_territory_set_unit_production(
			ppt,
			pro_purchase_territory_get_unit_production(ppt) + 1,
		)
	}
}

// Java synthetic lambda: ProPurchaseUtils#lambda$getUnitsToConsume$2(Set, Unit) -> boolean.
//
// Origin: inside getUnitsToConsume the predicate
//     Matches.eligibleUnitToConsume(player, neededType).and(u -> !unitsToConsume.contains(u))
// generates this lambda with the captured `unitsToConsume` Set as its
// first synthetic parameter. Under the rawptr-ctx closure-capture
// convention (see llm-instructions.md), the captured Set is carried in a
// small ctx struct and the lambda becomes a free top-level proc with the
// `proc(rawptr, ^Unit) -> bool` shape.
Pro_Purchase_Utils_Lambda_Get_Units_To_Consume_2_Ctx :: struct {
	units_to_consume: ^map[^Unit]struct {},
}

pro_purchase_utils_lambda_get_units_to_consume_2 :: proc(ctx: rawptr, u: ^Unit) -> bool {
	c := cast(^Pro_Purchase_Utils_Lambda_Get_Units_To_Consume_2_Ctx)ctx
	_, exists := c.units_to_consume[u]
	return !exists
}

