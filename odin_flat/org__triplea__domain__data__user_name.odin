package game

import "core:fmt"
import "core:strings"

User_Name :: struct {
	value: string,
}

user_name_new :: proc(value: string) -> ^User_Name {
	self := new(User_Name)
	self.value = value
	return self
}

user_name_of :: proc(name: string) -> ^User_Name {
	if len(name) == 0 || len(strings.trim_space(name)) == 0 {
		fmt.panicf("Username cannot be null or blank")
	}
	return user_name_new(name)
}

// Java owners covered by this file:
//   - org.triplea.domain.data.UserName

