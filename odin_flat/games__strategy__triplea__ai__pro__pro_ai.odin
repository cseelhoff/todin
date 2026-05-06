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
        // Wire the AbstractAi vtable: AbstractAi#purchase is abstract in
        // Java; AbstractProAi#purchase is the concrete override. The
        // thunk casts ^Abstract_Ai back to ^Abstract_Pro_Ai (safe because
        // Pro_Ai uses `using abstract_pro_ai`, so the receiver pointer
        // arithmetic for the embed is a no-op identity).
        self.purchase = pro_ai_v_purchase
        game_shutdown_registry_register_shutdown_action(pro_ai_lambda__new__0)
        return self
}

// Vtable thunk for Abstract_Ai#purchase => AbstractProAi#purchase.
@(private = "file")
pro_ai_v_purchase :: proc(
        self: ^Abstract_Ai,
        purchase_for_bid: bool,
        pus_to_spend: i32,
        purchase_delegate: ^I_Purchase_Delegate,
        data: ^Game_Data,
        player: ^Game_Player,
) {
        abstract_pro_ai_purchase(
                cast(^Abstract_Pro_Ai)self,
                purchase_for_bid,
                pus_to_spend,
                purchase_delegate,
                data,
                player,
        )
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
