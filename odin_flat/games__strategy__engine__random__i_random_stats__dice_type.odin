package game

// Java owners covered by this file:
//   - games.strategy.engine.random.IRandomStats$DiceType

// Identifies the purpose for which dice are rolled. Used to group dice
// statistics into various buckets.
Dice_Type :: enum {
	COMBAT,
	BOMBING,
	NONCOMBAT,
	TECH,
	ENGINE,
}

