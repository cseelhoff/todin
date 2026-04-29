package game

Repair_Frontier :: struct {
	using default_named: Default_Named,
	rules:        [dynamic]^Repair_Rule,
	cached_rules: [dynamic]^Repair_Rule,
}
