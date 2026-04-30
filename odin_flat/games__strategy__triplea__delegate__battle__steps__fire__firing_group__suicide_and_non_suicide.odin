package game

Firing_Group_Suicide_And_Non_Suicide :: struct {
	suicide_groups:    map[^Unit_Type][dynamic]^Unit,
	non_suicide_group: [dynamic]^Unit,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.fire.FiringGroup$SuicideAndNonSuicide

// Constructor — Java: SuicideAndNonSuicide.of(Multimap<UnitType, Unit>, Collection<Unit>).
// The Odin struct stores the suicide groups as a flat map[^Unit_Type][dynamic]^Unit;
// copy the buckets out of the Multimap shim. The non-suicide group is taken by reference
// (matches Java's @Value behaviour where the field aliases the caller's collection).
firing_group_suicide_and_non_suicide_new :: proc(
	suicide_groups: ^Multimap(^Unit_Type, ^Unit),
	non_suicide_group: [dynamic]^Unit,
) -> ^Firing_Group_Suicide_And_Non_Suicide {
	self := new(Firing_Group_Suicide_And_Non_Suicide)
	self.suicide_groups = make(map[^Unit_Type][dynamic]^Unit)
	for k, bucket in suicide_groups.entries {
		copied := make([dynamic]^Unit)
		for v in bucket {
			append(&copied, v)
		}
		self.suicide_groups[k] = copied
	}
	self.non_suicide_group = non_suicide_group
	return self
}

// int groupCount() — number of distinct suicide unit-type buckets, plus one
// for the non-suicide group iff it is non-empty.
firing_group_suicide_and_non_suicide_group_count :: proc(
	self: ^Firing_Group_Suicide_And_Non_Suicide,
) -> i32 {
	extra: i32 = 0
	if len(self.non_suicide_group) > 0 {
		extra = 1
	}
	return i32(len(self.suicide_groups)) + extra
}

// Collection<Collection<Unit>> values() — gather each suicide bucket as its
// own list, then append the non-suicide list iff non-empty.
firing_group_suicide_and_non_suicide_values :: proc(
	self: ^Firing_Group_Suicide_And_Non_Suicide,
) -> [dynamic][dynamic]^Unit {
	values := make([dynamic][dynamic]^Unit)
	for _, bucket in self.suicide_groups {
		copied := make([dynamic]^Unit)
		for v in bucket {
			append(&copied, v)
		}
		append(&values, copied)
	}
	if len(self.non_suicide_group) > 0 {
		append(&values, self.non_suicide_group)
	}
	return values
}

