package game

Unit_Property_Name :: enum {
	Transported_By,
	Unloaded,
	Loaded_This_Turn,
	Unloaded_To,
	Unloaded_In_Combat_Phase,
	Already_Moved,
	Bonus_Movement,
	Submerged,
	Was_In_Combat,
	Loaded_After_Combat,
	Unloaded_Amphibious,
	Originated_From,
	Was_Scrambled,
	Max_Scramble_Count,
	Was_In_Air_Battle,
	Launched,
	Airborne,
	Charged_Flat_Fuel_Cost,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.Unit$PropertyName

// Java: Unit$PropertyName#parseFromString(String) -> Optional<PropertyName>
// Modeled in Odin as (value, ok) to mirror Optional.
unit_property_name_parse_from_string :: proc(s: string) -> (Unit_Property_Name, bool) {
	for p in Unit_Property_Name {
		v := p
		if unit_property_name_to_string(&v) == s {
			return p, true
		}
	}
	return .Transported_By, false
}

unit_property_name_to_string :: proc(self: ^Unit_Property_Name) -> string {
	switch self^ {
	case .Transported_By:
		return "transportedBy"
	case .Unloaded:
		return "unloaded"
	case .Loaded_This_Turn:
		return "wasLoadedThisTurn"
	case .Unloaded_To:
		return "unloadedTo"
	case .Unloaded_In_Combat_Phase:
		return "wasUnloadedInCombatPhase"
	case .Already_Moved:
		return "alreadyMoved"
	case .Bonus_Movement:
		return "bonusMovement"
	case .Submerged:
		return "submerged"
	case .Was_In_Combat:
		return "wasInCombat"
	case .Loaded_After_Combat:
		return "wasLoadedAfterCombat"
	case .Unloaded_Amphibious:
		return "wasAmphibious"
	case .Originated_From:
		return "originatedFrom"
	case .Was_Scrambled:
		return "wasScrambled"
	case .Max_Scramble_Count:
		return "maxScrambleCount"
	case .Was_In_Air_Battle:
		return "wasInAirBattle"
	case .Launched:
		return "launched"
	case .Airborne:
		return "airborne"
	case .Charged_Flat_Fuel_Cost:
		return "chargedFlatFuelCost"
	}
	return ""
}

unit_property_name_lambda_parse_from_string_0 :: proc(s: string, prop: ^Unit_Property_Name) -> bool {
	return unit_property_name_to_string(prop) == s
}

unit_property_name_values :: proc() -> []Unit_Property_Name {
	return []Unit_Property_Name{
		.Transported_By,
		.Unloaded,
		.Loaded_This_Turn,
		.Unloaded_To,
		.Unloaded_In_Combat_Phase,
		.Already_Moved,
		.Bonus_Movement,
		.Submerged,
		.Was_In_Combat,
		.Loaded_After_Combat,
		.Unloaded_Amphibious,
		.Originated_From,
		.Was_Scrambled,
		.Max_Scramble_Count,
		.Was_In_Air_Battle,
		.Launched,
		.Airborne,
		.Charged_Flat_Fuel_Cost,
	}
}

unit_property_name_values_public :: proc() -> []Unit_Property_Name {
	return unit_property_name_values()
}

make_Unit_Property_Name :: proc(name: string, ordinal: int, custom_field: string) -> Unit_Property_Name {
	switch ordinal {
	case 0:  return .Transported_By
	case 1:  return .Unloaded
	case 2:  return .Loaded_This_Turn
	case 3:  return .Unloaded_To
	case 4:  return .Unloaded_In_Combat_Phase
	case 5:  return .Already_Moved
	case 6:  return .Bonus_Movement
	case 7:  return .Submerged
	case 8:  return .Was_In_Combat
	case 9:  return .Loaded_After_Combat
	case 10: return .Unloaded_Amphibious
	case 11: return .Originated_From
	case 12: return .Was_Scrambled
	case 13: return .Max_Scramble_Count
	case 14: return .Was_In_Air_Battle
	case 15: return .Launched
	case 16: return .Airborne
	case 17: return .Charged_Flat_Fuel_Cost
	}
	return .Transported_By
}

