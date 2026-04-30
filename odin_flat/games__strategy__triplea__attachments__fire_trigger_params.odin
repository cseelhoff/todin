package game

Fire_Trigger_Params :: struct {
	before_or_after: string,
	step_name:       string,
	use_uses:        bool,
	test_uses:       bool,
	test_chance:     bool,
	test_when:       bool,
}

fire_trigger_params_new :: proc(
	before_or_after: string,
	step_name: string,
	use_uses: bool,
	test_uses: bool,
	test_chance: bool,
	test_when: bool,
) -> ^Fire_Trigger_Params {
	self := new(Fire_Trigger_Params)
	self.before_or_after = before_or_after
	self.step_name = step_name
	self.use_uses = use_uses
	self.test_uses = test_uses
	self.test_chance = test_chance
	self.test_when = test_when
	return self
}
