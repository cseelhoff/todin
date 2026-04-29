package game

Abstract_Conditions_Attachment :: struct {
	using parent:                Default_Attachment,
	conditions:                  [dynamic]^Rules_Attachment,
	condition_type:              string,
	invert:                      bool,
	chance:                      string,
	chance_increment_on_failure: i32,
	chance_decrement_on_success: i32,
}
