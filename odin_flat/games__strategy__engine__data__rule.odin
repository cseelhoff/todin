package game

import "core:fmt"

// Java owner: games.strategy.engine.data.Rule
//
// Pure-interface superclass for ProductionRule and RepairRule;
// methods modeled as proc-typed fields, with `rule_*` dispatch
// procs as public entry points.

Rule :: struct {
	add_cost:    proc(self: ^Rule, resource: ^Resource, quantity: i32),
	get_name:    proc(self: ^Rule) -> string,
	get_results: proc(self: ^Rule) -> ^Integer_Map,
}

// games.strategy.engine.data.Rule#addCost(Resource, int)
rule_add_cost :: proc(self: ^Rule, resource: ^Resource, quantity: i32) {
	self.add_cost(self, resource, quantity)
}

// games.strategy.engine.data.Rule#getName()
rule_get_name :: proc(self: ^Rule) -> string {
	return self.get_name(self)
}

// games.strategy.engine.data.Rule#getResults()
rule_get_results :: proc(self: ^Rule) -> ^Integer_Map {
	return self.get_results(self)
}

// games.strategy.engine.data.Rule#addResult(NamedAttachable, int)
//
// Java guards with `obj instanceof UnitType || obj instanceof Resource`,
// throwing IllegalArgumentException otherwise. Odin's port lacks a
// dedicated Named_Kind tag for Resource (it embeds Named_Attachable but
// keeps the zero-value `.Other` discriminator); UnitType sets
// `.Unit_Type`. Other Named_Attachable embedders (Game_Player,
// Territory, Production_Rule, Production_Frontier, I_Attachment,
// Tech_Advance, Territory_Effect, Relationship_Type) set their own
// distinct kind, so the conservative check below rejects every kind
// except `.Unit_Type` and `.Other`, matching Java's intent.
rule_add_result :: proc(self: ^Rule, obj: ^Named_Attachable, quantity: i32) {
	kind := obj.default_named.named.kind
	if kind != .Unit_Type && kind != .Other {
		panic(fmt.tprintf(
			"results must be units or resources, not kind: %v", kind))
	}
	integer_map_put(rule_get_results(self), rawptr(obj), quantity)
}

// games.strategy.engine.data.Rule#getAnyResultKey()
//
// Java: CollectionUtils.getAny(getResults().keySet()). The Odin
// IntegerMap stores keys as `rawptr` (generic erasure substitute);
// cast back to ^Named_Attachable to mirror the Java return type.
rule_get_any_result_key :: proc(self: ^Rule) -> ^Named_Attachable {
	keys := integer_map_key_set(rule_get_results(self))
	defer delete(keys)
	return cast(^Named_Attachable)collection_utils_get_any(keys)
}
