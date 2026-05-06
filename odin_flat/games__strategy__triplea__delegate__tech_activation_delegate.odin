package game

import "core:fmt"
import "core:strings"

Tech_Activation_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
}

// games.strategy.triplea.delegate.TechActivationDelegate#<init>()
// Java's implicit no-arg constructor. The only declared field
// `needToInitialize` has the Java initializer `= true`; embedded
// Base_Triple_A_Delegate is zero-initialized.
tech_activation_delegate_v_delegate_currently_requires_user_input :: proc(self: ^I_Delegate) -> bool {
	return tech_activation_delegate_delegate_currently_requires_user_input(cast(^Tech_Activation_Delegate)self)
}

tech_activation_delegate_v_end :: proc(self: ^I_Delegate) {
	tech_activation_delegate_end(cast(^Tech_Activation_Delegate)self)
}

tech_activation_delegate_v_get_remote_type :: proc(self: ^I_Delegate) -> typeid {
	return tech_activation_delegate_get_remote_type(cast(^Tech_Activation_Delegate)self)
}

tech_activation_delegate_v_load_state :: proc(self: ^I_Delegate, state: rawptr) {
	tech_activation_delegate_load_state(
		cast(^Tech_Activation_Delegate)self,
		cast(^Tech_Activation_Extended_Delegate_State)state,
	)
}

tech_activation_delegate_v_save_state :: proc(self: ^I_Delegate) -> rawptr {
	return rawptr(tech_activation_delegate_save_state(cast(^Tech_Activation_Delegate)self))
}

tech_activation_delegate_v_start :: proc(self: ^I_Delegate) {
	tech_activation_delegate_start(cast(^Tech_Activation_Delegate)self)
}

tech_activation_delegate_new :: proc() -> ^Tech_Activation_Delegate {
	self := new(Tech_Activation_Delegate)
	self.need_to_initialize = true
	self.base_triple_a_delegate.abstract_delegate.i_delegate.delegate_currently_requires_user_input = tech_activation_delegate_v_delegate_currently_requires_user_input
	self.base_triple_a_delegate.abstract_delegate.i_delegate.end = tech_activation_delegate_v_end
	self.base_triple_a_delegate.abstract_delegate.i_delegate.get_remote_type = tech_activation_delegate_v_get_remote_type
	self.base_triple_a_delegate.abstract_delegate.i_delegate.load_state = tech_activation_delegate_v_load_state
	self.base_triple_a_delegate.abstract_delegate.i_delegate.save_state = tech_activation_delegate_v_save_state
	self.base_triple_a_delegate.abstract_delegate.i_delegate.start = tech_activation_delegate_v_start
	return self
}

// games.strategy.triplea.delegate.TechActivationDelegate#saveState()
// Builds a TechActivationExtendedDelegateState. `superState` is the
// parent delegate's save_state (Base_Triple_A_Delegate has no override
// beyond its own implementation). `super_state` is rawptr so a
// Base_Delegate_State pointer can be packed in.
tech_activation_delegate_save_state :: proc(
	self: ^Tech_Activation_Delegate,
) -> ^Tech_Activation_Extended_Delegate_State {
	state := tech_activation_extended_delegate_state_new()
	state.super_state = rawptr(base_triple_a_delegate_save_state(&self.base_triple_a_delegate))
	state.need_to_initialize = self.need_to_initialize
	return state
}

// games.strategy.triplea.delegate.TechActivationDelegate#advancesAsString(java.util.Collection)
// Static helper that joins advance names with ", " and " and " before
// the final element, mirroring Java's StringBuilder loop exactly.
tech_activation_delegate_advances_as_string :: proc(advances: [dynamic]^Tech_Advance) -> string {
	count := i32(len(advances))
	b: strings.Builder
	strings.builder_init(&b)
	for advance in advances {
		strings.write_string(&b, advance.named.base.name)
		count -= 1
		if count > 1 {
			strings.write_string(&b, ", ")
		}
		if count == 1 {
			strings.write_string(&b, " and ")
		}
	}
	return strings.to_string(b)
}

// games.strategy.triplea.delegate.TechActivationDelegate#delegateCurrentlyRequiresUserInput()
// Java returns `false` unconditionally.
tech_activation_delegate_delegate_currently_requires_user_input :: proc(self: ^Tech_Activation_Delegate) -> bool {
	return false
}

// games.strategy.triplea.delegate.TechActivationDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value, matching the convention used by the other
// delegates that have no remote type.
tech_activation_delegate_get_remote_type :: proc(self: ^Tech_Activation_Delegate) -> typeid {
	return nil
}

// games.strategy.triplea.delegate.TechActivationDelegate#loadState(java.io.Serializable)
// Java casts the Serializable to TechActivationExtendedDelegateState,
// chains super.loadState with its superState, then restores
// needToInitialize.
tech_activation_delegate_load_state :: proc(
	self: ^Tech_Activation_Delegate,
	state: ^Tech_Activation_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
}

// games.strategy.triplea.delegate.TechActivationDelegate#shareTechnology()
// For each player on the current player's PlayerAttachment.shareTechnology
// list, intersect the current player's already-acquired tech advances with
// that player's still-available techs, emit a history event, and grant the
// shared advances. Java's `CollectionUtils.intersection` is inlined as a
// typed loop (the rawptr-only collection_utils_intersection would lose
// the ^Tech_Advance element type), matching the inline-difference pattern
// used by technology_delegate_get_available_techs.
tech_activation_delegate_share_technology :: proc(self: ^Tech_Activation_Delegate) {
	player := self.player
	bridge := self.bridge
	pa := player_attachment_get(player)
	if pa == nil {
		return
	}
	share_with := player_attachment_get_share_technology(pa)
	if len(share_with) == 0 {
		return
	}
	frontier := game_data_get_technology_frontier(
		abstract_delegate_get_data(&self.abstract_delegate),
	)
	current_advances := tech_tracker_get_current_tech_advances(player, frontier)
	defer delete(current_advances)
	for p in share_with {
		available_techs := technology_delegate_get_available_techs(p, frontier)
		defer delete(available_techs)
		to_give := make([dynamic]^Tech_Advance, 0)
		defer delete(to_give)
		for ca in current_advances {
			for at in available_techs {
				if ca == at {
					append(&to_give, ca)
					break
				}
			}
		}
		if len(to_give) > 0 {
			advances_text := tech_activation_delegate_advances_as_string(to_give)
			defer delete(advances_text)
			event := fmt.aprintf(
				"%s giving technology to %s: %s",
				player.named.base.name,
				p.named.base.name,
				advances_text,
			)
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(bridge),
				event,
			)
			delete(event)
			for advance in to_give {
				tech_tracker_add_advance(p, bridge, advance)
			}
		}
	}
}

// games.strategy.triplea.delegate.TechActivationDelegate#start()
// Java body, performed only on the first call after needToInitialize:
//   1. super.start()
//   2. read advances scheduled by the TechnologyDelegate this turn,
//      log a history event "<player> activating <list>" and call
//      TechTracker.addAdvance for each one
//   3. clear those advances from the TechnologyDelegate
//   4. if Properties.getTriggers(data) is on, build the AND-chained
//      Predicate<TriggerAttachment>:
//        availableUses
//          .and(whenOrDefaultMatch(null, null))
//          .and(unitPropertyMatch().or(techMatch()).or(supportMatch()))
//      collect every trigger matching that predicate for the current
//      player, test the conditions they need, retain the satisfied
//      ones, and fire unitProperty / tech / support trigger changes
//      with the default FireTriggerParams(null, null, true, true,
//      true, true)
//   5. shareTechnology(); needToInitialize = false
//
// The capturing whenOrDefaultMatch is paired with the bare unit/tech/
// support match procs through a small per-call ctx struct, mirroring
// the convention used by base_triple_a_delegate / end_turn_delegate.
Tech_Activation_Delegate_Ctx_trigger_match :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

tech_activation_delegate_lambda_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Tech_Activation_Delegate_Ctx_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	return trigger_attachment_lambda_unit_property_match(t) ||
		trigger_attachment_lambda_tech_match(t) ||
		trigger_attachment_lambda_support_match(t)
}

tech_activation_delegate_start :: proc(self: ^Tech_Activation_Delegate) {
	base_triple_a_delegate_start(&self.base_triple_a_delegate)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if !self.need_to_initialize {
		return
	}
	tech_delegate := game_data_get_tech_delegate(data)
	advances := technology_delegate_get_advances(tech_delegate, self.player)
	if len(advances) > 0 {
		adv_str := tech_activation_delegate_advances_as_string(advances)
		defer delete(adv_str)
		event := fmt.aprintf("%s activating %s", self.player.named.base.name, adv_str)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			event,
		)
		delete(event)
		for advance in advances {
			tech_tracker_add_advance(self.player, self.bridge, advance)
		}
	}
	technology_delegate_clear_advances(tech_delegate, self.player)
	if properties_get_triggers(game_data_get_properties(data)) {
		// availableUses .and(whenOrDefaultMatch(null, null))
		when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match("", "")
		match_ctx := new(Tech_Activation_Delegate_Ctx_trigger_match)
		match_ctx.when_pred = when_pred
		match_ctx.when_ctx = when_ctx
		players_set := make(map[^Game_Player]struct {})
		defer delete(players_set)
		players_set[self.player] = {}
		to_fire_possible := trigger_attachment_collect_for_all_triggers_matching(
			players_set,
			tech_activation_delegate_lambda_trigger_match,
			rawptr(match_ctx),
		)
		defer delete(to_fire_possible)
		if len(to_fire_possible) > 0 {
			tested_conditions := trigger_attachment_collect_tests_for_all_triggers_simple(
				to_fire_possible,
				self.bridge,
			)
			defer delete(tested_conditions)
			sat_pred, sat_ctx := abstract_trigger_attachment_is_satisfied_match(tested_conditions)
			to_fire_satisfied := make(map[^Trigger_Attachment]struct {})
			defer delete(to_fire_satisfied)
			for t in to_fire_possible {
				if sat_pred(sat_ctx, t) {
					to_fire_satisfied[t] = {}
				}
			}
			params := fire_trigger_params_new("", "", true, true, true, true)
			trigger_attachment_trigger_unit_property_change(
				to_fire_satisfied,
				self.bridge,
				params,
			)
			trigger_attachment_trigger_tech_change(to_fire_satisfied, self.bridge, params)
			trigger_attachment_trigger_support_change(to_fire_satisfied, self.bridge, params)
		}
	}
	tech_activation_delegate_share_technology(self)
	self.need_to_initialize = false
}

// games.strategy.triplea.delegate.TechActivationDelegate#end()
// Java body:
//   super.end();
//   needToInitialize = true;
tech_activation_delegate_end :: proc(self: ^Tech_Activation_Delegate) {
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	self.need_to_initialize = true
}
