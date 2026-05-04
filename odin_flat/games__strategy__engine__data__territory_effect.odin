package game

Territory_Effect :: struct {
	using named_attachable: Named_Attachable,
}

territory_effect_new :: proc(name: string, data: ^Game_Data) -> ^Territory_Effect {
	self := new(Territory_Effect)
	base := named_attachable_new(name, data)
	self.named_attachable = base^
	free(base)
	return self
}
