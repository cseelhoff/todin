package game

import "core:fmt"

Owner_Change :: struct {
	using change: Change,
	old_owner_name: string,
	new_owner_name: string,
	territory_name: string,
}

// Java: OwnerChange(Territory territory, @Nullable GamePlayer newOwner)
owner_change_new :: proc(territory: ^Territory, new_owner: ^Game_Player) -> ^Owner_Change {
	self := new(Owner_Change)
	self.territory_name = default_named_get_name(&territory.named_attachable.default_named)
	if new_owner == nil {
		self.new_owner_name = ""
	} else {
		self.new_owner_name = default_named_get_name(&new_owner.named_attachable.default_named)
	}
	self.old_owner_name = default_named_get_name(&territory_get_owner(territory).named_attachable.default_named)
	return self
}

owner_change_to_string :: proc(self: ^Owner_Change) -> string {
	return fmt.aprintf("%s takes %s from %s", self.new_owner_name, self.territory_name, self.old_owner_name)
}

