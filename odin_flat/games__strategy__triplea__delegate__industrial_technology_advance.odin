package game

import "core:strings"

Industrial_Technology_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// games.strategy.triplea.delegate.IndustrialTechnologyAdvance(GameData)
//   Mirrors `super(TECH_NAME_INDUSTRIAL_TECHNOLOGY, data)`. Wires the
//   `perform` vtable slot to the substantive impl below.
industrial_technology_advance_new :: proc(data: ^Game_Data) -> ^Industrial_Technology_Advance {
	self := new(Industrial_Technology_Advance)
	base := tech_advance_new("Industrial Technology", data)
	self.tech_advance = base^
	free(base)
	self.tech_advance.perform = proc(ta: ^Tech_Advance, player: ^Game_Player, bridge: ^I_Delegate_Bridge) {
		industrial_technology_advance_perform(transmute(^Industrial_Technology_Advance)ta, player, bridge)
	}
	return self
}

// games.strategy.triplea.delegate.IndustrialTechnologyAdvance#perform(GamePlayer, IDelegateBridge)
// Java: switch the player's production frontier to the
// `<current>IndustrialTechnology` variant when one exists.
industrial_technology_advance_perform :: proc(self: ^Industrial_Technology_Advance, player: ^Game_Player, bridge: ^I_Delegate_Bridge) {
	current := player.production_frontier
	if current == nil {
		return
	}
	current_name := default_named_get_name(&current.default_named)
	if strings.has_suffix(current_name, "IndustrialTechnology") {
		return
	}
	advanced_name := strings.concatenate({current_name, "IndustrialTechnology"})
	data := i_delegate_bridge_get_data(bridge)
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

