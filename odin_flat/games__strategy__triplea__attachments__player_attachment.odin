package game

Player_Attachment :: struct {
	using default_attachment: Default_Attachment,
	vps:                                i32,
	capture_vps:                        i32,
	retain_capital_number:              i32,
	retain_capital_produce_number:      i32,
	give_unit_control:                  [dynamic]^Game_Player,
	give_unit_control_in_all_territories: bool,
	capture_unit_on_entering_by:        [dynamic]^Game_Player,
	share_technology:                   [dynamic]^Game_Player,
	help_pay_tech_cost:                 [dynamic]^Game_Player,
	destroys_pus:                       bool,
	immune_to_blockade:                 bool,
	suicide_attack_resources:           Integer_Map_Resource,
	suicide_attack_targets:             map[^Unit_Type]struct{},
	placement_limit:                    map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{},
	movement_limit:                     map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{},
	attacking_limit:                    map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{},
}
