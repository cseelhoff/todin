package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.weak.WeakAi

Weak_Ai :: struct {
	using abstract_ai: Abstract_Ai,
}

// games.strategy.triplea.ai.weak.WeakAi#<init>(java.lang.String)
//   public WeakAi(final String name) {
//     // This class may be used as fallback implementation
//     // for Player. If this is the case assign the "Temporary" label
//     super(name, "Temporary");
//   }
weak_ai_new :: proc(name: string) -> ^Weak_Ai {
	self := new(Weak_Ai)
	self.name = name
	self.player_label = "Temporary"
	return self
}
