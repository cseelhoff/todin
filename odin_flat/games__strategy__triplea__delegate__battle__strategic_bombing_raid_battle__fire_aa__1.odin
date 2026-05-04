package game

import "core:fmt"
import "core:strings"

Fire_Aa_1 :: struct {
	using i_executable: I_Executable,
	outer:               ^Fire_Aa,
	current_possible_aa: [dynamic]^Unit,
	current_type_aa:     string,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$1

fire_aa_1_new :: proc(
	outer: ^Fire_Aa,
	current_possible_aa: [dynamic]^Unit,
	current_type_aa: string,
) -> ^Fire_Aa_1 {
	self := new(Fire_Aa_1)
	self.outer = outer
	self.current_possible_aa = current_possible_aa
	self.current_type_aa = current_type_aa
	self.i_executable.execute = fire_aa_1_execute
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$1#execute(ExecutionStack, IDelegateBridge)
//
// Java body (the "roll" anonymous IExecutable inside FireAa.execute):
//   validAttackingUnitsForThisRoll.removeAll(casualtiesSoFar);
//   if (!validAttackingUnitsForThisRoll.isEmpty()) {
//     dice = RollDiceFactory.rollAaDice(
//         validAttackingUnitsForThisRoll, currentPossibleAa, bridge, battleSite,
//         CombatValueBuilder.aaCombatValue()
//             .enemyUnits(List.of()).friendlyUnits(List.of())
//             .side(BattleState.Side.DEFENSE)
//             .supportAttachments(bridge.getData().getUnitTypeList().getSupportAaRules())
//             .build());
//     final var sound = bridge.getSoundChannelBroadcaster();
//     if (currentTypeAa.equals("AA")) {
//       sound.playSoundForAll(
//           dice.getHits() > 0 ? CLIP_BATTLE_AA_HIT : CLIP_BATTLE_AA_MISS, defender);
//     } else {
//       String prefix = CLIP_BATTLE_X_PREFIX + currentTypeAa.toLowerCase(Locale.ROOT);
//       sound.playSoundForAll(
//           prefix + (dice.getHits() > 0 ? CLIP_BATTLE_X_HIT : CLIP_BATTLE_X_MISS), defender);
//     }
//   }
fire_aa_1_execute :: proc(
	self_base: ^I_Executable,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	self := cast(^Fire_Aa_1)self_base
	fa := self.outer
	sbr := fa.this_0

	// validAttackingUnitsForThisRoll.removeAll(casualtiesSoFar)
	if len(fa.casualties_so_far) > 0 && len(fa.valid_attacking_units_for_this_roll) > 0 {
		removed := make(map[^Unit]struct {})
		defer delete(removed)
		for u in fa.casualties_so_far {
			removed[u] = {}
		}
		filtered: [dynamic]^Unit
		for u in fa.valid_attacking_units_for_this_roll {
			if _, hit := removed[u]; !hit {
				append(&filtered, u)
			}
		}
		delete(fa.valid_attacking_units_for_this_roll)
		fa.valid_attacking_units_for_this_roll = filtered
	}

	if len(fa.valid_attacking_units_for_this_roll) == 0 {
		return
	}

	// Build the AA combat value: SBR AA ignores enemy/friendly units for support.
	game_data := i_delegate_bridge_get_data(bridge)
	support_aa_rules_map := unit_type_list_get_support_aa_rules(
		game_data_get_unit_type_list(game_data),
	)
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_aa_rules_map {
		append(&support_attachments, usa)
	}
	empty_enemy: [dynamic]^Unit
	empty_friendly: [dynamic]^Unit
	cv := combat_value_builder_aa_builder_build(
		combat_value_builder_aa_builder_support_attachments(
			combat_value_builder_aa_builder_side(
				combat_value_builder_aa_builder_friendly_units(
					combat_value_builder_aa_builder_enemy_units(
						combat_value_builder_aa_combat_value(),
						empty_enemy,
					),
					empty_friendly,
				),
				.DEFENSE,
			),
			support_attachments,
		),
	)

	fa.dice = roll_dice_factory_roll_aa_dice(
		fa.valid_attacking_units_for_this_roll,
		self.current_possible_aa,
		bridge,
		sbr.battle_site,
		cv,
	)

	channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
	hits := dice_roll_get_hits(fa.dice)
	if self.current_type_aa == "AA" {
		clip := "battle_aa_hit" if hits > 0 else "battle_aa_miss"
		headless_sound_channel_play_sound_for_all(channel, clip, sbr.defender)
	} else {
		// SoundPath.CLIP_BATTLE_X_PREFIX = "battle_"
		// suffix CLIP_BATTLE_X_HIT = "_hit" / CLIP_BATTLE_X_MISS = "_miss"
		lower := strings.to_lower(self.current_type_aa)
		defer delete(lower)
		suffix := "_hit" if hits > 0 else "_miss"
		clip := fmt.aprintf("battle_%s%s", lower, suffix)
		defer delete(clip)
		headless_sound_channel_play_sound_for_all(channel, clip, sbr.defender)
	}
}

