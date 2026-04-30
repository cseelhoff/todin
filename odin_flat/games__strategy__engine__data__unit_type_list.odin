package game

import "core:fmt"

// games.strategy.engine.data.UnitTypeList

Unit_Type_List :: struct {
	using game_data_component: Game_Data_Component,
	unit_types: map[string]^Unit_Type,
	support_rules: map[^Unit_Support_Attachment]struct{},
	support_aa_rules: map[^Unit_Support_Attachment]struct{},
}

unit_type_list_get_unit_type :: proc(self: ^Unit_Type_List, name: string) -> ^Unit_Type {
	return self.unit_types[name] or_else nil
}

unit_type_list_get_all_unit_types :: proc(self: ^Unit_Type_List) -> map[^Unit_Type]struct{} {
	result := make(map[^Unit_Type]struct{})
	for _, ut in self.unit_types {
		result[ut] = {}
	}
	return result
}

unit_type_list_stream :: proc(self: ^Unit_Type_List) -> [dynamic]^Unit_Type {
	result: [dynamic]^Unit_Type
	for _, v in self.unit_types {
		append(&result, v)
	}
	return result
}

// games.strategy.engine.data.UnitTypeList#iterator()
unit_type_list_iterator :: proc(self: ^Unit_Type_List) -> [dynamic]^Unit_Type {
	result := make([dynamic]^Unit_Type)
	for _, v in self.unit_types {
		append(&result, v)
	}
	return result
}

unit_type_list_get_unit_type_or_throw :: proc(self: ^Unit_Type_List, name: string) -> ^Unit_Type {
	ut := unit_type_list_get_unit_type(self, name)
	if ut == nil {
		panic(fmt.tprintf("UnitTypeList has no unit type for %s", name))
	}
	return ut
}

unit_type_list_add_unit_type :: proc(self: ^Unit_Type_List, ut: ^Unit_Type) {
	self.unit_types[default_named_get_name(&ut.named_attachable.default_named)] = ut
}

// games.strategy.engine.data.UnitTypeList#getUnitTypes(java.lang.String[])
unit_type_list_get_unit_types :: proc(self: ^Unit_Type_List, names: [dynamic]string) -> [dynamic]^Unit_Type {
	types: [dynamic]^Unit_Type
	seen := make(map[^Unit_Type]struct{})
	defer delete(seen)
	for name in names {
		ut := self.unit_types[name] or_else nil
		if ut != nil {
			if _, exists := seen[ut]; !exists {
				seen[ut] = {}
				append(&types, ut)
			}
		}
	}
	return types
}

// games.strategy.engine.data.UnitTypeList#lambda$getUnitTypeOrThrow$0(java.lang.String)
// Supplier producing the IllegalStateException thrown by getUnitTypeOrThrow.
unit_type_list_lambda_get_unit_type_or_throw_0 :: proc(name: string) -> ^Throwable {
	err := new(Throwable)
	err.message = fmt.aprintf("UnitTypeList has no unit type for %s", name)
	return err
}
