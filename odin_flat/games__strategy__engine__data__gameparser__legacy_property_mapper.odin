package game

import "core:strings"

// Java owners covered by this file:
//   - games.strategy.engine.data.gameparser.LegacyPropertyMapper

Legacy_Property_Mapper :: struct {}

legacy_property_mapper_map_legacy_option_name :: proc(name: string) -> string {
	if strings.equal_fold(name, "isParatroop") {
		return "isAirTransportable"
	} else if strings.equal_fold(name, "isInfantry") || strings.equal_fold(name, "isMechanized") {
		return "isLandTransportable"
	} else if strings.equal_fold(name, "occupiedTerrOf") {
		return "originalOwner"
	} else if strings.equal_fold(name, "isImpassible") {
		return "isImpassable"
	} else if strings.equal_fold(name, "turns") {
		return "rounds"
	}
	return name
}

legacy_property_mapper_map_legacy_option_value :: proc(name: string, value: string) -> string {
	if strings.equal_fold(name, "victoryCity") {
		if strings.equal_fold(value, "true") {
			return "1"
		} else if strings.equal_fold(value, "false") {
			return "0"
		} else {
			return value
		}
	} else if strings.equal_fold(name, "conditionType") &&
	   strings.equal_fold(value, "XOR") {
		return "1"
	}
	return value
}

legacy_property_mapper_map_property_name :: proc(name: string) -> string {
	if strings.equal_fold(name, "Battleships repair at end of round") ||
	   strings.equal_fold(name, "Units repair at end of round") {
		return "Units Repair Hits End Turn"
	} else if strings.equal_fold(name, "Battleships repair at beginning of round") ||
	          strings.equal_fold(name, "Units repair at beginning of round") {
		return "Units Repair Hits Start Turn"
	}
	return name
}

legacy_property_mapper_ignore_option_name :: proc(name: string, value: string) -> bool {
	return strings.equal_fold(name, "takeUnitControl") ||
		(strings.equal_fold(name, "giveUnitControl") &&
				(value == "" || value == "false" || value == "true"))
}
