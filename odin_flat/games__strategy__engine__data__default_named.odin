package game

Default_Named :: struct {
	using named:  Named,
	using parent: Game_Data_Component,
}

default_named_get_name :: proc(self: ^Default_Named) -> string {
	return self.named.base.name
}

// Mirrors Java's `Objects.hashCode(name)` from `DefaultNamed.hashCode`.
// Uses FNV-1a over the name bytes to stay deterministic across runs.
default_named_hash_code :: proc(self: ^Default_Named) -> i32 {
	FNV_OFFSET :: u32(2166136261)
	FNV_PRIME :: u32(16777619)

	h := FNV_OFFSET
	mix_byte :: proc(h: u32, b: u8) -> u32 {
		return (h ~ u32(b)) * FNV_PRIME
	}

	if self != nil {
		for i in 0 ..< len(self.name) {
			h = mix_byte(h, self.name[i])
		}
	}

	return i32(h)
}

default_named_equals :: proc(self: ^Default_Named, other: ^Default_Named) -> bool {
	if self == nil || other == nil {
		return self == other
	}
	return self.named.base.name == other.named.base.name
}

// Workaround for JDK-8199664: Java body only calls in.defaultReadObject().
// No additional side-effects to mirror.
default_named_read_object :: proc(self: ^Default_Named, stream: ^Object_Input_Stream) {
}

// Mirrors Java's `DefaultNamed.toString` (simplified to return the name).
default_named_to_string :: proc(self: ^Default_Named) -> string {
	return self.name
}
