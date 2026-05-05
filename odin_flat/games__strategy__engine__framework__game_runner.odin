package game

import "core:os"
import "core:strings"

Game_Runner :: struct {}

game_runner_exit_on_end_game :: proc() -> bool {
	v := os.get_env_alloc("triplea.exit.on.game.end", context.allocator)
	defer delete(v, context.allocator)
	return strings.equal_fold(v, "true")
}

game_runner_headless :: proc() -> bool {
	v := os.get_env_alloc("triplea.headless", context.allocator)
	defer delete(v, context.allocator)
	return strings.equal_fold(v, "true")
}

