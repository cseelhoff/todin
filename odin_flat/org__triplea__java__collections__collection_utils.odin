package game

Collection_Utils :: struct {}

// Returns the count of elements in the iterable that match the predicate.
collection_utils_count_matches :: proc(it: [dynamic]rawptr, predicate: proc(rawptr) -> bool) -> i32 {
	count: i32 = 0
	for elem in it {
		if predicate(elem) {
			count += 1
		}
	}
	return count
}

// Returns the count of elements in the collection that match the predicate.
collection_utils_count_matches_collection :: proc(collection: [dynamic]rawptr, predicate: proc(rawptr) -> bool) -> i32 {
	count: i32 = 0
	for elem in collection {
		if predicate(elem) {
			count += 1
		}
	}
	return count
}

// Returns the first element of the iterable (mirrors elements.iterator().next()).
collection_utils_get_any :: proc(elements: [dynamic]rawptr) -> rawptr {
	return elements[0]
}

// True iff for each a in c1, a exists in c2, and vice versa, with equal size.
// Mirrors Java: Iterables.elementsEqual(c1, c2) || (size match && containsAll both ways).
collection_utils_have_equal_size_and_equivalent_elements :: proc(collection1: [dynamic]rawptr, collection2: [dynamic]rawptr) -> bool {
	// Iterables.elementsEqual: same length and pairwise equal in order.
	if len(collection1) == len(collection2) {
		all_equal := true
		for i in 0 ..< len(collection1) {
			if collection1[i] != collection2[i] {
				all_equal = false
				break
			}
		}
		if all_equal {
			return true
		}
	}

	if len(collection1) != len(collection2) {
		return false
	}

	// c2.containsAll(c1)
	for a in collection1 {
		found := false
		for b in collection2 {
			if a == b {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	// c1.containsAll(c2)
	for b in collection2 {
		found := false
		for a in collection1 {
			if a == b {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}

// Like Collectors.toList() but guarantees a mutable ArrayList — returns a fresh empty [dynamic]rawptr.
collection_utils_to_array_list :: proc() -> [dynamic]rawptr {
	result: [dynamic]rawptr
	return result
}

// Returns all elements in the collection that match the predicate. Always a fresh list.
collection_utils_get_matches :: proc(collection: [dynamic]rawptr, predicate: proc(rawptr) -> bool) -> [dynamic]rawptr {
	result: [dynamic]rawptr
	for elem in collection {
		if predicate(elem) {
			append(&result, elem)
		}
	}
	return result
}

// Returns up to `max` elements that match the predicate. Always a fresh list.
collection_utils_get_n_matches :: proc(collection: [dynamic]rawptr, max: i32, predicate: proc(rawptr) -> bool) -> [dynamic]rawptr {
	assert(max >= 0, "max must not be negative")
	result: [dynamic]rawptr
	count: i32 = 0
	for elem in collection {
		if count >= max {
			break
		}
		if predicate(elem) {
			append(&result, elem)
			count += 1
		}
	}
	return result
}

// Returns elements present in both collections (distinct). Always a fresh list.
collection_utils_intersection :: proc(collection1: [dynamic]rawptr, collection2: [dynamic]rawptr) -> [dynamic]rawptr {
	result: [dynamic]rawptr
	if len(collection1) == 0 || len(collection2) == 0 {
		return result
	}
	for a in collection1 {
		// distinct: skip if already added
		already := false
		for r in result {
			if r == a {
				already = true
				break
			}
		}
		if already {
			continue
		}
		// must exist in collection2
		in_c2 := false
		for b in collection2 {
			if a == b {
				in_c2 = true
				break
			}
		}
		if in_c2 {
			append(&result, a)
		}
	}
	return result
}

// Returns elements in collection1 not in collection2 (distinct). Always a fresh list.
collection_utils_difference :: proc(collection1: [dynamic]rawptr, collection2: [dynamic]rawptr) -> [dynamic]rawptr {
	result: [dynamic]rawptr
	if len(collection1) == 0 {
		return result
	}
	if len(collection2) == 0 {
		// copy of collection1
		for a in collection1 {
			append(&result, a)
		}
		return result
	}
	for a in collection1 {
		already := false
		for r in result {
			if r == a {
				already = true
				break
			}
		}
		if already {
			continue
		}
		in_c2 := false
		for b in collection2 {
			if a == b {
				in_c2 = true
				break
			}
		}
		if !in_c2 {
			append(&result, a)
		}
	}
	return result
}
