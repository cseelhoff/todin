package game

import "core:os"
import "core:strings"

Game_Runner :: struct {}

game_runner_exit_on_end_game :: proc() -> bool {
	v := os.get_env("triplea.exit.on.game.end")
	defer delete(v)
	return strings.equal_fold(v, "true")
}

game_runner_headless :: proc() -> bool {
	v := os.get_env("triplea.headless")
	defer delete(v)
	return strings.equal_fold(v, "true")
}

