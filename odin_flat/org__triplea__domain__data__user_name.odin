package game

User_Name :: struct {
	value: string,
}

user_name_new :: proc(value: string) -> ^User_Name {
	self := new(User_Name)
	self.value = value
	return self
}

// Java owners covered by this file:
//   - org.triplea.domain.data.UserName

