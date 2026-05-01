package game

Unit_Category :: struct {
	type:           ^Unit_Type,
	dependents:     [dynamic]^Unit_Owner,
	movement:       f64,
	transport_cost: i32,
	can_retreat:    bool,
	owner:          ^Game_Player,
	units:          [dynamic]^Unit,
	damaged:        i32,
	bombing_damage: i32,
	disabled:       bool,
}

// Java: `public void addUnit(final Unit unit) { units.add(unit); }`
unit_category_add_unit :: proc(self: ^Unit_Category, unit: ^Unit) {
	append(&self.units, unit)
}

// Java: `public boolean getCanRetreat() { return canRetreat; }`
unit_category_get_can_retreat :: proc(self: ^Unit_Category) -> bool {
	return self.can_retreat
}

// Java: `@Getter private int damaged = 0;`
unit_category_get_damaged :: proc(self: ^Unit_Category) -> i32 {
	return self.damaged
}

// Java: `public boolean getDisabled() { return disabled; }`
unit_category_get_disabled :: proc(self: ^Unit_Category) -> bool {
	return self.disabled
}

// Java: `@Getter private final GamePlayer owner;`
unit_category_get_owner :: proc(self: ^Unit_Category) -> ^Game_Player {
	return self.owner
}

// Java: `@Getter private final int transportCost;`
unit_category_get_transport_cost :: proc(self: ^Unit_Category) -> i32 {
	return self.transport_cost
}

// Java: `@Getter private final UnitType type;`
unit_category_get_type :: proc(self: ^Unit_Category) -> ^Unit_Type {
	return self.type
}

// Java: `@Getter private final List<Unit> units = new ArrayList<>();`
unit_category_get_units :: proc(self: ^Unit_Category) -> [dynamic]^Unit {
	return self.units
}

// Java: `@Override public int hashCode() { return Objects.hash(type, owner); }`
// Mirrors `Arrays.hashCode(new Object[]{type, owner})`:
//   h = 31 * (31 * 1 + h(type)) + h(owner)
// with `h(null) == 0`.
unit_category_hash_code :: proc(self: ^Unit_Category) -> i32 {
	type_hash: i32 = 0
	if self.type != nil {
		type_hash = unit_type_hash_code(self.type)
	}
	owner_hash: i32 = 0
	if self.owner != nil {
		owner_hash = default_named_hash_code(&self.owner.named_attachable.default_named)
	}
	return 31 * (31 + type_hash) + owner_hash
}

