package game

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteName

// Description for a Channel or a Remote end point.
Remote_Name :: struct {
	name:  string,
	clazz: string, // Java Class<?> (interface) -> store class name
}

remote_name_new :: proc(name: string, clazz: ^Class) -> ^Remote_Name {
	assert(clazz != nil, "null class; remote name")
	rn := new(Remote_Name)
	rn.name = name
	rn.clazz = class_get_name(clazz)
	return rn
}

remote_name_get_name :: proc(self: ^Remote_Name) -> string {
	return self.name
}

remote_name_get_clazz :: proc(self: ^Remote_Name) -> string {
	return self.clazz
}

