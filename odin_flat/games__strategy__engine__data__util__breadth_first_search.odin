package game

Breadth_First_Search :: struct {
	map_:                 ^Game_Map,
	visited:              map[^Territory]struct {},
	territories_to_check: [dynamic]^Territory,
	neighbor_condition:   proc(a: ^Territory, b: ^Territory) -> bool,
}

// Adapter ctx for BreadthFirstSearch's Predicate->BiPredicate constructor lambda.
// Holds the captured Predicate (proc + its rawptr ctx) so the synthetic
// lambda$new$0 can be carried as a rawptr-style closure.
Breadth_First_Search_Lambda_New_0_Ctx :: struct {
	neighbor_predicate:     proc(ctx: rawptr, t: ^Territory) -> bool,
	neighbor_predicate_ctx: rawptr,
}

// Java: BreadthFirstSearch.lambda$new$0(Predicate, Territory, Territory) ->
//   neighborCondition.test(it2)
// The captured Predicate<Territory> is reified through ctx (rawptr/ctx form).
breadth_first_search_lambda_new_0 :: proc(ctx: rawptr, it: ^Territory, it2: ^Territory) -> bool {
	captured := cast(^Breadth_First_Search_Lambda_New_0_Ctx)ctx
	return captured.neighbor_predicate(captured.neighbor_predicate_ctx, it2)
}

// Java: BreadthFirstSearch.lambda$new$1(Territory) -> true
// Non-capturing default-neighbor predicate used by `new BreadthFirstSearch(Territory)`.
breadth_first_search_lambda_new_1 :: proc(t: ^Territory) -> bool {
	return true
}

