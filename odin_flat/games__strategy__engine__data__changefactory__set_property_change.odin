package game

Set_Property_Change :: struct {
	using change: Change,
	property:  string,
	value:     any,
	old_value: any,
}
