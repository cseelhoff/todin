package game

import "core:fmt"

Original_Owner_Tracker :: struct {}

// games.strategy.triplea.delegate.OriginalOwnerTracker#lambda$getOriginalOwnerOrThrow$0(Territory)
//
// Java:
//   () -> new IllegalStateException(
//       String.format("GamePlayer expected for Territory %s", t.getName()))
//
// The lambda is the Supplier passed to Optional.orElseThrow; it
// builds the exception message from the captured Territory. In the
// Odin port we materialize just the formatted message string — the
// caller decides how to surface the failure.
original_owner_tracker_lambda_get_original_owner_or_throw_0 :: proc(territory: ^Territory) -> string {
	return fmt.aprintf("GamePlayer expected for Territory %s", default_named_get_name(&territory.named_attachable.default_named))
}

// Java: public static Change addOriginalOwnerChange(final Unit unit, final GamePlayer player) {
//   return ChangeFactory.unitPropertyChange(unit, player, Constants.ORIGINAL_OWNER);
// }
// Constants.ORIGINAL_OWNER is the literal "originalOwner" (Constants.java:215).
original_owner_tracker_add_original_owner_change_unit :: proc(unit: ^Unit, player: ^Game_Player) -> ^Change {
	return change_factory_unit_property_change(unit, rawptr(player), "originalOwner")
}

// Java: public static Change addOriginalOwnerChange(final Territory t, final GamePlayer player) {
//   return ChangeFactory.attachmentPropertyChange(
//       TerritoryAttachment.getOrThrow(t), player, Constants.ORIGINAL_OWNER);
// }
original_owner_tracker_add_original_owner_change_territory :: proc(t: ^Territory, player: ^Game_Player) -> ^Change {
	ta := territory_attachment_get_or_throw(t)
	return change_factory_attachment_property_change(
		cast(^I_Attachment)rawptr(ta),
		rawptr(player),
		"originalOwner",
	)
}

// Java: public static Optional<GamePlayer> getOriginalOwner(final Territory t) {
//   return TerritoryAttachment.get(t).flatMap(TerritoryAttachment::getOriginalOwner);
// }
// nil mirrors Optional.empty() at both flatMap stages.
original_owner_tracker_get_original_owner :: proc(t: ^Territory) -> ^Game_Player {
	ta := territory_attachment_get(t)
	if ta == nil {
		return nil
	}
	return territory_attachment_get_original_owner(ta)
}

// Java: public static Change addOriginalOwnerChange(final Collection<Unit> units, final GamePlayer player) {
//   final CompositeChange change = new CompositeChange();
//   for (final Unit unit : units) {
//     change.add(addOriginalOwnerChange(unit, player));
//   }
//   return change;
// }
original_owner_tracker_add_original_owner_change_units :: proc(units: [dynamic]^Unit, player: ^Game_Player) -> ^Change {
	change := composite_change_new()
	for unit in units {
		composite_change_add(change, original_owner_tracker_add_original_owner_change_unit(unit, player))
	}
	return &change.change
}

// Java: public static Collection<Territory> getOriginallyOwned(final GameState data, final GamePlayer player) {
//   final Collection<Territory> territories = new ArrayList<>();
//   for (final Territory t : data.getMap()) {
//     GamePlayer originalOwner = getOriginalOwner(t).orElse(data.getPlayerList().getNullPlayer());
//     if (originalOwner.equals(player)) {
//       territories.add(t);
//     }
//   }
//   return territories;
// }
original_owner_tracker_get_originally_owned :: proc(data: ^Game_State, player: ^Game_Player) -> [dynamic]^Territory {
	territories := make([dynamic]^Territory)
	for t in game_map_get_territories(game_state_get_map(data)) {
		original_owner := original_owner_tracker_get_original_owner(t)
		if original_owner == nil {
			original_owner = player_list_get_null_player(game_state_get_player_list(data))
		}
		if original_owner == player {
			append(&territories, t)
		}
	}
	return territories
}

