package game

Damage_Units_History_Change :: struct {
	change:          ^Composite_Change,
	location:        ^Territory,
	damage_to_units: ^Integer_Map(^Unit),
}

