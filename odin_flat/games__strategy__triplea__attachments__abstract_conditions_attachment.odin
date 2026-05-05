package game

import "core:strconv"
import "core:strings"

Abstract_Conditions_Attachment :: struct {
	using default_attachment: Default_Attachment,
	conditions:                  [dynamic]^Rules_Attachment,
	condition_type:              string,
	invert:                      bool,
	chance:                      string,
	chance_increment_on_failure: i32,
	chance_decrement_on_success: i32,
}

// ---------------------------------------------------------------------------
// File-private helpers used by the recursive testers below.
//
// In this port, `^I_Condition` is an opaque identity pointer derived from
// `cast(^I_Condition)rawptr(concrete)` (see `rules_attachment_is_satisfied`).
// Every concrete ICondition impl (RulesAttachment, AbstractTriggerAttachment
// subtypes, AbstractUserActionAttachment subtypes) lays out
// Abstract_Conditions_Attachment at offset 0 via its `using` chain, so the
// reverse cast `cast(^Abstract_Conditions_Attachment)rawptr(ic)` is the way
// we access the per-condition fields the Java side reaches via virtual
// `getConditions()` / `getInvert()` / `getConditionType()` calls.
// ---------------------------------------------------------------------------

// AbstractConditionsAttachment#areConditionsMet(rulesToTest, testedConditions, conditionType).
// Untracked in the AI port surface but required by ICondition.isSatisfied
// dispatch; mirrors the Java switch-on-conditionType: AND / OR / "y" / "y-z".
@(private = "file")
are_conditions_met_local :: proc(
	rules_to_test: []^I_Condition,
	tested_conditions: map[^I_Condition]bool,
	condition_type: string,
) -> bool {
	met := false
	switch condition_type {
	case "AND":
		for c in rules_to_test {
			met = tested_conditions[c]
			if !met {
				break
			}
		}
	case "OR":
		for c in rules_to_test {
			met = tested_conditions[c]
			if met {
				break
			}
		}
	case:
		// Numeric form: "y" (exactly y true) or "y-z" (between y and z, inclusive).
		idx := strings.index_byte(condition_type, '-')
		count := 0
		for c in rules_to_test {
			if tested_conditions[c] {
				count += 1
			}
		}
		if idx < 0 {
			start, _ := strconv.parse_int(condition_type)
			met = count == start
		} else {
			start, _ := strconv.parse_int(condition_type[:idx])
			end, _ := strconv.parse_int(condition_type[idx + 1:])
			met = count >= start && count <= end
		}
	}
	return met
}

// Virtual dispatch for ICondition.isSatisfied(Map, IDelegateBridge).
// Mirrors AbstractConditionsAttachment#isSatisfied(Map, IDelegateBridge):
// honor an existing cached result, otherwise recompute via areConditionsMet
// against the condition's own sub-conditions, accounting for `invert`. The
// RulesAttachment two-arg override (heavy game-state checks) is outside the
// AI snapshot surface and therefore not special-cased here.
@(private = "file")
i_condition_is_satisfied_with_bridge :: proc(
	c: ^I_Condition,
	tested_conditions: map[^I_Condition]bool,
	delegate_bridge: ^I_Delegate_Bridge,
) -> bool {
	if v, ok := tested_conditions[c]; ok {
		return v
	}
	aca := cast(^Abstract_Conditions_Attachment)rawptr(c)
	rules_to_test := make([dynamic]^I_Condition, 0, len(aca.conditions))
	defer delete(rules_to_test)
	for sub in aca.conditions {
		append(&rules_to_test, cast(^I_Condition)rawptr(sub))
	}
	met := are_conditions_met_local(rules_to_test[:], tested_conditions, aca.condition_type)
	return met != aca.invert
}

// ---------------------------------------------------------------------------
// AbstractConditionsAttachment#getAllConditionsRecursive(Set, Set)
//
// Java:
//   final Set<ICondition> allConditionsNeededSoFar =
//       Optional.ofNullable(initialAllConditionsNeededSoFar).orElseGet(HashSet::new);
//   allConditionsNeededSoFar.addAll(startingListOfConditions);
//   for (final ICondition condition : startingListOfConditions) {
//     for (final ICondition subCondition : condition.getConditions()) {
//       if (!allConditionsNeededSoFar.contains(subCondition)) {
//         allConditionsNeededSoFar.addAll(
//             getAllConditionsRecursive(Set.of(subCondition), allConditionsNeededSoFar));
//       }
//     }
//   }
//   return allConditionsNeededSoFar;
//
// In Odin, `Set<ICondition>` is `map[^I_Condition]struct{}`. A nil/zero
// initial set on the Java side becomes a freshly allocated map here.
// `condition.getConditions()` resolves through the offset-0 cast to
// Abstract_Conditions_Attachment (see notes above).
// ---------------------------------------------------------------------------
abstract_conditions_attachment_get_all_conditions_recursive :: proc(
	starting_list_of_conditions: map[^I_Condition]struct {},
	initial_all_conditions_needed_so_far: map[^I_Condition]struct {},
) -> map[^I_Condition]struct {} {
	all_conditions_needed_so_far := initial_all_conditions_needed_so_far
	if all_conditions_needed_so_far == nil {
		all_conditions_needed_so_far = make(map[^I_Condition]struct {})
	}
	for cond in starting_list_of_conditions {
		all_conditions_needed_so_far[cond] = {}
	}
	for cond in starting_list_of_conditions {
		aca := cast(^Abstract_Conditions_Attachment)rawptr(cond)
		for sub in aca.conditions {
			sub_ic := cast(^I_Condition)rawptr(sub)
			if _, present := all_conditions_needed_so_far[sub_ic]; !present {
				// Java passes Set.of(subCondition); model as a single-element set.
				singleton := make(map[^I_Condition]struct {})
				singleton[sub_ic] = {}
				abstract_conditions_attachment_get_all_conditions_recursive(
					singleton,
					all_conditions_needed_so_far,
				)
				delete(singleton)
			}
		}
	}
	return all_conditions_needed_so_far
}

// ---------------------------------------------------------------------------
// AbstractConditionsAttachment#testAllConditionsRecursive(Set, Map, IDelegateBridge)
//
// Java:
//   final Map<ICondition, Boolean> allConditionsTestedSoFar =
//       Optional.ofNullable(initialAllConditionsTestedSoFar).orElseGet(HashMap::new);
//   for (final ICondition c : rules) {
//     if (!allConditionsTestedSoFar.containsKey(c)) {
//       testAllConditionsRecursive(
//           new HashSet<>(c.getConditions()), allConditionsTestedSoFar, delegateBridge);
//       allConditionsTestedSoFar.put(c, c.isSatisfied(allConditionsTestedSoFar, delegateBridge));
//     }
//   }
//   return allConditionsTestedSoFar;
// ---------------------------------------------------------------------------
abstract_conditions_attachment_test_all_conditions_recursive :: proc(
	rules: map[^I_Condition]struct {},
	initial_all_conditions_tested_so_far: map[^I_Condition]bool,
	delegate_bridge: ^I_Delegate_Bridge,
) -> map[^I_Condition]bool {
	all_conditions_tested_so_far := initial_all_conditions_tested_so_far
	if all_conditions_tested_so_far == nil {
		all_conditions_tested_so_far = make(map[^I_Condition]bool)
	}
	for c in rules {
		if _, tested := all_conditions_tested_so_far[c]; tested {
			continue
		}
		// Recurse into c's sub-conditions: HashSet<>(c.getConditions()).
		aca := cast(^Abstract_Conditions_Attachment)rawptr(c)
		sub_set := make(map[^I_Condition]struct {})
		for sub in aca.conditions {
			sub_set[cast(^I_Condition)rawptr(sub)] = {}
		}
		abstract_conditions_attachment_test_all_conditions_recursive(
			sub_set,
			all_conditions_tested_so_far,
			delegate_bridge,
		)
		delete(sub_set)
		all_conditions_tested_so_far[c] = i_condition_is_satisfied_with_bridge(
			c,
			all_conditions_tested_so_far,
			delegate_bridge,
		)
	}
	return all_conditions_tested_so_far
}

// AbstractConditionsAttachment#isSatisfied(Map<ICondition, Boolean>)
// Java: return isSatisfied(testedConditions, null);
// Java 2-arg form (delegate_bridge unused outside RulesAttachment override):
//   if (testedConditions.containsKey(this)) return testedConditions.get(this);
//   return areConditionsMet(new ArrayList<>(getConditions()), testedConditions,
//       getConditionType()) != getInvert();
abstract_conditions_attachment_is_satisfied :: proc(
	self: ^Abstract_Conditions_Attachment,
	tested_conditions: map[^I_Condition]bool,
) -> bool {
	self_ic := cast(^I_Condition)rawptr(self)
	if v, ok := tested_conditions[self_ic]; ok {
		return v
	}
	rules_to_test := make([dynamic]^I_Condition, 0, len(self.conditions))
	defer delete(rules_to_test)
	for sub in self.conditions {
		append(&rules_to_test, cast(^I_Condition)rawptr(sub))
	}
	met := are_conditions_met_local(rules_to_test[:], tested_conditions, self.condition_type)
	return met != self.invert
}
