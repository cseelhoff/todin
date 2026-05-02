package game

Unit_Owner :: struct {
	type:  ^Unit_Type,
	owner: ^Game_Player,
}

// games.strategy.triplea.util.UnitOwner#<init>(games.strategy.engine.data.Unit)
//
//   public UnitOwner(final Unit unit) {
//     checkNotNull(unit);
//     type = unit.getType();
//     owner = unit.getOwner();
//   }
unit_owner_new :: proc(unit: ^Unit) -> ^Unit_Owner {
	assert(unit != nil)
	self := new(Unit_Owner)
	self.type = unit_get_type(unit)
	self.owner = unit_get_owner(unit)
	return self
}

// games.strategy.triplea.util.UnitOwner#getType
//
//   @Getter UnitType type;
unit_owner_get_type :: proc(self: ^Unit_Owner) -> ^Unit_Type {
	return self.type
}

// games.strategy.triplea.util.UnitOwner#getOwner
//
//   @Getter GamePlayer owner;
unit_owner_get_owner :: proc(self: ^Unit_Owner) -> ^Game_Player {
	return self.owner
}

// games.strategy.triplea.util.UnitOwner#equals
//
//   public boolean equals(final Object o) {
//     if (o == this) return true;
//     else if (o instanceof UnitOwner other) {
//       return Objects.equals(type, other.type) && Objects.equals(owner, other.owner);
//     }
//     return false;
//   }
unit_owner_equals :: proc(self: ^Unit_Owner, other: ^Unit_Owner) -> bool {
	if other == self {
		return true
	}
	if other == nil {
		return false
	}
	return self.type == other.type && self.owner == other.owner
}

// java.util.Objects.hashCode shim: 0 for null, identity hash otherwise.
@(private="file")
unit_owner_ptr_hash :: proc(p: rawptr) -> i32 {
	if p == nil {
		return 0
	}
	bits := u64(uintptr(p))
	return i32(bits) ~ i32(bits >> 32)
}

// games.strategy.triplea.util.UnitOwner#hashCode
//
//   public int hashCode() {
//     return Objects.hash(type, owner);
//   }
//
// Java's Objects.hash(a, b) == Arrays.hashCode(new Object[]{a, b})
//                           == 31 * (31 + h(a)) + h(b)
unit_owner_hash_code :: proc(self: ^Unit_Owner) -> i32 {
	h := i32(1)
	h = 31 * h + unit_owner_ptr_hash(rawptr(self.type))
	h = 31 * h + unit_owner_ptr_hash(rawptr(self.owner))
	return h
}
