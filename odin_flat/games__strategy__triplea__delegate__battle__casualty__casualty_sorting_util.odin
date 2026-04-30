package game

Casualty_Sorting_Util :: struct {}

@(private="file")
casualty_sorting_util_marines_cmp :: proc(u1: ^Unit, u2: ^Unit) -> int {
	a1 := unit_get_was_amphibious(u1)
	a2 := unit_get_was_amphibious(u2)
	v1 := 1 if a1 else 0
	v2 := 1 if a2 else 0
	if v1 != v2 {
		return v1 - v2
	}
	ua1: ^Unit_Attachment = nil
	ua2: ^Unit_Attachment = nil
	if u1 != nil && u1.type != nil {
		ua1 = u1.type.unit_attachment
	}
	if u2 != nil && u2.type != nil {
		ua2 = u2.type.unit_attachment
	}
	m1: i32 = ua1.is_marine if ua1 != nil else 0
	m2: i32 = ua2.is_marine if ua2 != nil else 0
	if m1 < m2 {
		return -1
	}
	if m1 > m2 {
		return 1
	}
	return 0
}

casualty_sorting_util_compare_marines :: proc() -> proc(a: ^Unit, b: ^Unit) -> int {
	return casualty_sorting_util_marines_cmp
}

