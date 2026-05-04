package game

import "core:strings"

Improved_Shipyards_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: ImprovedShipyardsAdvance(GameData data) — forwards to
// `super(TECH_NAME_IMPROVED_SHIPYARDS, data)` (i.e. "Shipyards"). Allocates
// the concrete struct, sets the embedded Named_Attachable's name and the
// Tech_Advance's game_data pointer, and wires the polymorphic dispatch
// fields so callers using the abstract `^Tech_Advance` get the correct
// subtype behavior for `has_tech` and `get_property`.
improved_shipyards_advance_new :: proc(data: ^Game_Data) -> ^Improved_Shipyards_Advance {
	s := new(Improved_Shipyards_Advance)
	s.named.base.name = "Shipyards"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return improved_shipyards_advance_has_tech(transmute(^Improved_Shipyards_Advance)self, ta)
	}
	s.tech_advance.perform = proc(self: ^Tech_Advance, player: ^Game_Player, bridge: ^I_Delegate_Bridge) {
		improved_shipyards_advance_perform(transmute(^Improved_Shipyards_Advance)self, player, bridge)
	}
	return s
}

improved_shipyards_advance_get_property :: proc(self: ^Improved_Shipyards_Advance) -> string {
	return TECH_PROPERTY_IMPROVED_SHIPYARDS
}

improved_shipyards_advance_has_tech :: proc(self: ^Improved_Shipyards_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_shipyards(ta)
}

// games.strategy.triplea.delegate.ImprovedShipyardsAdvance#perform(GamePlayer, IDelegateBridge)
// Java: switch the player's current production frontier to the
// `<current>Shipyards` variant when the `useShipyards` property is on
// and such a frontier exists. Mirrors Java's early-return guards.
improved_shipyards_advance_perform :: proc(self: ^Improved_Shipyards_Advance, player: ^Game_Player, bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_use_shipyards(game_state_get_properties(&data.game_state)) {
		return
	}
	current := player.production_frontier
	if current == nil {
		return
	}
	current_name := default_named_get_name(&current.default_named)
	if strings.has_suffix(current_name, "Shipyards") {
		return
	}
	advanced_name := strings.concatenate({current_name, "Shipyards"})
	advanced_tech := production_frontier_list_get_production_frontier(
		game_data_get_production_frontier_list(data),
		advanced_name,
	)
	if advanced_tech == nil {
		return
	}
	prod_change := change_factory_change_production_frontier(player, advanced_tech)
	i_delegate_bridge_add_change(bridge, prod_change)
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.ImprovedShipyardsAdvance
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.ImprovedShipyardsAdvance

