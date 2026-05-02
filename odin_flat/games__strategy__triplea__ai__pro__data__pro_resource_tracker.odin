package game

Pro_Resource_Tracker :: struct {
	resources:      Integer_Map_Resource,
	temp_purchases: Integer_Map_Resource,
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

