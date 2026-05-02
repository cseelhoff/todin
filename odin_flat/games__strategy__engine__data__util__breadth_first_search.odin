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

// games.strategy.engine.data.util.BreadthFirstSearch#<init>(Collection<Territory>, BiPredicate<Territory,Territory>)
// Java:
//   this.map = CollectionUtils.getAny(startTerritories).getData().getMap();
//   this.visited = new HashSet<>(startTerritories);
//   this.territoriesToCheck = new ArrayDeque<>(startTerritories);
//   this.neighborCondition = neighborCondition;
breadth_first_search_new :: proc(
	start_territories: [dynamic]^Territory,
	neighbor_condition: proc(a: ^Territory, b: ^Territory) -> bool,
) -> ^Breadth_First_Search {
	self := new(Breadth_First_Search)
	any_t := start_territories[0]
	data := game_data_component_get_data(&any_t.named_attachable.default_named.game_data_component)
	self.map_ = game_data_get_map(data)
	self.visited = make(map[^Territory]struct {})
	self.territories_to_check = make([dynamic]^Territory)
	for t in start_territories {
		self.visited[t] = struct {}{}
		append(&self.territories_to_check, t)
	}
	self.neighbor_condition = neighbor_condition
	return self
}

// games.strategy.engine.data.util.BreadthFirstSearch#checkNextTerritory(Visitor, int)
// Java:
//   final Territory territory = territoriesToCheck.removeFirst();
//   for (final Territory neighbor : map.getNeighbors(territory)) {
//     if (!visited.contains(neighbor) && neighborCondition.test(territory, neighbor)) {
//       visited.add(neighbor);
//       final boolean shouldContinueSearch = visitor.visit(neighbor, currentDistance + 1);
//       if (!shouldContinueSearch) { territoriesToCheck.clear(); break; }
//       territoriesToCheck.add(neighbor);
//     }
//   }
//   return territory;
breadth_first_search_check_next_territory :: proc(
	self: ^Breadth_First_Search,
	visitor: ^Breadth_First_Search_Visitor,
	current_distance: i32,
) -> ^Territory {
	territory := self.territories_to_check[0]
	ordered_remove(&self.territories_to_check, 0)
	neighbors := game_map_get_neighbors(self.map_, territory)
	for neighbor in neighbors {
		_, already_visited := self.visited[neighbor]
		if !already_visited && self.neighbor_condition(territory, neighbor) {
			self.visited[neighbor] = struct {}{}
			should_continue_search := visitor.visit(visitor, neighbor, current_distance + 1)
			if !should_continue_search {
				clear(&self.territories_to_check)
				break
			}
			append(&self.territories_to_check, neighbor)
		}
	}
	return territory
}

// games.strategy.engine.data.util.BreadthFirstSearch#createTerritoryFinder(Territory)
// Java:
//   Preconditions.checkNotNull(destination);
//   return new TerritoryFinder(destination);
breadth_first_search_create_territory_finder :: proc(destination: ^Territory) -> ^Breadth_First_Search_Territory_Finder {
	assert(destination != nil)
	return make_Breadth_First_Search_Territory_Finder(destination)
}

// File-scope holder used to bridge a Predicate<Territory> (no closure) into
// the BiPredicate-shaped `neighbor_condition` field. BFS is single-threaded
// and constructed-then-traversed; the value is set by the Predicate-form
// constructor immediately before the (synchronous) traverse call.
@(private = "file")
breadth_first_search_active_predicate: proc(t: ^Territory) -> bool

@(private = "file")
breadth_first_search_predicate_to_bipredicate :: proc(it: ^Territory, it2: ^Territory) -> bool {
	return breadth_first_search_active_predicate(it2)
}

// games.strategy.engine.data.util.BreadthFirstSearch#<init>(Collection<Territory>, Predicate<Territory>)
// Java: this(startTerritories, (it, it2) -> neighborCondition.test(it2));
breadth_first_search_new_with_predicate :: proc(
	start_territories: [dynamic]^Territory,
	neighbor_condition: proc(t: ^Territory) -> bool,
) -> ^Breadth_First_Search {
	breadth_first_search_active_predicate = neighbor_condition
	return breadth_first_search_new(start_territories, breadth_first_search_predicate_to_bipredicate)
}

// games.strategy.engine.data.util.BreadthFirstSearch#traverse(Visitor)
// Java:
//   int currentDistance = 0;
//   Territory lastTerritoryAtCurrentDistance = territoriesToCheck.peekLast();
//   while (!territoriesToCheck.isEmpty()) {
//     final Territory territory = checkNextTerritory(visitor, currentDistance);
//     if (ObjectUtils.referenceEquals(territory, lastTerritoryAtCurrentDistance)) {
//       currentDistance++;
//       lastTerritoryAtCurrentDistance = territoriesToCheck.peekLast();
//     }
//   }
breadth_first_search_traverse :: proc(
	self: ^Breadth_First_Search,
	visitor: ^Breadth_First_Search_Visitor,
) {
	current_distance: i32 = 0
	last_territory_at_current_distance: ^Territory = nil
	if len(self.territories_to_check) > 0 {
		last_territory_at_current_distance =
			self.territories_to_check[len(self.territories_to_check) - 1]
	}
	for len(self.territories_to_check) > 0 {
		territory := breadth_first_search_check_next_territory(self, visitor, current_distance)
		if territory == last_territory_at_current_distance {
			current_distance += 1
			if len(self.territories_to_check) > 0 {
				last_territory_at_current_distance =
					self.territories_to_check[len(self.territories_to_check) - 1]
			} else {
				last_territory_at_current_distance = nil
			}
		}
	}
}

