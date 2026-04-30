package game

Pro_Transport_Utils :: struct {}

// Java: public static Set<Unit> getMovedUnits(
//     final List<Unit> alreadyMovedUnits,
//     final Map<Territory, ProTerritory> attackMap)
//   final Set<Unit> movedUnits = new HashSet<>(alreadyMovedUnits);
//   movedUnits.addAll(attackMap.values().stream()
//       .map(ProTerritory::getAllDefenders)
//       .flatMap(Collection::stream)
//       .collect(Collectors.toList()));
//   return movedUnits;
//
// Java's Set<Unit> maps to Odin's `map[^Unit]struct{}`. The stream
// pipeline flattens every defender of every ProTerritory in the map
// into the result set.
pro_transport_utils_get_moved_units :: proc(
	already_moved_units: [dynamic]^Unit,
	attack_map: map[^Territory]^Pro_Territory,
) -> map[^Unit]struct{} {
	moved_units := make(map[^Unit]struct{})
	for u in already_moved_units {
		moved_units[u] = {}
	}
	for _, pt in attack_map {
		defenders := pro_territory_get_all_defenders(pt)
		for u in defenders {
			moved_units[u] = {}
		}
		delete(defenders)
	}
	return moved_units
}

// Java: private static Comparator<Unit> getDecreasingAttackComparator(
//     final GamePlayer player)
//   return (o1, o2) -> {
//     final Set<UnitSupportAttachment> supportAttachments1 =
//         UnitSupportAttachment.get(o1.getType());
//     int maxSupport1 = 0;
//     for (final UnitSupportAttachment usa : supportAttachments1) {
//       if (usa.getAllied() && usa.getOffence() && usa.getBonus() > maxSupport1) {
//         maxSupport1 = usa.getBonus();
//       }
//     }
//     final int attack1 = o1.getUnitAttachment().getAttack(player) + maxSupport1;
//     ... mirror for o2 ...
//     return attack2 - attack1;
//   };
//
// The lambda captures `player`, so we use the rawptr-ctx closure-capture
// convention (see llm-instructions.md): a heap-allocated ctx struct
// holds the captured `^Game_Player`, and the returned comparator is
// the non-capturing trampoline paired with the ctx pointer. Java's
// `Comparator<Unit>` returning `attack2 - attack1` (decreasing) maps
// to a less-than predicate `attack(a) > attack(b)`.
Pro_Transport_Utils_Decreasing_Attack_Comparator_Ctx :: struct {
	player: ^Game_Player,
}

pro_transport_utils_decreasing_attack_comparator_less :: proc(
	ctx: rawptr,
	o1: ^Unit,
	o2: ^Unit,
) -> bool {
	c := cast(^Pro_Transport_Utils_Decreasing_Attack_Comparator_Ctx)ctx

	support_attachments_1 := unit_support_attachment_get(unit_get_type(o1))
	max_support_1: i32 = 0
	for usa in support_attachments_1 {
		if unit_support_attachment_get_allied(usa) &&
		   unit_support_attachment_get_offence(usa) &&
		   unit_support_attachment_get_bonus(usa) > max_support_1 {
			max_support_1 = unit_support_attachment_get_bonus(usa)
		}
	}
	attack_1 :=
		unit_attachment_get_attack(unit_get_unit_attachment(o1), c.player) + max_support_1

	support_attachments_2 := unit_support_attachment_get(unit_get_type(o2))
	max_support_2: i32 = 0
	for usa in support_attachments_2 {
		if unit_support_attachment_get_allied(usa) &&
		   unit_support_attachment_get_offence(usa) &&
		   unit_support_attachment_get_bonus(usa) > max_support_2 {
			max_support_2 = unit_support_attachment_get_bonus(usa)
		}
	}
	attack_2 :=
		unit_attachment_get_attack(unit_get_unit_attachment(o2), c.player) + max_support_2

	return attack_1 > attack_2
}

pro_transport_utils_get_decreasing_attack_comparator :: proc(
	player: ^Game_Player,
) -> (
	proc(rawptr, ^Unit, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Pro_Transport_Utils_Decreasing_Attack_Comparator_Ctx)
	ctx.player = player
	return pro_transport_utils_decreasing_attack_comparator_less, rawptr(ctx)
}
