package game

Production_Frontier :: struct {
	using default_named: Default_Named,
	rules:               [dynamic]^Production_Rule,
	cached_rules:        [dynamic]^Production_Rule,
}

