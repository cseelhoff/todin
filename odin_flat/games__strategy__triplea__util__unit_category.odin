package game

import "core:fmt"
import "core:strings"

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

// Java:
//   private boolean equalsIgnoreDamagedAndBombingDamageAndDisabled(final UnitCategory other) {
//     return other.type.equals(this.type)
//         && other.movement.compareTo(this.movement) == 0
//         && other.owner.equals(this.owner)
//         && CollectionUtils.haveEqualSizeAndEquivalentElements(this.dependents, other.dependents);
//   }
unit_category_equals_ignore_damaged_and_bombing_damage_and_disabled :: proc(self: ^Unit_Category, other: ^Unit_Category) -> bool {
	if !unit_type_equals(other.type, self.type) {
		return false
	}
	if other.movement != self.movement {
		return false
	}
	if other.owner != self.owner {
		return false
	}
	return unit_category_dependents_equivalent(self.dependents, other.dependents)
}

// Mirrors CollectionUtils.haveEqualSizeAndEquivalentElements for [dynamic]^Unit_Owner,
// using UnitOwner.equals (value equality) rather than rawptr identity.
@(private = "file")
unit_category_dependents_equivalent :: proc(c1: [dynamic]^Unit_Owner, c2: [dynamic]^Unit_Owner) -> bool {
	if len(c1) != len(c2) {
		return false
	}
	// Iterables.elementsEqual: same length and pairwise equal in order.
	all_equal := true
	for i in 0 ..< len(c1) {
		if !unit_owner_equals(c1[i], c2[i]) {
			all_equal = false
			break
		}
	}
	if all_equal {
		return true
	}
	// containsAll both ways.
	for a in c1 {
		found := false
		for b in c2 {
			if unit_owner_equals(a, b) {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	for a in c2 {
		found := false
		for b in c1 {
			if unit_owner_equals(a, b) {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}

// Java's AbstractCollection.toString() over a Collection<UnitOwner>,
// which uses UnitOwner.toString(): "Unit owner: <name> type: <name>".
@(private = "file")
unit_category_dependents_to_string :: proc(deps: [dynamic]^Unit_Owner) -> string {
	b: strings.Builder
	strings.builder_init(&b)
	strings.write_byte(&b, '[')
	for d, i in deps {
		if i > 0 {
			strings.write_string(&b, ", ")
		}
		owner_name := default_named_get_name(&d.owner.named_attachable.default_named)
		type_name := default_named_get_name(&d.type.named_attachable.default_named)
		fmt.sbprintf(&b, "Unit owner: %s type: %s", owner_name, type_name)
	}
	strings.write_byte(&b, ']')
	return strings.to_string(b)
}

// Java lambda inside compareTo:
//   (o1, o2) -> {
//     if (CollectionUtils.haveEqualSizeAndEquivalentElements(o1, o2)) return 0;
//     return o1.toString().compareTo(o2.toString());
//   }
unit_category_lambda_compare_to_0 :: proc(o1: [dynamic]^Unit_Owner, o2: [dynamic]^Unit_Owner) -> int {
	if unit_category_dependents_equivalent(o1, o2) {
		return 0
	}
	s1 := unit_category_dependents_to_string(o1)
	s2 := unit_category_dependents_to_string(o2)
	return strings.compare(s1, s2)
}

// Java:
//   @Override public int compareTo(final UnitCategory other) {
//     return Comparator.nullsLast(
//             Comparator.comparing(UnitCategory::getOwner, Comparator.comparing(GamePlayer::getName))
//                 .thenComparing(UnitCategory::getType, new UnitTypeComparator())
//                 .thenComparing(UnitCategory::getMovement)
//                 .thenComparing(UnitCategory::getDependents, (o1, o2) -> { ... })
//                 .thenComparing(UnitCategory::getCanRetreat)
//                 .thenComparingInt(UnitCategory::getDamaged)
//                 .thenComparingInt(UnitCategory::getBombingDamage)
//                 .thenComparing(UnitCategory::getDisabled))
//         .compare(this, other);
unit_category_compare_to :: proc(self: ^Unit_Category, other: ^Unit_Category) -> int {
	// Comparator.nullsLast: nulls sort to the end.
	if self == nil && other == nil {
		return 0
	}
	if self == nil {
		return 1
	}
	if other == nil {
		return -1
	}

	// Owner by name.
	a_name := default_named_get_name(&self.owner.named_attachable.default_named)
	b_name := default_named_get_name(&other.owner.named_attachable.default_named)
	if c := strings.compare(a_name, b_name); c != 0 {
		return c
	}

	// Type via UnitTypeComparator.
	utc := unit_type_comparator_new()
	if c := unit_type_comparator_compare(utc, self.type, other.type); c != 0 {
		return c
	}

	// Movement (BigDecimal natural order). f64 mirrors that.
	if self.movement < other.movement {
		return -1
	}
	if self.movement > other.movement {
		return 1
	}

	// Dependents lambda.
	if c := unit_category_lambda_compare_to_0(self.dependents, other.dependents); c != 0 {
		return c
	}

	// Boolean natural order: false (0) < true (1).
	cmp_bool :: proc(x, y: bool) -> int {
		xi := 0
		if x {xi = 1}
		yi := 0
		if y {yi = 1}
		return xi - yi
	}
	if c := cmp_bool(self.can_retreat, other.can_retreat); c != 0 {
		return c
	}

	// Damaged (int).
	if self.damaged < other.damaged {
		return -1
	}
	if self.damaged > other.damaged {
		return 1
	}

	// Bombing damage (int).
	if self.bombing_damage < other.bombing_damage {
		return -1
	}
	if self.bombing_damage > other.bombing_damage {
		return 1
	}

	// Disabled (Boolean).
	return cmp_bool(self.disabled, other.disabled)
}

// Java:
//   private void createDependents(final Collection<Unit> dependents) {
//     this.dependents = new ArrayList<>();
//     if (dependents == null) { return; }
//     for (final Unit current : dependents) {
//       this.dependents.add(new UnitOwner(current));
//     }
//   }
unit_category_create_dependents :: proc(self: ^Unit_Category, dependents: [dynamic]^Unit) {
	self.dependents = make([dynamic]^Unit_Owner)
	// In Odin a [dynamic] is never "null"; an empty/zeroed slice mirrors Java's null guard.
	if len(dependents) == 0 {
		return
	}
	for current in dependents {
		append(&self.dependents, unit_owner_new(current))
	}
}

// Java:
//   @Override public boolean equals(final Object o) {
//     if (o instanceof UnitCategory other) {
//       final boolean equalsIgnoreDamaged = equalsIgnoreDamagedAndBombingDamageAndDisabled(other);
//       return equalsIgnoreDamaged
//           && other.damaged == this.damaged
//           && other.bombingDamage == this.bombingDamage
//           && other.disabled == this.disabled
//           && other.canRetreat == this.canRetreat;
//     }
//     return false;
//   }
unit_category_equals :: proc(self: ^Unit_Category, other: ^Unit_Category) -> bool {
	if self == nil || other == nil {
		return self == other
	}
	if !unit_category_equals_ignore_damaged_and_bombing_damage_and_disabled(self, other) {
		return false
	}
	return other.damaged == self.damaged &&
		other.bombing_damage == self.bombing_damage &&
		other.disabled == self.disabled &&
		other.can_retreat == self.can_retreat
}

// Java: `public int getHitPoints() { return type.getUnitAttachment().getHitPoints(); }`
unit_category_get_hit_points :: proc(self: ^Unit_Category) -> i32 {
	return unit_attachment_get_hit_points(unit_type_get_unit_attachment(self.type))
}

// Java: `public UnitAttachment getUnitAttachment() { return getType().getUnitAttachment(); }`
unit_category_get_unit_attachment :: proc(self: ^Unit_Category) -> ^Unit_Attachment {
	return unit_type_get_unit_attachment(unit_category_get_type(self))
}

// Java:
//   UnitCategory(
//       final Unit unit,
//       final Collection<Unit> dependents,
//       final BigDecimal movement,
//       final int damaged,
//       final int bombingDamage,
//       final boolean disabled,
//       final int transportCost,
//       final boolean canRetreat) {
//     type = unit.getType();
//     this.movement = movement;
//     this.transportCost = transportCost;
//     owner = unit.getOwner();
//     this.damaged = damaged;
//     this.bombingDamage = bombingDamage;
//     this.disabled = disabled;
//     this.canRetreat = canRetreat;
//     units.add(unit);
//     createDependents(dependents);
//   }
unit_category_new :: proc(
	unit: ^Unit,
	dependents: [dynamic]^Unit,
	movement: f64,
	damaged: i32,
	bombing_damage: i32,
	disabled: bool,
	transport_cost: i32,
	can_retreat: bool,
) -> ^Unit_Category {
	self := new(Unit_Category)
	self.type = unit_get_type(unit)
	self.movement = movement
	self.transport_cost = transport_cost
	self.owner = unit_get_owner(unit)
	self.damaged = damaged
	self.bombing_damage = bombing_damage
	self.disabled = disabled
	self.can_retreat = can_retreat
	self.units = make([dynamic]^Unit)
	append(&self.units, unit)
	unit_category_create_dependents(self, dependents)
	return self
}

