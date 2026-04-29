package game

Unit_Placement :: struct {
	unit_type:   string,
	territory:   string,
	quantity:    i32,
	owner:       string,
	hits_taken:  ^i32,
	unit_damage: ^i32,
}
