package game

// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.DummyPlayer

Dummy_Player :: struct {
	using abstract_ai: Abstract_Ai,
	keep_at_least_one_land:   bool,
	retreat_after_round:      i32,
	retreat_after_x_units_left: i32,
	retreat_when_only_air_left: bool,
	bridge:                   ^Dummy_Delegate_Bridge,
	is_attacker:              bool,
	order_of_losses:          [dynamic]^Unit,
}

dummy_player_get_battle :: proc(self: ^Dummy_Player) -> ^Must_Fight_Battle {
	return dummy_delegate_bridge_get_battle(self.bridge)
}

// games.strategy.triplea.odds.calculator.DummyPlayer#<init>(
//   DummyDelegateBridge, boolean, String, List<Unit>, boolean, int, int, boolean)
//   Mirrors the Java constructor: super(name, "DummyPlayer"); then
//   stores all eight fields.
dummy_player_new :: proc(
	dummy_delegate_bridge: ^Dummy_Delegate_Bridge,
	attacker: bool,
	name: string,
	order_of_losses: [dynamic]^Unit,
	keep_at_least_one_land: bool,
	retreat_after_round: i32,
	retreat_after_x_units_left: i32,
	retreat_when_only_air_left: bool,
) -> ^Dummy_Player {
	self := new(Dummy_Player)
	self.name = name
	self.player_label = "DummyPlayer"
	self.keep_at_least_one_land = keep_at_least_one_land
	self.retreat_after_round = retreat_after_round
	self.retreat_after_x_units_left = retreat_after_x_units_left
	self.retreat_when_only_air_left = retreat_when_only_air_left
	self.bridge = dummy_delegate_bridge
	self.is_attacker = attacker
	self.order_of_losses = order_of_losses
	return self
}

// games.strategy.triplea.odds.calculator.DummyPlayer#getOurUnits()
//   final MustFightBattle battle = getBattle();
//   if (battle == null) return null;
//   return new ArrayList<>(isAttacker ? battle.getAttackingUnits()
//                                     : battle.getDefendingUnits());
// Odin: returns a freshly-allocated [dynamic]^Unit copy, or nil if no
// battle. Callers distinguish "no battle" from "empty" via len + the
// pointer not being nil — we return a zero-length nil dynamic array
// for the null case (matches Java's null sentinel; getOurUnits's only
// caller, retreatQuery, checks `== null`).
dummy_player_get_our_units :: proc(self: ^Dummy_Player) -> [dynamic]^Unit {
	battle := dummy_player_get_battle(self)
	if battle == nil {
		return nil
	}
	src: ^[dynamic]^Unit
	if self.is_attacker {
		src = &battle.attacking_units
	} else {
		src = &battle.defending_units
	}
	out := make([dynamic]^Unit, 0, len(src^))
	for u in src^ {
		append(&out, u)
	}
	return out
}

// games.strategy.triplea.odds.calculator.DummyPlayer#getEnemyUnits()
//   Mirror of getOurUnits with attacker/defender swapped.
dummy_player_get_enemy_units :: proc(self: ^Dummy_Player) -> [dynamic]^Unit {
	battle := dummy_player_get_battle(self)
	if battle == nil {
		return nil
	}
	src: ^[dynamic]^Unit
	if self.is_attacker {
		src = &battle.defending_units
	} else {
		src = &battle.attacking_units
	}
	out := make([dynamic]^Unit, 0, len(src^))
	for u in src^ {
		append(&out, u)
	}
	return out
}

