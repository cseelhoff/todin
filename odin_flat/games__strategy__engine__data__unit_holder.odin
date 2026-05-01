package game

// games.strategy.engine.data.UnitHolder
//
// Java is an interface; only its default methods live here. The abstract
// methods (getUnitCollection, notifyChanged, getType) are implemented by
// the concrete holders (Territory, Game_Player) and reached through
// unit_holder_get_unit_collection / named_unit_holder_* (defined in
// later Phase B layers — forward refs across the `game` package are
// fine).
Unit_Holder :: struct {}

// Java: default Collection<Unit> getUnits() {
//         return getUnitCollection().getUnits();
//       }
unit_holder_get_units :: proc(self: ^Unit_Holder) -> [dynamic]^Unit {
	return unit_collection_get_units(unit_holder_get_unit_collection(self))
}

// Java: default boolean anyUnitsMatch(final Predicate<Unit> matcher) {
//         return getUnitCollection().anyMatch(matcher);
//       }
unit_holder_any_units_match :: proc(self: ^Unit_Holder, pred: proc(^Unit) -> bool) -> bool {
	return unit_collection_any_match(unit_holder_get_unit_collection(self), pred)
}
