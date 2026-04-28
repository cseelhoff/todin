package game

// games.strategy.engine.data.DefaultNamed
//
// Java's DefaultNamed is the abstract impl of Named. Its only field is the
// name, which we already encode via Default_Named_Base inside Named. This
// type is therefore an alias of Named to preserve the inheritance chain.

Default_Named :: struct {
	using named: Named,
}
