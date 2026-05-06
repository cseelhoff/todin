package game

// games.strategy.engine.data.Territory
//
// extends NamedAttachable implements NamedUnitHolder, Comparable<Territory>

Territory :: struct {
	using named_attachable: Named_Attachable,
	water:                bool,
	owner:                ^Game_Player,
	unit_collection:      ^Unit_Collection,
	territory_attachment: ^Territory_Attachment,
}

// games.strategy.engine.data.Territory#<init>(String, boolean, GameData)
// Java:
//   super(name, data);
//   this.water = water;
//   owner = data.getPlayerList().getNullPlayer();
//   unitCollection = new UnitCollection(this, getData());
territory_new :: proc(name: string, water: bool, data: ^Game_Data) -> ^Territory {
	self := new(Territory)
	parent := named_attachable_new(name, data)
	self.named_attachable = parent^
	free(parent)
	self.named_attachable.default_named.named.kind = .Territory
	self.named_attachable.default_named.named.get_name = territory_v_get_name
	self.water = water
	self.owner = player_list_get_null_player(game_data_get_player_list(data))
	self.unit_collection = unit_collection_new(cast(^Named_Unit_Holder)self, data)
	return self
}

territory_to_string :: proc(self: ^Territory) -> string {
	return default_named_get_name(&self.named_attachable.default_named)
}

territory_v_get_name :: proc(self: ^Named) -> string {
	return territory_get_name(cast(^Territory)self)
}

// games.strategy.engine.data.Territory#isOwnedBy(GamePlayer)
territory_is_owned_by :: proc(self: ^Territory, player: ^Game_Player) -> bool {
	// Java: return getOwner().equals(player);
	// GamePlayer does not override equals, so this is reference identity.
	return self.owner == player
}

// Mirrors Java's `Territory.compareTo`, which delegates to
// `String.compareTo` on the territory name. Java's contract returns
// the lexicographic byte/char difference; for the ASCII territory
// names used by the engine this matches a byte-wise compare.
territory_compare_to :: proc(self: ^Territory, other: ^Territory) -> i32 {
	a := default_named_get_name(&self.named_attachable.default_named)
	b := default_named_get_name(&other.named_attachable.default_named)
	min_len := len(a)
	if len(b) < min_len {
		min_len = len(b)
	}
	for i in 0 ..< min_len {
		if a[i] != b[i] {
			return i32(a[i]) - i32(b[i])
		}
	}
	return i32(len(a)) - i32(len(b))
}

// games.strategy.engine.data.Territory#getType()
// Java: return UnitHolder.TERRITORY;  // the string "T"
territory_get_type :: proc(self: ^Territory) -> string {
	return "T"
}

// games.strategy.engine.data.Territory#getOwner()
// Lombok @Getter on the `owner` field.
territory_get_owner :: proc(self: ^Territory) -> ^Game_Player {
	return self.owner
}

// games.strategy.engine.data.Territory#isWater()
territory_is_water :: proc(self: ^Territory) -> bool {
	return self.water
}

// games.strategy.engine.data.Territory#getUnitCollection()
// Lombok @Getter on the `unitCollection` field.
territory_get_unit_collection :: proc(self: ^Territory) -> ^Unit_Collection {
	return self.unit_collection
}

// games.strategy.engine.data.Territory#getData() (inherited from
// GameDataComponent via NamedAttachable -> DefaultNamed).
territory_get_data :: proc(self: ^Territory) -> ^Game_Data {
	return game_data_component_get_data(&self.named_attachable.default_named.game_data_component)
}

// games.strategy.engine.data.Territory#setOwner(GamePlayer)
// Java:
//   this.owner = Optional.ofNullable(owner).orElse(getData().getPlayerList().getNullPlayer());
//   getData().notifyTerritoryOwnerChanged(this);
territory_set_owner :: proc(self: ^Territory, owner: ^Game_Player) {
	data := game_data_component_get_data(&self.named_attachable.default_named.game_data_component)
	if owner != nil {
		self.owner = owner
	} else {
		self.owner = player_list_get_null_player(game_data_get_player_list(data))
	}
	game_data_notify_territory_owner_changed(data, self)
}

// games.strategy.engine.data.Territory#notifyChanged()
// Java: getData().notifyTerritoryUnitsChanged(this);
territory_notify_changed :: proc(self: ^Territory) {
	data := game_data_component_get_data(&self.named_attachable.default_named.game_data_component)
	game_data_notify_territory_units_changed(data, self)
}

// games.strategy.engine.data.Territory#notifyAttachmentChanged()
// Java: getData().notifyTerritoryAttachmentChanged(this);
territory_notify_attachment_changed :: proc(self: ^Territory) {
	data := game_data_component_get_data(&self.named_attachable.default_named.game_data_component)
	game_data_notify_territory_attachment_changed(data, self)
}

// games.strategy.engine.data.Territory#getName()
// Forwarder to the embedded Default_Named accessor (Territory extends
// NamedAttachable, which extends DefaultNamed).
territory_get_name :: proc(self: ^Territory) -> string {
	return default_named_get_name(&self.named_attachable.default_named)
}

// games.strategy.engine.data.Territory#getMatches(Predicate)
// Inherited default from UnitHolder:
//   return getUnitCollection().getMatches(matcher);
// Odin convention: predicates carry a closure-emulating `ctx: rawptr`
// alongside the proc value (Odin proc literals can't capture). Callers
// throughout odin_flat/ pass `(pred, ctx)` pairs returned by the
// pro_matches helpers.
territory_get_matches :: proc(self: ^Territory, matcher: proc(rawptr, ^Unit) -> bool, ctx: rawptr) -> [dynamic]^Unit {
	uc := self.unit_collection
	result: [dynamic]^Unit
	if uc == nil {
		return result
	}
	for u in uc.units {
		if matcher(ctx, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.engine.data.Territory#getUnits()
// Inherited default from UnitHolder:
//   return getUnitCollection().getUnits();
territory_get_units :: proc(self: ^Territory) -> [dynamic]^Unit {
	if self.unit_collection == nil {
		empty: [dynamic]^Unit
		return empty
	}
	return unit_collection_get_units(self.unit_collection)
}

// games.strategy.engine.data.Territory#anyUnitsMatch(Predicate)
// Inherited default from UnitHolder:
//   return getUnitCollection().anyUnitsMatch(matcher);
// Mirrors `territory_get_matches`'s (pred, ctx) closure-emulation
// signature so existing call sites (e.g. pro_territory_manager) work.
territory_any_units_match :: proc(self: ^Territory, pred: proc(rawptr, ^Unit) -> bool, ctx: rawptr) -> bool {
	uc := self.unit_collection
	if uc == nil {
		return false
	}
	for u in uc.units {
		if pred(ctx, u) {
			return true
		}
	}
	return false
}
