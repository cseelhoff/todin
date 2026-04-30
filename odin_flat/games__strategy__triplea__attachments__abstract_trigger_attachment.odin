package game

Abstract_Trigger_Attachment :: struct {
	using abstract_conditions_attachment: Abstract_Conditions_Attachment,
	uses: i32,
	used_this_round: bool,
	notification: string,
	when_triggers: [dynamic]^Tuple(string, string),
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.AbstractTriggerAttachment
//
// Static factory methods that produce Java Predicate<TriggerAttachment>
// closures follow the project's predicate-pair convention: each capturing
// factory allocates a per-call context struct holding the captured
// variables and returns the pair (proc(rawptr, ^Trigger_Attachment) -> bool,
// rawptr). Non-capturing lambdas use the simpler bare-proc form.
//
// In this port, an Odin `string` field whose Java counterpart was a
// @Nullable String uses the empty string "" to represent Java null.

// ---------------------------------------------------------------------------
// availableUses static field initializer:
//   t -> t.getUses() != 0
// (lambda$static$0)
// ---------------------------------------------------------------------------
abstract_trigger_attachment_lambda_static_0 :: proc(t: ^Trigger_Attachment) -> bool {
	return t.uses != 0
}

// ---------------------------------------------------------------------------
// triggerSetUsedForThisRound predicate (lambda$triggerSetUsedForThisRound$1):
//   ta -> ta.getUsedThisRound() && ta.getUses() > 0
// ---------------------------------------------------------------------------
abstract_trigger_attachment_lambda_trigger_set_used_for_this_round_1 :: proc(
	ta: ^Trigger_Attachment,
) -> bool {
	return ta.used_this_round && ta.uses > 0
}

// ---------------------------------------------------------------------------
// isSatisfiedMatch(Map<ICondition, Boolean>) -> Predicate<TriggerAttachment>
//   return t -> t.isSatisfied(testedConditions);
// ---------------------------------------------------------------------------
Abstract_Trigger_Attachment_Ctx_is_satisfied_match :: struct {
	tested_conditions: map[^I_Condition]bool,
}

// lambda$isSatisfiedMatch$2(Map, TriggerAttachment) -> bool
abstract_trigger_attachment_lambda_is_satisfied_match_2 :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Abstract_Trigger_Attachment_Ctx_is_satisfied_match)ctx_ptr
	return abstract_conditions_attachment_is_satisfied(
		&t.abstract_conditions_attachment,
		ctx.tested_conditions,
	)
}

abstract_trigger_attachment_is_satisfied_match :: proc(
	tested_conditions: map[^I_Condition]bool,
) -> (proc(rawptr, ^Trigger_Attachment) -> bool, rawptr) {
	ctx := new(Abstract_Trigger_Attachment_Ctx_is_satisfied_match)
	ctx.tested_conditions = tested_conditions
	return abstract_trigger_attachment_lambda_is_satisfied_match_2, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// whenOrDefaultMatch(beforeOrAfter, stepName) -> Predicate<TriggerAttachment>
//
// Both string args may be Java null. The lambda body itself
// (lambda$whenOrDefaultMatch$3) lives at method_layer 1 — the factory
// captures the args here and forwards them via the context. By
// project convention, an empty Odin string represents Java null for
// these @NonNls @Nullable parameters; in TripleA the only non-null
// values seen are exactly "before" / "after" and a step name, never "".
// ---------------------------------------------------------------------------
Abstract_Trigger_Attachment_Ctx_when_or_default_match :: struct {
	before_or_after: string,
	step_name:       string,
}

abstract_trigger_attachment_when_or_default_match :: proc(
	before_or_after: string,
	step_name: string,
) -> (proc(rawptr, ^Trigger_Attachment) -> bool, rawptr) {
	ctx := new(Abstract_Trigger_Attachment_Ctx_when_or_default_match)
	ctx.before_or_after = before_or_after
	ctx.step_name = step_name
	return abstract_trigger_attachment_lambda_when_or_default_match_3, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// notificationMatch() -> Predicate<TriggerAttachment>
//   return t -> t.getNotification() != null;
// Non-capturing — bare proc form.
// ---------------------------------------------------------------------------
// lambda$notificationMatch$4(TriggerAttachment) -> bool
abstract_trigger_attachment_lambda_notification_match_4 :: proc(
	t: ^Trigger_Attachment,
) -> bool {
	return t.notification != ""
}

abstract_trigger_attachment_notification_match :: proc(
) -> proc(^Trigger_Attachment) -> bool {
	return abstract_trigger_attachment_lambda_notification_match_4
}

// ---------------------------------------------------------------------------
// getPropertyOrEmpty inline lambdas:
//   lambda$getPropertyOrEmpty$6 -> () -> -1     (default IntSupplier for "uses")
//   lambda$getPropertyOrEmpty$7 -> l -> { throw ... } (rejects setting "trigger")
// Both are non-capturing helpers consumed by the layer-1 body of
// getPropertyOrEmpty.
// ---------------------------------------------------------------------------
abstract_trigger_attachment_lambda_get_property_or_empty_6 :: proc() -> i32 {
	return -1
}

abstract_trigger_attachment_lambda_get_property_or_empty_7 :: proc(
	l: [dynamic]^Rules_Attachment,
) {
	// Java: throw new IllegalStateException("Can't set trigger directly");
	panic("Can't set trigger directly")
}

