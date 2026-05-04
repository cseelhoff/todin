package game

Pro_Simulate_Turn_Utils :: struct {}

// games.strategy.triplea.ai.pro.simulate.ProSimulateTurnUtils#transferUnit(Unit, Map<Unit,Territory>, List<Unit>, GameState, GamePlayer)
//
// Java:
//   private static @Nullable Unit transferUnit(
//       final Unit u,
//       final Map<Unit, Territory> unitTerritoryMap,
//       final List<Unit> usedUnits,
//       final GameState toData,
//       final GamePlayer player) {
//     final Territory unitTerritory = unitTerritoryMap.get(u);
//     final List<Unit> toUnits =
//         toData.getMap().getTerritoryOrNull(unitTerritory.getName()).getMatches(
//             ProMatches.unitIsOwnedAndMatchesTypeAndNotTransporting(player, u.getType()));
//     for (final Unit toUnit : toUnits) {
//       if (!usedUnits.contains(toUnit)) {
//         usedUnits.add(toUnit);
//         return toUnit;
//       }
//     }
//     return null;
//   }
pro_simulate_turn_utils_transfer_unit :: proc(
	u: ^Unit,
	unit_territory_map: map[^Unit]^Territory,
	used_units: ^[dynamic]^Unit,
	to_data: ^Game_State,
	player: ^Game_Player,
) -> ^Unit {
	unit_territory := unit_territory_map[u]
	to_territory := game_map_get_territory_or_null(
		game_state_get_map(to_data),
		default_named_get_name(&unit_territory.named_attachable.default_named),
	)
	pred, ctx := pro_matches_unit_is_owned_and_matches_type_and_not_transporting(
		player,
		unit_get_type(u),
	)
	uc := territory_get_unit_collection(to_territory)
	for to_unit in uc.units {
		if !pred(ctx, to_unit) {
			continue
		}
		// usedUnits.contains(toUnit) — reference identity scan
		found := false
		for used in used_units^ {
			if used == to_unit {
				found = true
				break
			}
		}
		if !found {
			append(used_units, to_unit)
			return to_unit
		}
	}
	return nil
}

// games.strategy.triplea.ai.pro.simulate.ProSimulateTurnUtils#transferLoadedTransport(Unit, List<Unit>, Map<Unit,Territory>, List<Unit>, GameState, GamePlayer)
//
// Java:
//   private static @Nullable Unit transferLoadedTransport(
//       final Unit transport,
//       final List<Unit> transportingUnits,
//       final Map<Unit, Territory> unitTerritoryMap,
//       final List<Unit> usedUnits,
//       final GameState toData,
//       final GamePlayer player) {
//     final Territory unitTerritory = unitTerritoryMap.get(transport);
//     final List<Unit> toTransports =
//         toData.getMap().getTerritoryOrNull(unitTerritory.getName()).getMatches(
//             ProMatches.unitIsOwnedAndMatchesTypeAndIsTransporting(player, transport.getType()));
//     for (final Unit toTransport : toTransports) {
//       if (!usedUnits.contains(toTransport)) {
//         final List<Unit> toTransportingUnits = toTransport.getTransporting();
//         if (transportingUnits.size() == toTransportingUnits.size()) {
//           boolean canTransfer = true;
//           for (int i = 0; i < transportingUnits.size(); i++) {
//             if (!transportingUnits.get(i).getType().equals(toTransportingUnits.get(i).getType())) {
//               canTransfer = false;
//               break;
//             }
//           }
//           if (canTransfer) {
//             usedUnits.add(toTransport);
//             usedUnits.addAll(toTransportingUnits);
//             return toTransport;
//           }
//         }
//       }
//     }
//     return null;
//   }
pro_simulate_turn_utils_transfer_loaded_transport :: proc(
	transport: ^Unit,
	transporting_units: [dynamic]^Unit,
	unit_territory_map: map[^Unit]^Territory,
	used_units: ^[dynamic]^Unit,
	to_data: ^Game_State,
	player: ^Game_Player,
) -> ^Unit {
	unit_territory := unit_territory_map[transport]
	to_territory := game_map_get_territory_or_null(
		game_state_get_map(to_data),
		default_named_get_name(&unit_territory.named_attachable.default_named),
	)
	pred, ctx := pro_matches_unit_is_owned_and_matches_type_and_is_transporting(
		player,
		unit_get_type(transport),
	)
	uc := territory_get_unit_collection(to_territory)
	for to_transport in uc.units {
		if !pred(ctx, to_transport) {
			continue
		}
		// usedUnits.contains(toTransport) — reference identity scan
		used_already := false
		for u in used_units^ {
			if u == to_transport {
				used_already = true
				break
			}
		}
		if used_already {
			continue
		}
		to_transporting_units := unit_get_transporting_no_args(to_transport)
		if len(transporting_units) != len(to_transporting_units) {
			continue
		}
		can_transfer := true
		for i := 0; i < len(transporting_units); i += 1 {
			if unit_get_type(transporting_units[i]) != unit_get_type(to_transporting_units[i]) {
				can_transfer = false
				break
			}
		}
		if can_transfer {
			append(used_units, to_transport)
			for u in to_transporting_units {
				append(used_units, u)
			}
			return to_transport
		}
	}
	return nil
}

// games.strategy.triplea.ai.pro.simulate.ProSimulateTurnUtils#checkIfCapturedTerritoryIsAlliedCapital(Territory, GameState, GamePlayer, IDelegateBridge)
//
// Java:
//   private static boolean checkIfCapturedTerritoryIsAlliedCapital(
//       final Territory t,
//       final GameState data,
//       final GamePlayer player,
//       final IDelegateBridge delegateBridge) {
//     final Optional<GamePlayer> optionalTerrOrigOwner = OriginalOwnerTracker.getOriginalOwner(t);
//     final RelationshipTracker relationshipTracker = data.getRelationshipTracker();
//     if (TerritoryAttachment.get(t).map(TerritoryAttachment::isCapital).orElse(false)
//         && optionalTerrOrigOwner.isPresent()
//         && TerritoryAttachment.getAllCapitals(optionalTerrOrigOwner.get(), data.getMap()).contains(t)
//         && relationshipTracker.isAllied(optionalTerrOrigOwner.get(), player)) {
//       final GamePlayer terrOrigOwner = optionalTerrOrigOwner.get();
//       // Give capital and any allied territories back to original owner
//       final Collection<Territory> originallyOwned =
//           OriginalOwnerTracker.getOriginallyOwned(data, terrOrigOwner);
//       final List<Territory> friendlyTerritories =
//           CollectionUtils.getMatches(originallyOwned, Matches.isTerritoryAllied(terrOrigOwner));
//       friendlyTerritories.add(t);
//       for (final Territory item : friendlyTerritories) {
//         if (item.isOwnedBy(terrOrigOwner)) {
//           continue;
//         }
//         final Change takeOverFriendlyTerritories = ChangeFactory.changeOwner(item, terrOrigOwner);
//         delegateBridge.addChange(takeOverFriendlyTerritories);
//         final Collection<Unit> units =
//             CollectionUtils.getMatches(item.getUnits(), Matches.unitIsInfrastructure());
//         if (!units.isEmpty()) {
//           final Change takeOverNonComUnits = ChangeFactory.changeOwner(units, terrOrigOwner, t);
//           delegateBridge.addChange(takeOverNonComUnits);
//         }
//       }
//       return true;
//     }
//     return false;
//   }
//
// Optional.empty mirrors `nil` for ^Game_Player; the `.map(...).orElse(false)`
// chain inlines as a nil-check on the attachment plus its is_capital flag.
pro_simulate_turn_utils_check_if_captured_territory_is_allied_capital :: proc(
	t: ^Territory,
	data: ^Game_State,
	player: ^Game_Player,
	delegate_bridge: ^I_Delegate_Bridge,
) -> bool {
	terr_orig_owner := original_owner_tracker_get_original_owner(t)
	relationship_tracker := game_state_get_relationship_tracker(data)
	att := territory_attachment_get(t)
	is_capital := att != nil && territory_attachment_is_capital(att)
	if !is_capital || terr_orig_owner == nil {
		return false
	}
	all_capitals := territory_attachment_get_all_capitals(terr_orig_owner, game_state_get_map(data))
	contains_t := false
	for cap in all_capitals {
		if cap == t {
			contains_t = true
			break
		}
	}
	if !contains_t {
		return false
	}
	if !relationship_tracker_is_allied(relationship_tracker, terr_orig_owner, player) {
		return false
	}
	// Give capital and any allied territories back to original owner
	originally_owned := original_owner_tracker_get_originally_owned(data, terr_orig_owner)
	allied_pred, allied_ctx := matches_is_territory_allied(terr_orig_owner)
	friendly_territories := make([dynamic]^Territory)
	for terr in originally_owned {
		if allied_pred(allied_ctx, terr) {
			append(&friendly_territories, terr)
		}
	}
	append(&friendly_territories, t)
	infra_pred, infra_ctx := matches_unit_is_infrastructure()
	for item in friendly_territories {
		if territory_is_owned_by(item, terr_orig_owner) {
			continue
		}
		take_over_friendly_territories := change_factory_change_owner(item, terr_orig_owner)
		i_delegate_bridge_add_change(delegate_bridge, take_over_friendly_territories)
		uc := territory_get_unit_collection(item)
		units := make([dynamic]^Unit)
		for u in uc.units {
			if infra_pred(infra_ctx, u) {
				append(&units, u)
			}
		}
		if len(units) > 0 {
			take_over_non_com_units := change_factory_change_owner_3(units, terr_orig_owner, t)
			i_delegate_bridge_add_change(delegate_bridge, take_over_non_com_units)
		}
	}
	return true
}

