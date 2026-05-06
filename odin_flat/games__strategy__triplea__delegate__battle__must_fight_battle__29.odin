package game

import "core:fmt"
import "core:strings"

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.MustFightBattle$29

Must_Fight_Battle_29 :: struct {
	using i_executable: I_Executable,
	this_0:             ^Must_Fight_Battle,
	loop:               ^I_Executable,
}

must_fight_battle_29_new :: proc(outer: ^Must_Fight_Battle, executable: ^I_Executable) -> ^Must_Fight_Battle_29 {
	self := new(Must_Fight_Battle_29)
	self.this_0 = outer
	self.loop = executable
	self.i_executable.execute = must_fight_battle_29_v_execute
	return self
}

must_fight_battle_29_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	must_fight_battle_29_execute(cast(^Must_Fight_Battle_29)self, stack, bridge)
}

// games.strategy.triplea.delegate.battle.MustFightBattle$29#execute
//
//   if (!isOver) {
//     round++;
//     if (round > MAX_ROUNDS) {
//       throw new IllegalStateException(
//           "Round 10,000 reached in a battle. ..."
//           + " Territory: " + battleSite
//           + " Attacker: " + attacker.getName()
//           + " Attacking unit types: " + <distinct attacking unit type names joined>
//           + ", Defending unit types: " + <distinct defending unit type names joined>);
//     }
//     determineStepStrings();
//     final IDisplay display = bridge.getDisplayChannelBroadcaster();
//     display.listBattleSteps(battleId, stepStrings);
//     if (!MustFightBattle.this.stack.isEmpty()) {
//       throw new IllegalStateException("Stack not empty: " + MustFightBattle.this.stack);
//     }
//     MustFightBattle.this.stack.push(loop);
//   }
must_fight_battle_29_execute :: proc(
	self:   ^Must_Fight_Battle_29,
	stack:  ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	outer := self.this_0
	if outer.is_over {
		return
	}
	outer.round += 1
	if i64(outer.round) > 10000 {
		// Distinct attacking unit type names.
		attacking_seen: map[^Unit_Type]struct{}
		attacking_names: [dynamic]string
		for u in outer.attacking_units {
			t := unit_get_type(u)
			if _, ok := attacking_seen[t]; !ok {
				attacking_seen[t] = {}
				append(&attacking_names, t.base.name)
			}
		}
		// Distinct defending unit type names.
		defending_seen: map[^Unit_Type]struct{}
		defending_names: [dynamic]string
		for u in outer.defending_units {
			t := unit_get_type(u)
			if _, ok := defending_seen[t]; !ok {
				defending_seen[t] = {}
				append(&defending_names, t.base.name)
			}
		}
		fmt.panicf(
			"Round 10,000 reached in a battle. Something must be wrong. Please report this to TripleA.\n Territory: %s Attacker: %s Attacking unit types: %s, Defending unit types: %s",
			outer.battle_site.base.name,
			outer.attacker.base.name,
			strings.join(attacking_names[:], ","),
			strings.join(defending_names[:], ","),
		)
	}
	must_fight_battle_determine_step_strings(outer)
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_list_battle_steps(display, outer.battle_id, outer.step_strings)
	if !execution_stack_is_empty(outer.stack) {
		fmt.panicf("Stack not empty: %v", outer.stack)
	}
	execution_stack_push_one(outer.stack, self.loop)
}

