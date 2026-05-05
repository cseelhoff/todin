package game

Named_Unit_Holder :: struct {
	using named:       Named,
	using unit_holder: Unit_Holder,
}

// Java: UnitHolder.notifyChanged() — implementations:
//   - Territory: data.notifyTerritoryUnitsChanged(this) → fires
//     territoryListeners (UI redraw observers).
//   - GamePlayer: empty body.
// No game-state mutation occurs; snapshot runs have no UI listeners,
// so a no-op is faithful.
named_unit_holder_notify_changed :: proc(self: ^Named_Unit_Holder) {
	// no-op
}

