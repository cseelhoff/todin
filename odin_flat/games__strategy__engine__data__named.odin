package game

// games.strategy.engine.data.Named (interface)
//
// Java is an interface; in Odin we expose it as a struct that holds the
// canonical name storage. Subtypes embed `using named: Named`, giving the
// `obj.named.base.name` access pattern the snapshot harness expects.

Default_Named_Base :: struct {
	name: string,
}

Named :: struct {
	base: Default_Named_Base,
}
