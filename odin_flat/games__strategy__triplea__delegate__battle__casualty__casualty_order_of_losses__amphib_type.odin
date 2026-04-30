package game

Casualty_Order_Of_Losses_Amphib_Type :: struct {
	type:          ^Unit_Type,
	is_amphibious: bool,
}

casualty_order_of_losses_amphib_type_new :: proc(type: ^Unit_Type, is_amphibious: bool) -> ^Casualty_Order_Of_Losses_Amphib_Type {
	self := new(Casualty_Order_Of_Losses_Amphib_Type)
	self.type = type
	self.is_amphibious = is_amphibious
	return self
}

