package game

Firing_Group_Suicide_And_Non_Suicide :: struct {
	suicide_groups:    map[^Unit_Type][dynamic]^Unit,
	non_suicide_group: [dynamic]^Unit,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.fire.FiringGroup$SuicideAndNonSuicide

