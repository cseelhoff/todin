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

// Java: default List<Unit> getMatches(final Predicate<Unit> matcher) {
//         return getUnitCollection().getMatches(matcher);
//       }
unit_holder_get_matches :: proc(self: ^Unit_Holder, pred: proc(^Unit) -> bool) -> [dynamic]^Unit {
	return unit_collection_get_matches(unit_holder_get_unit_collection(self), pred)
}

// Java: UnitCollection getUnitCollection() — abstract dispatch to the
// concrete holder's unit collection. Discriminates on the layout
// shared by every concrete UnitHolder: each starts with a
// `using named_attachable: Named_Attachable` whose embedded Named has
// a `kind` discriminator set by the holder's constructor.
unit_holder_get_unit_collection :: proc(holder: ^Unit_Holder) -> ^Unit_Collection {
	as_named := cast(^Named_Attachable)holder
	switch as_named.default_named.named.kind {
	case .Territory:
		return (cast(^Territory)holder).unit_collection
	case .Game_Player:
		return (cast(^Game_Player)holder).units_held
	case .Other, .Unit_Type, .Production_Rule, .Production_Frontier, .I_Attachment:
		return nil
	}
	return nil
}

// Java: NamedUnitHolder.getType() returns "T" (Territory) or "P" (Player),
// keyed by UnitHolder.TERRITORY / UnitHolder.PLAYER constants.
named_unit_holder_get_type :: proc(holder: ^Named_Unit_Holder) -> string {
	as_named := cast(^Named_Attachable)holder
	switch as_named.default_named.named.kind {
	case .Territory:
		return "T"
	case .Game_Player:
		return "P"
	case .Other, .Unit_Type, .Production_Rule, .Production_Frontier, .I_Attachment:
		return ""
	}
	return ""
}
