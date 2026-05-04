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

// Java: static AmphibType of(final Unit unit) {
//   final UnitAttachment ua = unit.getUnitAttachment();
//   return new AmphibType(unit.getType(), ua.getIsMarine() != 0 && unit.getWasAmphibious());
// }
casualty_order_of_losses_amphib_type_of :: proc(unit: ^Unit) -> ^Casualty_Order_Of_Losses_Amphib_Type {
	ua := unit_get_unit_attachment(unit)
	is_amphibious :=
		unit_attachment_get_is_marine(ua) != 0 && unit_get_was_amphibious(unit)
	return casualty_order_of_losses_amphib_type_new(unit_get_type(unit), is_amphibious)
}

// Java: boolean matches(final Unit unit) {
//   final UnitAttachment ua = unit.getUnitAttachment();
//   return type.equals(unit.getType())
//       && (ua.getIsMarine() == 0 || isAmphibious == unit.getWasAmphibious());
// }
casualty_order_of_losses_amphib_type_matches :: proc(
	self: ^Casualty_Order_Of_Losses_Amphib_Type,
	unit: ^Unit,
) -> bool {
	ua := unit_get_unit_attachment(unit)
	return(
		self.type == unit_get_type(unit) &&
		(unit_attachment_get_is_marine(ua) == 0 ||
				self.is_amphibious == unit_get_was_amphibious(unit)) \
	)
}

