package game

Pro_Resource_Tracker :: struct {
	resources:      Integer_Map_Resource,
	temp_purchases: Integer_Map_Resource,
}

pro_resource_tracker_clear_temp_purchases :: proc(self: ^Pro_Resource_Tracker) {
	delete(self.temp_purchases)
	self.temp_purchases = make(Integer_Map_Resource)
}

