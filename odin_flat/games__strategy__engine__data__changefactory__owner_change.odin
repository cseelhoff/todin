package game

import "core:fmt"

Owner_Change :: struct {
	using change: Change,
	old_owner_name: string,
	new_owner_name: string,
	territory_name: string,
}

owner_change_to_string :: proc(self: ^Owner_Change) -> string {
	return fmt.aprintf("%s takes %s from %s", self.new_owner_name, self.territory_name, self.old_owner_name)
}

