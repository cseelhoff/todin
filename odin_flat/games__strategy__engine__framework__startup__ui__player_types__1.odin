package game

Player_Types_1 :: struct {}

// Java: anonymous subclass `new Type(label) { ... }` in PlayerTypes.WEAK_AI.
// The synthetic `<init>(String)` just forwards to the enclosing `Type(label)`
// constructor (which delegates to `Type(label, true)`). The owner struct here
// has no fields of its own, so the Odin port allocates a new instance and
// returns it. Field initialization for the embedded `Player_Types_Type` is
// not performed because Phase A did not embed it on this owner.
player_types_1_new :: proc(label: string) -> ^Player_Types_1 {
	return new(Player_Types_1)
}
