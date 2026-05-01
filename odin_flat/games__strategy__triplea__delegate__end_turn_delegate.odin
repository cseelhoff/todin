package game

End_Turn_Delegate :: struct {
	using abstract_end_turn_delegate: Abstract_End_Turn_Delegate,
}

end_turn_delegate_lambda_static_0 :: proc(ra: ^Rules_Attachment) -> bool {
	return ra.uses != 0
}
