package game

Pro_Purchase_Option_Map :: struct {
	land_fodder_options:    [dynamic]^Pro_Purchase_Option,
	land_attack_options:    [dynamic]^Pro_Purchase_Option,
	land_defense_options:   [dynamic]^Pro_Purchase_Option,
	land_zero_move_options: [dynamic]^Pro_Purchase_Option,
	air_options:            [dynamic]^Pro_Purchase_Option,
	sea_defense_options:    [dynamic]^Pro_Purchase_Option,
	sea_transport_options:  [dynamic]^Pro_Purchase_Option,
	sea_carrier_options:    [dynamic]^Pro_Purchase_Option,
	sea_sub_options:        [dynamic]^Pro_Purchase_Option,
	aa_options:             [dynamic]^Pro_Purchase_Option,
	factory_options:        [dynamic]^Pro_Purchase_Option,
	special_options:        [dynamic]^Pro_Purchase_Option,
}
// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.data.ProPurchaseOptionMap

