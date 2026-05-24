package game

import "core:fmt"
import "core:math"
import "core:strings"

// Port of org.triplea.java.collections.IntegerMap (generic base).
// Java is generic over T; Odin lacks generics, so keys are stored as rawptr.
// A specialized variant Integer_Map_Resource exists separately for Resource keys.
//
// Java's IntegerMap is backed by LinkedHashMap (preserves INSERTION ORDER).
// Odin's `map[rawptr]i32` iterates in pointer-hash order — diverges from
// Java and cascades through casualty-selection / AI move-ordering paths.
// `keys_order` keeps the LinkedHashMap iteration order; all iteration
// procs in this file walk it instead of `map_values`. Always mutate via
// the helpers (`integer_map_put`/`_add`/`_remove_key`/`_clear`) so the
// two stay in sync. Direct `self.map_values[k] = ...` writes are
// forbidden — use `integer_map_put` or `_iorder_put_`.
Integer_Map :: struct {
	map_values: map[rawptr]i32,
	keys_order: [dynamic]rawptr,
}

// Mirrors java.util.Map.Entry<T, Integer> as used by entrySet() callers.
Integer_Map_Entry :: struct {
	key:   rawptr,
	value: i32,
}

@(private="file")
_iorder_put_ :: proc(self: ^Integer_Map, key: rawptr, value: i32) {
	if _, present := self.map_values[key]; !present {
		append(&self.keys_order, key)
	}
	self.map_values[key] = value
}

@(private="file")
_iorder_remove_ :: proc(self: ^Integer_Map, key: rawptr) {
	if _, present := self.map_values[key]; !present {
		return
	}
	delete_key(&self.map_values, key)
	for j := 0; j < len(self.keys_order); j += 1 {
		if self.keys_order[j] == key {
			ordered_remove(&self.keys_order, j)
			return
		}
	}
}

// public IntegerMap()
integer_map_new :: proc() -> ^Integer_Map {
	self := new(Integer_Map)
	self.map_values = make(map[rawptr]i32)
	self.keys_order = make([dynamic]rawptr)
	return self
}

// private IntegerMap(Map<T,Integer> map, boolean copy)
//
// Java's LinkedHashMap(Map) copy ctor iterates the source map's entrySet
// in the source's iteration order. When the source is also a LinkedHashMap
// (the normal case for IntegerMap callers) this preserves insertion order.
// When the source is a raw `map[rawptr]i32`, Odin's iteration is
// pointer-hashed — but that matches Java's behavior for an unordered
// source map.
integer_map_new_from_map :: proc(source: map[rawptr]i32, copy: bool) -> ^Integer_Map {
	self := new(Integer_Map)
	self.keys_order = make([dynamic]rawptr)
	if copy {
		self.map_values = make(map[rawptr]i32)
		for k, v in source {
			_iorder_put_(self, k, v)
		}
	} else {
		// Java: mapValues = map; aliases the supplied map. Odin maps are
		// reference-like (descriptor by value, shared backing storage), so a
		// plain copy preserves Java's "view, not clone" semantics. We can
		// only synthesize a keys_order here by iterating once (pointer-hash
		// order) — for raw-map aliasing the caller has already lost
		// insertion order, so this is the best we can do.
		self.map_values = source
		for k, _ in source {
			append(&self.keys_order, k)
		}
	}
	return self
}

// public int size()
integer_map_size :: proc(self: ^Integer_Map) -> i32 {
	return i32(len(self.map_values))
}

// public void put(T key, int value)
integer_map_put :: proc(self: ^Integer_Map, key: rawptr, value: i32) {
	_iorder_put_(self, key, value)
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
	_iorder_put_(self, key, new_val)
}

// Lambda for multiplyAllValuesBy: (k, value) -> (int) Math.ceil(value * multiplyBy)
integer_map_lambda_multiply_all_values_by_2 :: proc(multiply_by: f64, k: rawptr, value: i32) -> i32 {
	return i32(math.ceil(f64(value) * multiply_by))
}

// public void multiplyAllValuesBy(double multiplyBy)
integer_map_multiply_all_values_by :: proc(self: ^Integer_Map, multiply_by: f64) {
	// Walk keys_order so Java's LinkedHashMap iteration order is preserved.
	// Mutation is value-only (keys unchanged), so keys_order need not change.
	for k in self.keys_order {
		v := self.map_values[k]
		self.map_values[k] = integer_map_lambda_multiply_all_values_by_2(multiply_by, k, v)
	}
}

// public void clear()
integer_map_clear :: proc(self: ^Integer_Map) {
	clear(&self.map_values)
	clear(&self.keys_order)
}

// public Set<T> keySet()
integer_map_key_set :: proc(self: ^Integer_Map) -> [dynamic]rawptr {
	keys: [dynamic]rawptr
	for k in self.keys_order {
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
	for k in self.keys_order {
		v := self.map_values[k]
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
	for k in self.keys_order {
		v := self.map_values[k]
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
	for k in self.keys_order {
		v := self.map_values[k]
		if !integer_map_lambda_is_positive_6(v) {
			return false
		}
	}
	return true
}

// public void removeKey(T key)
integer_map_remove_key :: proc(self: ^Integer_Map, key: rawptr) {
	_iorder_remove_(self, key)
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
	for k in self.keys_order {
		v := self.map_values[k]
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
	for k in self.keys_order {
		v := self.map_values[k]
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
integer_map_of_empty :: proc() -> ^Integer_Map {
	return integer_map_new_from_map(make(map[rawptr]i32), false)
}

// public static <X> IntegerMap<X> of(final Map<X, Integer> map) — Java
// delegates to `new IntegerMap<>(map)`, which uses the public copy constructor
// (copy=true).
integer_map_of_map :: proc(source: map[rawptr]i32) -> ^Integer_Map {
	return integer_map_new_map(source)
}

// Proc group dispatching the two `of` static factories by argument shape.
integer_map_of :: proc{
	integer_map_of_empty,
	integer_map_of_map,
}

// public IntegerMap(final IntegerMap<T> integerMap) — shallow clone constructor;
// Java delegates to `this(integerMap.mapValues)` which copies the backing map.
// We walk the source's keys_order so the clone preserves Java's LinkedHashMap
// iteration order.
integer_map_new_copy :: proc(other: ^Integer_Map) -> ^Integer_Map {
	self := integer_map_new()
	for k in other.keys_order {
		_iorder_put_(self, k, other.map_values[k])
	}
	return self
}

// public static <X> IntegerMap<X> unmodifiableViewOf(IntegerMap<X> other)
// Java wraps with Collections.unmodifiableMap; Odin has no immutability wrapper,
// so we alias the backing map (copy=false) to preserve the "view" semantics.
// keys_order is cloned (snapshot) since `[dynamic]` is not stable under appends.
integer_map_unmodifiable_view_of :: proc(other: ^Integer_Map) -> ^Integer_Map {
	self := new(Integer_Map)
	self.map_values = other.map_values
	self.keys_order = make([dynamic]rawptr)
	for k in other.keys_order {
		append(&self.keys_order, k)
	}
	return self
}

// public void add(final IntegerMap<T> map)
integer_map_add_map :: proc(self: ^Integer_Map, other: ^Integer_Map) {
	for k in other.keys_order {
		v := other.map_values[k]
		integer_map_add(self, k, v)
	}
}

// public void subtract(final IntegerMap<T> map)
integer_map_subtract :: proc(self: ^Integer_Map, other: ^Integer_Map) {
	for k in other.keys_order {
		v := other.map_values[k]
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
	for k in other.keys_order {
		v := other.map_values[k]
		if !integer_map_lambda_greater_than_or_equal_to_5(self, k, v) {
			return false
		}
	}
	return true
}

// public void addMultiple(final IntegerMap<T> map, final int multiple)
integer_map_add_multiple :: proc(self: ^Integer_Map, other: ^Integer_Map, multiple: i32) {
	for k in other.keys_order {
		v := other.map_values[k]
		integer_map_add(self, k, v * multiple)
	}
}
