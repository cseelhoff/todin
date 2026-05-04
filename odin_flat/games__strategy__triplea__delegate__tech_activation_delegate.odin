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
tech_activation_delegate_new :: proc() -> ^Tech_Activation_Delegate {
	self := new(Tech_Activation_Delegate)
	self.need_to_initialize = true
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
