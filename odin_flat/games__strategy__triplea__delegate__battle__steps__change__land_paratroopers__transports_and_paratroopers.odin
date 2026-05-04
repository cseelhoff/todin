package game

Land_Paratroopers_Transports_And_Paratroopers :: struct {
	air_transports: [dynamic]^Unit,
	paratroopers:   [dynamic]^Unit,
}

// Java: TransportsAndParatroopers(LandParatroopers outer) {
//   if (battleState.getStatus().isFirstRound()
//       && !battleState.getBattleSite().isWater()
//       && battleState.getPlayer(OFFENSE).getTechAttachment().getParatroopers()) {
//     this.airTransports.addAll(
//         CollectionUtils.getMatches(
//             battleState.getBattleSite().getUnits(), Matches.unitIsAirTransport()));
//     this.paratroopers.addAll(battleState.getDependentUnits(airTransports));
//   }
// }
land_paratroopers_transports_and_paratroopers_new :: proc(
	outer: ^Land_Paratroopers,
) -> ^Land_Paratroopers_Transports_And_Paratroopers {
	self := new(Land_Paratroopers_Transports_And_Paratroopers)
	self.air_transports = make([dynamic]^Unit)
	self.paratroopers = make([dynamic]^Unit)

	bs := outer.battle_state
	if !battle_status_is_first_round(battle_state_get_status(bs)) {
		return self
	}
	site := battle_state_get_battle_site(bs)
	if territory_is_water(site) {
		return self
	}
	off_player := battle_state_get_player(bs, .OFFENSE)
	if !tech_attachment_get_paratroopers(game_player_get_tech_attachment(off_player)) {
		return self
	}

	site_units := unit_collection_get_units(territory_get_unit_collection(site))
	defer delete(site_units)

	pred, pred_ctx := matches_unit_is_air_transport()
	for u in site_units {
		if pred(pred_ctx, u) {
			append(&self.air_transports, u)
		}
	}

	deps := battle_state_get_dependent_units(bs, self.air_transports)
	defer delete(deps)
	for d in deps {
		append(&self.paratroopers, d)
	}
	return self
}

land_paratroopers_transports_and_paratroopers_has_paratroopers :: proc(self: ^Land_Paratroopers_Transports_And_Paratroopers) -> bool {
	return len(self.air_transports) > 0 && len(self.paratroopers) > 0
}
