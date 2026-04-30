package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils

Pro_Purchase_Validation_Utils :: struct {}

// Static helper: concatenate two unit lists into a freshly allocated
// dynamic array. Mirrors Java's
//   Stream.concat(l1.stream(), l2.stream()).collect(Collectors.toList()).
pro_purchase_validation_utils_combine_lists :: proc(
	l1: [dynamic]^Unit,
	l2: [dynamic]^Unit,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, len(l1) + len(l2))
	for u in l1 {
		append(&result, u)
	}
	for u in l2 {
		append(&result, u)
	}
	return result
}

