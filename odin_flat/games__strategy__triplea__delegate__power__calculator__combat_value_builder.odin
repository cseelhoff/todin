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

