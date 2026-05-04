package game

// Java owner: games.strategy.triplea.delegate.power.calculator.CombatValueBuilder
// Utility class (Lombok @UtilityClass) with no instance fields.

Combat_Value_Builder :: struct {}

// Lombok @Builder(builderMethodName = "mainCombatValue") synthesizes a
// static factory that simply returns `new MainBuilder()`.
combat_value_builder_main_combat_value :: proc() -> ^Combat_Value_Builder_Main_Builder {
	return combat_value_builder_main_builder_new()
}

// Lombok @Builder(builderMethodName = "aaCombatValue") — returns a fresh AaBuilder.
combat_value_builder_aa_combat_value :: proc() -> ^Combat_Value_Builder_Aa_Builder {
	return combat_value_builder_aa_builder_new()
}

// Lombok @Builder(builderMethodName = "navalBombardmentCombatValue") — returns a fresh NavalBombardmentBuilder.
combat_value_builder_naval_bombardment_combat_value :: proc() -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	return combat_value_builder_naval_bombardment_builder_new()
}

// Java: CombatValueBuilder.buildMainCombatValue(...)
//   Package-private static factory backing the Lombok @Builder-generated
//   MainBuilder.build(). Mirrors the Java by populating a MainBuilder and
//   delegating to its terminal build(), which assembles either a
//   MainDefenseCombatValue or MainOffenseCombatValue depending on side.
combat_value_builder_build_main_combat_value :: proc(
	enemy_units: [dynamic]^Unit,
	friendly_units: [dynamic]^Unit,
	side: Battle_State_Side,
	game_sequence: ^Game_Sequence,
	support_attachments: [dynamic]^Unit_Support_Attachment,
	lhtr_heavy_bombers: bool,
	game_dice_sides: int,
	territory_effects: [dynamic]^Territory_Effect,
) -> ^Combat_Value {
	b := combat_value_builder_main_builder_new()
	b.enemy_units = enemy_units
	b.friendly_units = friendly_units
	b.side = side
	b.game_sequence = game_sequence
	b.support_attachments = support_attachments
	b.lhtr_heavy_bombers = lhtr_heavy_bombers
	b.game_dice_sides = game_dice_sides
	b.territory_effects = territory_effects
	return combat_value_builder_main_builder_build(b)
}

// Java: CombatValueBuilder.buildAaCombatValue(...)
//   Package-private static factory backing the Lombok @Builder-generated
//   AaBuilder.build(). Populates an AaBuilder and delegates to its terminal
//   build(), which assembles AaDefenseCombatValue / AaOffenseCombatValue
//   depending on side.
combat_value_builder_build_aa_combat_value :: proc(
	enemy_units: [dynamic]^Unit,
	friendly_units: [dynamic]^Unit,
	side: Battle_State_Side,
	support_attachments: [dynamic]^Unit_Support_Attachment,
) -> ^Combat_Value {
	b := combat_value_builder_aa_builder_new()
	b.enemy_units = enemy_units
	b.friendly_units = friendly_units
	b.side = side
	b.support_attachments = support_attachments
	return combat_value_builder_aa_builder_build(b)
}

// Java: CombatValueBuilder.buildBombardmentCombatValue(...)
//   Package-private static factory backing the Lombok @Builder-generated
//   NavalBombardmentBuilder.build(). Populates a NavalBombardmentBuilder
//   and delegates to its terminal build(), which assembles a
//   BombardmentCombatValue. Friendly supports use side = OFFENSE / allied =
//   true and enemy supports use side = DEFENSE / allied = false (hard-coded
//   in the builder, matching the Java helper).
combat_value_builder_build_bombardment_combat_value :: proc(
	enemy_units: [dynamic]^Unit,
	friendly_units: [dynamic]^Unit,
	support_attachments: [dynamic]^Unit_Support_Attachment,
	lhtr_heavy_bombers: bool,
	game_dice_sides: int,
	territory_effects: [dynamic]^Territory_Effect,
) -> ^Combat_Value {
	b := combat_value_builder_naval_bombardment_builder_new()
	b.enemy_units = enemy_units
	b.friendly_units = friendly_units
	b.support_attachments = support_attachments
	b.lhtr_heavy_bombers = lhtr_heavy_bombers
	b.game_dice_sides = game_dice_sides
	b.territory_effects = territory_effects
	return combat_value_builder_naval_bombardment_builder_build(b)
}

