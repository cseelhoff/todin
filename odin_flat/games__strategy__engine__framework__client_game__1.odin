package game

// Anonymous inner class #1 of games.strategy.engine.framework.ClientGame.
// Implements IGameModifiedChannel; captures the enclosing ClientGame instance.
// Java owners covered by this file:
//   - games.strategy.engine.framework.ClientGame$1

Client_Game_1 :: struct {
	this_0: ^Client_Game,
}

make_Client_Game_1 :: proc(this_0: ^Client_Game) -> ^Client_Game_1 {
	self := new(Client_Game_1)
	self.this_0 = this_0
	return self
}
