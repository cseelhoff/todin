package game

Game_Play :: struct {
	delegates: [dynamic]^Game_Play_Delegate,
	sequence:  ^Game_Play_Sequence,
	offset:    ^Game_Play_Offset,
}
// Java owners covered by this file:
//   - org.triplea.map.data.elements.GamePlay
