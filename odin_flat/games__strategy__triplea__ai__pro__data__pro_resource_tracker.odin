package game

import "core:strings"

Pro_Resource_Tracker :: struct {
	resources:      Integer_Map_Resource,
	temp_purchases: Integer_Map_Resource,
}

// public ProResourceTracker(final GamePlayer player)
//   resources = player.getResources().getResourcesCopy();
pro_resource_tracker_new_from_player :: proc(player: ^Game_Player) -> ^Pro_Resource_Tracker {
	self := new(Pro_Resource_Tracker)
	self.resources = resource_collection_get_resources_copy(game_player_get_resources(player))
	self.temp_purchases = make(Integer_Map_Resource)
	return self
}

// public boolean hasEnough(final IntegerMap<Resource> amount)
//   return getRemaining().greaterThanOrEqualTo(amount);
// Inlined for the typed Integer_Map_Resource alias (the generic
// integer_map_greater_than_or_equal_to operates on ^Integer_Map with rawptr keys).
pro_resource_tracker_has_enough_amount :: proc(self: ^Pro_Resource_Tracker, amount: ^Integer_Map_Resource) -> bool {
	remaining := pro_resource_tracker_get_remaining(self)
	defer {
		delete(remaining^)
		free(remaining)
	}
	for k, v in amount^ {
		existing, _ := remaining[k]
		if existing < v {
			return false
		}
	}
	return true
}

// public boolean isEmpty()
//   final IntegerMap<Resource> remaining = getRemaining();
//   return !remaining.isEmpty() && remaining.allValuesEqual(0);
pro_resource_tracker_is_empty :: proc(self: ^Pro_Resource_Tracker) -> bool {
	remaining := pro_resource_tracker_get_remaining(self)
	defer {
		delete(remaining^)
		free(remaining)
	}
	if len(remaining^) == 0 {
		return false
	}
	for _, v in remaining^ {
		if v != 0 {
			return false
		}
	}
	return true
}

// public String toString()
//   return getRemaining().toString().replaceAll("\n", " ");
// IntegerMap.toString() format: "IntegerMap:\n<name> -> <n>\n" per entry,
// or "IntegerMap:\nempty\n" when empty. Resource.toString() resolves to
// the resource's name via Named (matches resource_collection_format_integer_map).
pro_resource_tracker_to_string :: proc(self: ^Pro_Resource_Tracker) -> string {
	remaining := pro_resource_tracker_get_remaining(self)
	defer {
		delete(remaining^)
		free(remaining)
	}
	raw := resource_collection_format_integer_map(remaining)
	defer delete(raw)
	result, _ := strings.replace_all(raw, "\n", " ")
	return result
}

pro_resource_tracker_clear_temp_purchases :: proc(self: ^Pro_Resource_Tracker) {
	delete(self.temp_purchases)
	self.temp_purchases = make(Integer_Map_Resource)
}

// public ProResourceTracker(final int pus, final GameState data)
//   resources = new IntegerMap<>();
//   resources.add(data.getResourceList().getResourceOrThrow(Constants.PUS), pus);
// Constants.PUS resolves to the literal "PUs" (matches ai_utils.odin /
// resource_collection.odin convention).
pro_resource_tracker_new :: proc(pus: i32, data: ^Game_State) -> ^Pro_Resource_Tracker {
	self := new(Pro_Resource_Tracker)
	self.resources = make(Integer_Map_Resource)
	self.temp_purchases = make(Integer_Map_Resource)
	pus_resource := resource_list_get_resource_or_throw(game_state_get_resource_list(data), "PUs")
	existing, _ := self.resources[pus_resource]
	self.resources[pus_resource] = existing + pus
	return self
}

// public void purchase(final ProPurchaseOption ppo)
//   resources.subtract(ppo.getCosts());
pro_resource_tracker_purchase :: proc(self: ^Pro_Resource_Tracker, ppo: ^Pro_Purchase_Option) {
	costs := pro_purchase_option_get_costs(ppo)
	if costs == nil {
		return
	}
	for k, v in costs^ {
		existing, _ := self.resources[k]
		self.resources[k] = existing - v
	}
}

// public void removePurchase(final ProPurchaseOption ppo)
//   if (ppo != null) { resources.add(ppo.getCosts()); }
pro_resource_tracker_remove_purchase :: proc(self: ^Pro_Resource_Tracker, ppo: ^Pro_Purchase_Option) {
	if ppo == nil {
		return
	}
	costs := pro_purchase_option_get_costs(ppo)
	if costs == nil {
		return
	}
	for k, v in costs^ {
		existing, _ := self.resources[k]
		self.resources[k] = existing + v
	}
}

// public void tempPurchase(final ProPurchaseOption ppo)
//   tempPurchases.add(ppo.getCosts());
pro_resource_tracker_temp_purchase :: proc(self: ^Pro_Resource_Tracker, ppo: ^Pro_Purchase_Option) {
	costs := pro_purchase_option_get_costs(ppo)
	if costs == nil {
		return
	}
	for k, v in costs^ {
		existing, _ := self.temp_purchases[k]
		self.temp_purchases[k] = existing + v
	}
}

// public void removeTempPurchase(final ProPurchaseOption ppo)
//   if (ppo != null) { tempPurchases.subtract(ppo.getCosts()); }
pro_resource_tracker_remove_temp_purchase :: proc(self: ^Pro_Resource_Tracker, ppo: ^Pro_Purchase_Option) {
	if ppo == nil {
		return
	}
	costs := pro_purchase_option_get_costs(ppo)
	if costs == nil {
		return
	}
	for k, v in costs^ {
		existing, _ := self.temp_purchases[k]
		self.temp_purchases[k] = existing - v
	}
}

// public void confirmTempPurchases()
//   resources.subtract(tempPurchases);
//   clearTempPurchases();
pro_resource_tracker_confirm_temp_purchases :: proc(self: ^Pro_Resource_Tracker) {
	for k, v in self.temp_purchases {
		existing, _ := self.resources[k]
		self.resources[k] = existing - v
	}
	pro_resource_tracker_clear_temp_purchases(self)
}

// public int getTempPUs(final GameState data)
//   final Resource pus = data.getResourceList().getResourceOrThrow(Constants.PUS);
//   return tempPurchases.getInt(pus);
pro_resource_tracker_get_temp_pus :: proc(self: ^Pro_Resource_Tracker, data: ^Game_State) -> i32 {
	pus := resource_list_get_resource_or_throw(game_state_get_resource_list(data), "PUs")
	v, ok := self.temp_purchases[pus]
	if !ok {
		return 0
	}
	return v
}

// private IntegerMap<Resource> getRemaining()
//   final IntegerMap<Resource> combinedResources = new IntegerMap<>(resources);
//   combinedResources.subtract(tempPurchases);
//   return combinedResources;
pro_resource_tracker_get_remaining :: proc(self: ^Pro_Resource_Tracker) -> ^Integer_Map_Resource {
	combined := new(Integer_Map_Resource)
	combined^ = make(Integer_Map_Resource)
	for k, v in self.resources {
		combined[k] = v
	}
	for k, v in self.temp_purchases {
		existing, _ := combined[k]
		combined[k] = existing - v
	}
	return combined
}

