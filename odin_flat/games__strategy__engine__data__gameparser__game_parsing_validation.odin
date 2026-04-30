package game

// Ported from games.strategy.engine.data.gameparser.GameParsingValidation
// Phase A: type only.

Game_Parsing_Validation :: struct {
	data: ^Game_Data,
}

make_Game_Parsing_Validation :: proc(data: ^Game_Data) -> ^Game_Parsing_Validation {
	self := new(Game_Parsing_Validation)
	self.data = data
	return self
}

