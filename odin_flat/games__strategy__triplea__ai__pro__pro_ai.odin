package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.ProAi

Pro_Ai :: struct {
	using abstract_pro_ai: Abstract_Pro_Ai,
}

// Static field on ProAi: shared across all ProAi instances.
// Java: private static final ConcurrentBattleCalculator concurrentCalc = new ConcurrentBattleCalculator();
// Initialized lazily on first ProAi construction (Java initializes it
// eagerly at class-load, but lazy init here yields the same observable
// behavior since nothing else in the port references this field before
// the first ProAi ctor runs).
@(private)
pro_ai_concurrent_calc: ^Concurrent_Battle_Calculator

// Java: public ProAi(String name, String playerLabel)
//   super(name, concurrentCalc, new ProData(), playerLabel);
//   GameShutdownRegistry.registerShutdownAction(() -> concurrentCalc.setGameData(null));
pro_ai_new :: proc(name: string, player_label: string) -> ^Pro_Ai {
	if pro_ai_concurrent_calc == nil {
		pro_ai_concurrent_calc = concurrent_battle_calculator_new()
	}
	self := new(Pro_Ai)
	base := abstract_pro_ai_new(name, pro_ai_concurrent_calc, pro_data_new(), player_label)
	self.abstract_pro_ai = base^
	free(base)
	game_shutdown_registry_register_shutdown_action(pro_ai_lambda__new__0)
	return self
}

// Java: () -> concurrentCalc.setGameData(null)
pro_ai_lambda__new__0 :: proc() {
	_ = concurrent_battle_calculator_set_game_data(pro_ai_concurrent_calc, nil)
}

// Java: @Override protected void prepareData(GameData data)
//   concurrentCalc.setGameData(data);
pro_ai_prepare_data :: proc(self: ^Pro_Ai, data: ^Game_Data) {
	_ = concurrent_battle_calculator_set_game_data(pro_ai_concurrent_calc, data)
}
