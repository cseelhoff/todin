package game

// games.strategy.engine.data.GameSequence
//
// Ordered list of GameStep + cursor (round, step index).

Game_Sequence :: struct {
	using game_data_component: Game_Data_Component,
	steps:         [dynamic]^Game_Step,
	current_index: i32,
	round:         i32,
	round_offset:  i32,
}

// Mirrors Java GameSequence#addStep(GameStep):
//     steps.add(step);
game_sequence_add_step :: proc(self: ^Game_Sequence, step: ^Game_Step) {
	append(&self.steps, step)
}

// Mirrors Java GameSequence#getRound():
//     return round + roundOffset;
game_sequence_get_round :: proc(self: ^Game_Sequence) -> i32 {
	return self.round + self.round_offset
}

// Mirrors Java GameSequence#getStepIndex():
//     return currentIndex;
game_sequence_get_step_index :: proc(self: ^Game_Sequence) -> i32 {
	return self.current_index
}

// Mirrors Java GameSequence#size():
//     return steps.size();
game_sequence_size :: proc(self: ^Game_Sequence) -> i32 {
	return i32(len(self.steps))
}

// Mirrors Java GameSequence#iterator() (from Iterable<GameStep>):
//     return steps.iterator();
// Returns the underlying [dynamic]^Game_Step so callers can iterate with
// `for s in game_sequence_iterator(seq)`.
game_sequence_iterator :: proc(self: ^Game_Sequence) -> [dynamic]^Game_Step {
	return self.steps
}

// Mirrors Java GameSequence#next() (synchronized):
//     currentIndex++;
//     if (currentIndex >= steps.size()) {
//         currentIndex = 0;
//         round++;
//         return true;
//     }
//     return false;
game_sequence_next :: proc(self: ^Game_Sequence) -> bool {
	self.current_index += 1
	if self.current_index >= i32(len(self.steps)) {
		self.current_index = 0
		self.round += 1
		return true
	}
	return false
}

// Mirrors the int-overload Java GameSequence#getStep(int):
//     if ((index < 0) || (index >= steps.size())) {
//         throw new IllegalArgumentException(...);
//     }
//     return steps.get(index);
// Renamed to disambiguate from the no-arg getStep().
game_sequence_get_step_at :: proc(self: ^Game_Sequence, index: i32) -> ^Game_Step {
	if index < 0 || index >= i32(len(self.steps)) {
		return nil
	}
	return self.steps[index]
}

// Mirrors Java GameSequence#getStep() (synchronized):
//     if (currentIndex < 0) currentIndex = 0;
//     if (currentIndex >= steps.size()) next();
//     return getStep(currentIndex);
game_sequence_get_step :: proc(self: ^Game_Sequence) -> ^Game_Step {
	if self.current_index < 0 {
		self.current_index = 0
	}
	if self.current_index >= i32(len(self.steps)) {
		game_sequence_next(self)
	}
	return game_sequence_get_step_at(self, self.current_index)
}

// Mirrors Java GameSequence#setRoundOffset(int):
//     this.roundOffset = roundOffset;
game_sequence_set_round_offset :: proc(self: ^Game_Sequence, value: i32) {
	self.round_offset = value
}

// Mirrors Java GameSequence#setStepIndex(int):
//     if ((newIndex < 0) || (newIndex >= steps.size())) {
//         throw new IllegalArgumentException("New index out of range: " + newIndex);
//     }
//     currentIndex = newIndex;
game_sequence_set_step_index :: proc(self: ^Game_Sequence, value: i32) {
	if value < 0 || value >= i32(len(self.steps)) {
		return
	}
	self.current_index = value
}

// Mirrors Java GameSequence#<init>(GameData):
//     super(data);
//     // field defaults: steps = new ArrayList<>(); currentIndex = 0;
//     // round = 1; roundOffset = 0;
game_sequence_new :: proc(data: ^Game_Data) -> ^Game_Sequence {
	self := new(Game_Sequence)
	self.game_data_component = make_Game_Data_Component(data)
	self.steps = make([dynamic]^Game_Step)
	self.current_index = 0
	self.round = 1
	self.round_offset = 0
	return self
}
