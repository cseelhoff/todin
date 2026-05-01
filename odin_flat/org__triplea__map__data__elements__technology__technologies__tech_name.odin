package game

Technology_Technologies_Tech_Name :: struct {
	name: string,
	tech: string,
}

technology_technologies_tech_name_get_name :: proc(self: ^Technology_Technologies_Tech_Name) -> string {
	return self.name
}

technology_technologies_tech_name_get_tech :: proc(self: ^Technology_Technologies_Tech_Name) -> string {
	return self.tech
}

