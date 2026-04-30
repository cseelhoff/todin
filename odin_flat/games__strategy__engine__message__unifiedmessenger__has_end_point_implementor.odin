package game

Has_End_Point_Implementor :: struct {
	end_point_name: string,
}

has_end_point_implementor_new :: proc(end_point_name: string) -> ^Has_End_Point_Implementor {
	self := new(Has_End_Point_Implementor)
	self.end_point_name = end_point_name
	return self
}

