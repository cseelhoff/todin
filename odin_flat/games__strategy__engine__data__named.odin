package game

// games.strategy.engine.data.Named (interface)
//
// Java is an interface; in Odin we expose it as a struct that holds the
// canonical name storage. Subtypes embed `using named: Named`, giving the
// `obj.named.base.name` access pattern the snapshot harness expects.

Default_Named_Base :: struct {
	name: string,
}

// Runtime discriminator for Java `instanceof` checks against Named
// subtypes that the JVM exposes as distinct classes. Default zero
// value `.Other` covers every embedding struct whose constructor has
// not been ported yet; constructors set this explicitly when they
// are implemented in Phase B. The set of variants is driven by the
// `instanceof` checks in
// games/strategy/engine/data/GameObjectStreamData.java (canSerialize
// and the GameObjectStreamData(Named) constructor).
Named_Kind :: enum {
	Other,
	Game_Player,
	Unit_Type,
	Territory,
	Production_Rule,
	Production_Frontier,
	I_Attachment,
}

Named :: struct {
	base: Default_Named_Base,
	kind: Named_Kind,
	get_name: proc(self: ^Named) -> string,
}

// Dispatch for the Java `Named#getName()` interface method. Falls back
// to the canonical name stored in `base.name` when no override has been
// installed by an embedding struct's constructor.
named_get_name :: proc(self: ^Named) -> string {
	if self == nil {
		return ""
	}
	if self.get_name != nil {
		return self.get_name(self)
	}
	return self.base.name
}
