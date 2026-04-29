package game

// Port of org.triplea.java.collections.IntegerMap (generic base).
// Java is generic over T; Odin lacks generics, so keys are stored as rawptr.
// A specialized variant Integer_Map_Resource exists separately for Resource keys.
Integer_Map :: struct {
	map_values: map[rawptr]i32,
}

