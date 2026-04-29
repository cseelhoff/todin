package game

// Java: games.strategy.engine.delegate.IDelegate
// Interface — Java declares `String getName()`. Odin mirrors this with a
// `name: string` field; concrete delegates embed `using i_delegate: I_Delegate`
// (transitively via Abstract_Delegate) so polymorphic name lookups through
// `^I_Delegate` resolve to the same storage as `concrete.name`.

I_Delegate :: struct {
	name: string,
}

