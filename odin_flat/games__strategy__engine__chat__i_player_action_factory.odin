package game

// Java owners covered by this file:
//   - games.strategy.engine.chat.IPlayerActionFactory

I_Player_Action_Factory :: struct {
	mouse_on_player: proc(clicked_on: ^Chat_Participant) -> [dynamic]^Action,
}
