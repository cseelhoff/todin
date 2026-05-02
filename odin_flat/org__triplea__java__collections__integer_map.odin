package game

import "core:fmt"
import "core:math"
import "core:strings"

// Port of org.triplea.java.collections.IntegerMap (generic base).
// Java is generic over T; Odin lacks generics, so keys are stored as rawptr.
// A specialized variant Integer_Map_Resource exists separately for Resource keys.
Integer_Map :: struct {
	map_values: map[rawptr]i32,
}

// Mirrors java.util.Map.Entry<T, Integer> as used by entrySet() callers.
Integer_Map_Entry :: struct {
	key:   rawptr,
	value: i32,
}

// public IntegerMap()
integer_map_new :: proc() -> ^Integer_Map {
	self := new(Integer_Map)
	self.map_values = make(map[rawptr]i32)
	return self
}

// private IntegerMap(Map<T,Integer> map, boolean copy)
integer_map_new_from_map :: proc(source: map[rawptr]i32, copy: bool) -> ^Integer_Map {
	self := new(Integer_Map)
	if copy {
		self.map_values = make(map[rawptr]i32)
		for k, v in source {
			self.map_values[k] = v
		}
	} else {
		// Java: mapValues = map; aliases the supplied map. Odin maps are
		// reference-like (descriptor by value, shared backing storage), so a
		// plain copy preserves Java's "view, not clone" semantics.
		self.map_values = source
	}
	return self
}

// public int size()
integer_map_size :: proc(self: ^Integer_Map) -> i32 {
	return i32(len(self.map_values))
}

// public void put(T key, int value)
integer_map_put :: proc(self: ^Integer_Map, key: rawptr, value: i32) {
	self.map_values[key] = value
}

// public int getInt(T key)  -- 0 if absent.
integer_map_get_int :: proc(self: ^Integer_Map, key: rawptr) -> i32 {
	if v, ok := self.map_values[key]; ok {
		return v
	}
	return 0
}

// Lambda for IntegerMap.add: (k, oldVal) -> oldVal == null ? value : oldVal + value.
// Java's Map.compute passes a possibly-null oldVal; we encode the absence with
// `old_val_present` so the lambda preserves Java's branching behavior.
integer_map_lambda_add_1 :: proc(value: i32, k: rawptr, old_val: i32, old_val_present: bool) -> i32 {
	if !old_val_present {
		return value
	}
	return old_val + value
}

// public void add(T key, int value)
integer_map_add :: proc(self: ^Integer_Map, key: rawptr, value: i32) {
	old, ok := self.map_values[key]
	new_val := integer_map_lambda_add_1(value, key, old, ok)
	self.map_values[key] = new_val
}

// Lambda for multiplyAllValuesBy: (k, value) -> (int) Math.ceil(value * multiplyBy)
integer_map_lambda_multiply_all_values_by_2 :: proc(multiply_by: f64, k: rawptr, value: i32) -> i32 {
	return i32(math.ceil(f64(value) * multiply_by))
}

// public void multiplyAllValuesBy(double multiplyBy)
integer_map_multiply_all_values_by :: proc(self: ^Integer_Map, multiply_by: f64) {
	// Snapshot the keys to avoid mutating the map mid-iteration.
	keys: [dynamic]rawptr
	defer delete(keys)
	for k, _ in self.map_values {
		append(&keys, k)
	}
	for k in keys {
		v := self.map_values[k]
		self.map_values[k] = integer_map_lambda_multiply_all_values_by_2(multiply_by, k, v)
	}
}

// public void clear()
integer_map_clear :: proc(self: ^Integer_Map) {
	clear(&self.map_values)
}

// public Set<T> keySet()
integer_map_key_set :: proc(self: ^Integer_Map) -> [dynamic]rawptr {
	keys: [dynamic]rawptr
	for k, _ in self.map_values {
		append(&keys, k)
	}
	return keys
}

// Lambda for allValuesEqual: value -> integer == value
integer_map_lambda_all_values_equal_3 :: proc(integer: i32, value: i32) -> bool {
	return integer == value
}

// public boolean allValuesEqual(int integer) — Java stream allMatch returns true on empty.
integer_map_all_values_equal :: proc(self: ^Integer_Map, integer: i32) -> bool {
	for _, v in self.map_values {
		if !integer_map_lambda_all_values_equal_3(integer, v) {
			return false
		}
	}
	return true
}

// Lambda for totalValues: value -> value (mapToInt identity).
integer_map_lambda_total_values_4 :: proc(value: i32) -> i32 {
	return value
}

// public int totalValues()
integer_map_total_values :: proc(self: ^Integer_Map) -> i32 {
	sum: i32 = 0
	for _, v in self.map_values {
		sum += integer_map_lambda_total_values_4(v)
	}
	return sum
}

// Lambda for isPositive: value -> value >= 0
integer_map_lambda_is_positive_6 :: proc(value: i32) -> bool {
	return value >= 0
}

// public boolean isPositive()
integer_map_is_positive :: proc(self: ^Integer_Map) -> bool {
	for _, v in self.map_values {
		if !integer_map_lambda_is_positive_6(v) {
			return false
		}
	}
	return true
}

// public void removeKey(T key)
integer_map_remove_key :: proc(self: ^Integer_Map, key: rawptr) {
	delete_key(&self.map_values, key)
}

// public boolean containsKey(T key)
integer_map_contains_key :: proc(self: ^Integer_Map, key: rawptr) -> bool {
	_, ok := self.map_values[key]
	return ok
}

// public boolean isEmpty()
integer_map_is_empty :: proc(self: ^Integer_Map) -> bool {
	return len(self.map_values) == 0
}

// public Set<Map.Entry<T,Integer>> entrySet()
integer_map_entry_set :: proc(self: ^Integer_Map) -> [dynamic]Integer_Map_Entry {
	entries: [dynamic]Integer_Map_Entry
	for k, v in self.map_values {
		append(&entries, Integer_Map_Entry{key = k, value = v})
	}
	return entries
}

// Lambda from the Collection/Function constructor: value -> mapValues.put(value, mapValues.getOrDefault(value, 0)).
// Hoisted as a free proc; takes the target map explicitly since the captured field is the IntegerMap's mapValues.
integer_map_lambda_new_0 :: proc(map_values: ^map[rawptr]i32, value: rawptr) {
	cur: i32 = 0
	if v, ok := map_values^[value]; ok {
		cur = v
	}
	map_values^[value] = cur
}

// public String toString() — mirrors Java line-by-line.
integer_map_to_string :: proc(self: ^Integer_Map) -> string {
	b: strings.Builder
	strings.builder_init(&b)
	strings.write_string(&b, "IntegerMap:\n")
	if len(self.map_values) == 0 {
		strings.write_string(&b, "empty\n")
	}
	for k, v in self.map_values {
		// Java calls T.toString() on the key; rawptr here yields its address,
		// matching java.lang.Object's default "@hashHex" rendering.
		strings.write_string(&b, fmt.tprintf("%p", k))
		strings.write_string(&b, " -> ")
		strings.write_int(&b, int(v))
		strings.write_byte(&b, '\n')
	}
	return strings.to_string(b)
}

// public IntegerMap(final Map<T, Integer> map) — copy constructor that delegates
// to the private (map, copy=true) constructor.
integer_map_new_map :: proc(source: map[rawptr]i32) -> ^Integer_Map {
	return integer_map_new_from_map(source, true)
}

// public static <X> IntegerMap<X> of() — immutable empty integer map.
// Java passes Map.of() with copy=false; Odin's empty map literal is equivalent.
integer_map_of :: proc() -> ^Integer_Map {
	return integer_map_new_from_map(make(map[rawptr]i32), false)
}

// public static <X> IntegerMap<X> unmodifiableViewOf(IntegerMap<X> other)
// Java wraps with Collections.unmodifiableMap; Odin has no immutability wrapper,
// so we alias the backing map (copy=false) to preserve the "view" semantics.
integer_map_unmodifiable_view_of :: proc(other: ^Integer_Map) -> ^Integer_Map {
	return integer_map_new_from_map(other.map_values, false)
}

// public void add(final IntegerMap<T> map)
integer_map_add_map :: proc(self: ^Integer_Map, other: ^Integer_Map) {
	for k, v in other.map_values {
		integer_map_add(self, k, v)
	}
}

// public void subtract(final IntegerMap<T> map)
integer_map_subtract :: proc(self: ^Integer_Map, other: ^Integer_Map) {
	for k, v in other.map_values {
		integer_map_add(self, k, -v)
	}
}

// Lambda for greaterThanOrEqualTo: entry -> getInt(entry.getKey()) >= entry.getValue()
integer_map_lambda_greater_than_or_equal_to_5 :: proc(self: ^Integer_Map, key: rawptr, value: i32) -> bool {
	return integer_map_get_int(self, key) >= value
}

// public boolean greaterThanOrEqualTo(final IntegerMap<T> map) — Java allMatch
// returns true on empty.
integer_map_greater_than_or_equal_to :: proc(self: ^Integer_Map, other: ^Integer_Map) -> bool {
	for k, v in other.map_values {
		if !integer_map_lambda_greater_than_or_equal_to_5(self, k, v) {
			return false
		}
	}
	return true
}

// public void addMultiple(final IntegerMap<T> map, final int multiple)
integer_map_add_multiple :: proc(self: ^Integer_Map, other: ^Integer_Map, multiple: i32) {
	for k, v in other.map_values {
		integer_map_add(self, k, v * multiple)
	}
}
