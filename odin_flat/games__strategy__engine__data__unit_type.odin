package game

// games.strategy.engine.data.UnitType
//
// A class of units (e.g. "infantry", "fighter"). Carries its UnitAttachment.

Unit_Type :: struct {
	using named_attachable: Named_Attachable,
	unit_attachment:        ^Unit_Attachment,
}

// Mirrors Java's `UnitType.equals(Object)`:
//   return o instanceof UnitType && ((UnitType) o).getName().equals(getName());
unit_type_equals :: proc(self: ^Unit_Type, o: ^Unit_Type) -> bool {
	if o == nil {
		return false
	}
	return default_named_get_name(&o.named_attachable.default_named) ==
		default_named_get_name(&self.named_attachable.default_named)
}

// Mirrors Java's `Objects.hashCode(getName())` from `UnitType.hashCode`.
unit_type_hash_code :: proc(self: ^Unit_Type) -> i32 {
	return default_named_hash_code(&self.named_attachable.default_named)
}

// Synthetic lambda from the 5-arg `UnitType.create(quantity, owner, isTemp,
// hitsTaken, bombingUnitDamage)`:
//   IntStream.range(0, quantity).mapToObj(i -> create(owner, isTemp, hitsTaken, bombingUnitDamage))
// Captures: this, owner, isTemp, hitsTaken, bombingUnitDamage. Lambda arg: i.
unit_type_lambda_create_0 :: proc(
	self: ^Unit_Type,
	owner: ^Game_Player,
	is_temp: bool,
	hits_taken: i32,
	bombing_unit_damage: i32,
	idx: i32,
) -> ^Unit {
	return unit_type_create(self, owner, is_temp, hits_taken, bombing_unit_damage)
}

// Mirrors Java's `UnitType.createTemp(int quantity, GamePlayer owner)`:
//   return create(quantity, owner, true, 0, 0);
// The 5-arg `create` body is
//   IntStream.range(0, quantity)
//       .mapToObj(i -> create(owner, isTemp, hitsTaken, bombingUnitDamage))
//       .collect(Collectors.toList());
// inlined here with isTemp=true, hitsTaken=0, bombingUnitDamage=0.
unit_type_create_temp :: proc(
	self: ^Unit_Type,
	quantity: i32,
	owner: ^Game_Player,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, quantity)
	for i in 0 ..< quantity {
		append(&result, unit_type_lambda_create_0(self, owner, true, 0, 0, i))
	}
	return result
}

// Mirrors Java's 5-arg
//   public List<Unit> UnitType.create(int quantity, GamePlayer owner,
//       boolean isTemp, int hitsTaken, int bombingUnitDamage)
//
//   return IntStream.range(0, quantity)
//       .mapToObj(i -> create(owner, isTemp, hitsTaken, bombingUnitDamage))
//       .collect(Collectors.toList());
unit_type_create_5 :: proc(
	self: ^Unit_Type,
	quantity: i32,
	owner: ^Game_Player,
	is_temp: bool,
	hits_taken: i32,
	bombing_unit_damage: i32,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, int(quantity))
	for i: i32 = 0; i < quantity; i += 1 {
		append(&result, unit_type_lambda_create_0(self, owner, is_temp, hits_taken, bombing_unit_damage, i))
	}
	return result
}

// Mirrors Java's 2-arg
//   public List<Unit> UnitType.create(int quantity, GamePlayer owner)
//   return create(quantity, owner, false, 0, 0);
// Suffix _2 disambiguates from the private single-unit
// `unit_type_create(self, owner, is_temp, hits_taken, bombing_unit_damage)`
// (Odin has no overloading); _5 is the full quantity-based variant.
unit_type_create_2 :: proc(
	self: ^Unit_Type,
	quantity: i32,
	owner: ^Game_Player,
) -> [dynamic]^Unit {
	return unit_type_create_5(self, quantity, owner, false, 0, 0)
}

// Mirrors Java's constructor
//   public UnitType(final String name, final GameData data) {
//     super(name, data);
//   }
// `super` is `NamedAttachable(String, GameData)`.
unit_type_new :: proc(name: string, data: ^Game_Data) -> ^Unit_Type {
	self := new(Unit_Type)
	base := named_attachable_new(name, data)
	self.named_attachable = base^
	free(base)
	self.named_attachable.default_named.named.kind = .Unit_Type
	return self
}

// Mirrors Java's private single-unit
//   private Unit UnitType.create(GamePlayer owner, boolean isTemp,
//       int hitsTaken, int bombingUnitDamage) {
//     final Unit u = new Unit(this, owner, getData());
//     u.setHits(hitsTaken);
//     u.setUnitDamage(bombingUnitDamage);
//     if (!isTemp) { getData().getUnits().put(u); }
//     return u;
//   }
unit_type_create :: proc(
	self: ^Unit_Type,
	owner: ^Game_Player,
	is_temp: bool,
	hits_taken: i32,
	bombing_unit_damage: i32,
) -> ^Unit {
	data := game_data_component_get_data(
		&self.named_attachable.default_named.game_data_component,
	)
	u := unit_new(self, owner, data)
	unit_set_hits(u, hits_taken)
	unit_set_unit_damage(u, bombing_unit_damage)
	if !is_temp {
		units_list_put(game_data_get_units(data), u)
	}
	return u
}

// Mirrors Java's `UnitType.getUnitAttachment()`:
//   if (unitAttachment == null) {
//     unitAttachment = UnitAttachment.get(this, Constants.UNIT_ATTACHMENT_NAME);
//   }
//   return unitAttachment;
// `Constants.UNIT_ATTACHMENT_NAME` is the literal "unitAttachment".
unit_type_get_unit_attachment :: proc(self: ^Unit_Type) -> ^Unit_Attachment {
	if self.unit_attachment == nil {
		self.unit_attachment = unit_attachment_get(self, "unitAttachment")
	}
	return self.unit_attachment
}

// Java: inherited from NamedAttachable / DefaultNamed#getName().
unit_type_get_name :: proc(self: ^Unit_Type) -> string {
	return default_named_get_name(&self.named_attachable.default_named)
}
