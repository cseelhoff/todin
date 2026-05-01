package game

import "core:strings"

Tech_Activation_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
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
