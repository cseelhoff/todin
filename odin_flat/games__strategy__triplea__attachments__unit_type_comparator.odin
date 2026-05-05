package game

Unit_Type_Comparator :: struct {}

unit_type_comparator_new :: proc() -> ^Unit_Type_Comparator {
	self := new(Unit_Type_Comparator)
	return self
}

// Java: int compare(UnitType u1, UnitType u2)
// Sort key (ascending): isInfrastructure, isAaForAnything, isAir, isSea, attack, name.
unit_type_comparator_compare :: proc(self: ^Unit_Type_Comparator, a, b: ^Unit_Type) -> int {
	ua_a := unit_type_get_unit_attachment(a)
	ua_b := unit_type_get_unit_attachment(b)

	cmp_bool :: proc(x, y: bool) -> int {
		xi := 0
		if x {xi = 1}
		yi := 0
		if y {yi = 1}
		return xi - yi
	}

	if c := cmp_bool(unit_attachment_is_infrastructure(ua_a), unit_attachment_is_infrastructure(ua_b)); c != 0 {
		return c
	}
	aa_pred, aa_ctx := matches_unit_type_is_aa_for_anything()
	if c := cmp_bool(aa_pred(aa_ctx, a), aa_pred(aa_ctx, b)); c != 0 {
		return c
	}
	if c := cmp_bool(unit_attachment_is_air(ua_a), unit_attachment_is_air(ua_b)); c != 0 {
		return c
	}
	if c := cmp_bool(unit_attachment_is_sea(ua_a), unit_attachment_is_sea(ua_b)); c != 0 {
		return c
	}
	if c := int(unit_attachment_get_attack_no_player(ua_a)) - int(unit_attachment_get_attack_no_player(ua_b)); c != 0 {
		return c
	}
	na := default_named_get_name(&a.named_attachable.default_named)
	nb := default_named_get_name(&b.named_attachable.default_named)
	min_len := len(na)
	if len(nb) < min_len {
		min_len = len(nb)
	}
	for i in 0 ..< min_len {
		if na[i] != nb[i] {
			return int(na[i]) - int(nb[i])
		}
	}
	return len(na) - len(nb)
}

