package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.AaRoll

Aa_Roll :: struct {
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

aa_roll_new :: proc(roll_support_from_friends: ^Available_Supports, roll_support_from_enemies: ^Available_Supports) -> ^Aa_Roll {
	self := new(Aa_Roll)
	self.support_from_friends = roll_support_from_friends
	self.support_from_enemies = roll_support_from_enemies
	return self
}

