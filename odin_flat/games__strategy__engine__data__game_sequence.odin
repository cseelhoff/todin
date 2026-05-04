package game

import "core:fmt"
import "core:strings"

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

// Mirrors Java GameSequence#setRoundAndStep(int, String, GamePlayer) (synchronized):
//     round = currentRound;
//     boolean found = false;
//     for (int i = 0; i < steps.size(); i++) {
//         final GameStep step = steps.get(i);
//         if (step != null
//             && step.getDisplayName().equalsIgnoreCase(stepDisplayName)
//             && ((player == null && step.getPlayerId() == null)
//                 || (player != null && player.equals(step.getPlayerId())))) {
//             currentIndex = i;
//             found = true;
//             break;
//         }
//     }
//     if (!found) {
//         currentIndex = 0;
//         log.error("Step Not Found ({}:{}), will instead use: {}", ...);
//     }
// `player` is @Nullable; we mirror that with `^Game_Player` accepting nil.
// GamePlayer.equals compares by identity within a single GameData, matching
// the convention used elsewhere in the port (pointer equality).
game_sequence_set_round_and_step :: proc(self: ^Game_Sequence, current_round: i32, step_display_name: string, player: ^Game_Player) {
	self.round = current_round
	found := false
	for i in 0 ..< len(self.steps) {
		step := self.steps[i]
		if step == nil {
			continue
		}
		step_player := game_step_get_player_id(step)
		player_match := (player == nil && step_player == nil) || (player != nil && player == step_player)
		if strings.equal_fold(game_step_get_display_name(step), step_display_name) && player_match {
			self.current_index = i32(i)
			found = true
			break
		}
	}
	if !found {
		self.current_index = 0
		player_name := "null"
		if player != nil {
			player_name = default_named_get_name(&player.named_attachable.default_named)
		}
		fallback_name := ""
		if int(self.current_index) < len(self.steps) && self.steps[self.current_index] != nil {
			fallback_name = game_step_get_display_name(self.steps[self.current_index])
		}
		fmt.eprintf("Step Not Found (%s:%s), will instead use: %s\n", step_display_name, player_name, fallback_name)
	}
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
