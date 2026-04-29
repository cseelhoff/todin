package game

Tech_Attachment :: struct {
	using parent: Default_Attachment,
	tech_cost: i32,
	heavy_bomber: bool,
	long_range_air: bool,
	jet_power: bool,
	rocket: bool,
	industrial_technology: bool,
	super_sub: bool,
	destroyer_bombard: bool,
	improved_artillery_support: bool,
	paratroopers: bool,
	increased_factory_production: bool,
	war_bonds: bool,
	mechanized_infantry: bool,
	aa_radar: bool,
	shipyards: bool,
	generic_tech: map[string]bool,
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.TechAttachment

