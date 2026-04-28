package game

Firing_Group :: struct {
	display_name:   string,
	group_name:     string,
	firing_units:   [dynamic]^Unit,
	target_units:   [dynamic]^Unit,
	suicide_on_hit: bool,
}
