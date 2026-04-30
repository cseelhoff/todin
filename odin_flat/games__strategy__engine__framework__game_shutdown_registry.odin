package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameShutdownRegistry
Game_Shutdown_Registry :: struct {
    shutdown_actions: [dynamic]proc(),
}

@(private="file")
g_game_shutdown_registry: Game_Shutdown_Registry

game_shutdown_registry_register_shutdown_action :: proc(action: proc()) {
    append(&g_game_shutdown_registry.shutdown_actions, action)
}

game_shutdown_registry_run_shutdown_actions :: proc() {
    for action in g_game_shutdown_registry.shutdown_actions {
        action()
    }
    clear(&g_game_shutdown_registry.shutdown_actions)
}

