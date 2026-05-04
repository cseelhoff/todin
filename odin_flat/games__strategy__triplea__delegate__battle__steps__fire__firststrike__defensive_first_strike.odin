package game

Defensive_First_Strike :: struct {
	using battle_step:  Battle_Step,
	battle_state:    ^Battle_State,
	battle_actions:  ^Battle_Actions,
	state:           Defensive_First_Strike_State,
	return_fire:     Must_Fight_Battle_Return_Fire,
}

defensive_first_strike_get_order :: proc(self: ^Defensive_First_Strike) -> Battle_Step_Order {
	if self.state == .REGULAR {
		return .FIRST_STRIKE_DEFENSIVE_REGULAR
	}
	return .FIRST_STRIKE_DEFENSIVE
}

defensive_first_strike_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

// Java: List<StepDetails> getAllStepDetails()
//   return this.state == State.NOT_APPLICABLE
//       ? List.of()
//       : getSteps().stream()
//           .flatMap(step -> step.getAllStepDetails().stream())
//           .collect(Collectors.toList());
defensive_first_strike_get_all_step_details :: proc(
	self: ^Defensive_First_Strike,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	if self.state == .NOT_APPLICABLE {
		return out
	}
	// Forward ref: defensive_first_strike_get_steps is defined later in
	// the package (mirrors private getSteps() on the Java side).
	steps := defensive_first_strike_get_steps(self)
	for step in steps {
		details := defensive_first_strike_lambda__get_all_step_details__0(step)
		for d in details {
			append(&out, d)
		}
	}
	return out
}

// Java: void execute(ExecutionStack stack, IDelegateBridge bridge)
//   if (this.state == State.NOT_APPLICABLE) { return; }
//   final List<BattleStep> steps = getSteps();
//   // steps go in reverse order on the stack
//   Collections.reverse(steps);
//   steps.forEach(stack::push);
defensive_first_strike_execute :: proc(
	self: ^Defensive_First_Strike,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if self.state == .NOT_APPLICABLE {
		return
	}
	steps := defensive_first_strike_get_steps(self)
	n := len(steps)
	// Collections.reverse: in-place reverse of the dynamic array.
	for i in 0 ..< n / 2 {
		steps[i], steps[n - 1 - i] = steps[n - 1 - i], steps[i]
	}
	// steps.forEach(stack::push): Battle_Step embeds I_Executable at
	// offset 0, matching the move_performer.odin pattern.
	for step in steps {
		execution_stack_push_one(stack, cast(^I_Executable)step)
	}
}
