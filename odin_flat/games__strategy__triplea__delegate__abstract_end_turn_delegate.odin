package game

Abstract_End_Turn_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
	has_posted_turn_summary: bool,
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#delegateCurrentlyRequiresUserInput()
// Java body: "return true;" — comment notes the call is needed regardless,
// because it resets player sounds for the turn.
abstract_end_turn_delegate_delegate_currently_requires_user_input :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> bool {
	return true
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getName()
// Mirrors AbstractDelegate.getName(): returns the internal name stored
// on the embedded I_Delegate.
abstract_end_turn_delegate_get_name :: proc(self: ^Abstract_End_Turn_Delegate) -> string {
	return self.name
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getDisplayName()
abstract_end_turn_delegate_get_display_name :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> string {
	return self.display_name
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getRemoteType()
// Java: "return IAbstractForumPosterDelegate.class;". Odin mirrors
// Class<? extends IRemote> with typeid.
abstract_end_turn_delegate_get_remote_type :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> typeid {
	return typeid_of(I_Abstract_Forum_Poster_Delegate)
}

// Captured-closure record for the Java method
//   getSingleBlockadeThenHighestToLowestBlockadeDamage(Map<Territory, Tuple<Integer, List<Territory>>>)
// which returns a Comparator<Territory> that closes over the supplied
// damage-per-zone map. The comparator's logic lives in the matching
// `_compare` proc below; the static factory simply packages the
// captured map into this struct value.
Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator :: struct {
	damage_per_blockade_zone: map[^Territory]^Tuple(i32, [dynamic]^Territory),
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getSingleBlockadeThenHighestToLowestBlockadeDamage(java.util.Map)
// Static factory returning a Comparator<Territory>. The Java source
// wraps it in `Comparator.nullsLast`, so nil sorts after non-nil.
abstract_end_turn_delegate_get_single_blockade_then_highest_to_lowest_blockade_damage :: proc(
	damage_per_blockade_zone: map[^Territory]^Tuple(i32, [dynamic]^Territory),
) -> Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator {
	return Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator{
		damage_per_blockade_zone = damage_per_blockade_zone,
	}
}

// Comparator body for
//   getSingleBlockadeThenHighestToLowestBlockadeDamage. Returns the
// Java Comparator<Territory> contract: negative if t1 < t2, zero if
// equal, positive if t1 > t2. Mirrors `Comparator.nullsLast` for the
// nil cases, then prefers a territory whose tuple's neighbor list has
// exactly one entry, then orders by descending damage value.
abstract_end_turn_delegate_single_blockade_then_highest_to_lowest_blockade_damage_compare :: proc(
	cmp: ^Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	// Comparator.nullsLast: nil sorts after any non-nil value.
	if t1 == nil && t2 == nil {
		return 0
	}
	if t1 == nil {
		return 1
	}
	if t2 == nil {
		return -1
	}
	if t1 == t2 {
		return 0
	}
	tuple1 := cmp.damage_per_blockade_zone[t1]
	tuple2 := cmp.damage_per_blockade_zone[t2]
	// Java's Tuple values are non-null in this map; defend against nil
	// just in case so the comparator stays a total order.
	if tuple1 == nil && tuple2 == nil {
		return 0
	}
	if tuple1 == nil {
		return 1
	}
	if tuple2 == nil {
		return -1
	}
	num1 := i32(len(tuple1.second))
	num2 := i32(len(tuple2.second))
	if num1 == 1 && num2 != 1 {
		return -1
	}
	if num2 == 1 && num1 != 1 {
		return 1
	}
	d1 := tuple1.first
	d2 := tuple2.first
	// Java: Integer.compare(d2, d1) — descending by damage.
	if d2 < d1 {
		return -1
	}
	if d2 > d1 {
		return 1
	}
	return 0
}

// Captured-closure record for
//   getSingleNeighborBlockadesThenHighestToLowestProduction(Collection<Territory>, GameMap)
// holding the blockade-zone collection and the game map needed to
// look up neighbors. The matching `_compare` proc implements the
// comparator body.
Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator :: struct {
	blockade_zones: [dynamic]^Territory,
	game_map:       ^Game_Map,
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getSingleNeighborBlockadesThenHighestToLowestProduction(java.util.Collection, games.strategy.engine.data.GameMap)
abstract_end_turn_delegate_get_single_neighbor_blockades_then_highest_to_lowest_production :: proc(
	blockade_zones: [dynamic]^Territory,
	game_map: ^Game_Map,
) -> Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator {
	return Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator{
		blockade_zones = blockade_zones,
		game_map       = game_map,
	}
}

// Comparator body for getSingleNeighborBlockadesThenHighestToLowestProduction.
// Mirrors Java semantics: nullsLast for nil; if a territory touches only
// one blockade zone, prefer it; otherwise fall back to the natural
// ordering of TerritoryAttachment.getProduction (ascending), exactly as
// the Java `Comparator.comparingInt(...)` chain does.
abstract_end_turn_delegate_single_neighbor_blockades_then_highest_to_lowest_production_compare :: proc(
	cmp: ^Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	// Comparator.nullsLast.
	if t1 == nil && t2 == nil {
		return 0
	}
	if t1 == nil {
		return 1
	}
	if t2 == nil {
		return -1
	}
	if t1 == t2 {
		return 0
	}
	// Count how many of t1/t2's neighbors are in the blockade zone set.
	// Java uses ArrayList(map.getNeighbors(t)).retainAll(blockadeZones);
	// the size after retainAll is what we count.
	count_blockade_neighbors := proc(
		t: ^Territory,
		game_map: ^Game_Map,
		blockade_zones: [dynamic]^Territory,
	) -> i32 {
		neighbors := game_map_get_neighbors(game_map, t)
		count: i32 = 0
		for n in neighbors {
			for b in blockade_zones {
				if n == b {
					count += 1
					break
				}
			}
		}
		return count
	}
	n1 := count_blockade_neighbors(t1, cmp.game_map, cmp.blockade_zones)
	n2 := count_blockade_neighbors(t2, cmp.game_map, cmp.blockade_zones)
	if n1 == 1 && n2 != 1 {
		return -1
	}
	if n2 == 1 && n1 != 1 {
		return 1
	}
	// Java: Comparator.comparingInt(t -> TerritoryAttachment.getProduction((Territory) t))
	// which is ascending production. The static getProduction returns
	// 0 when the territory has no attachment.
	prod_of := proc(t: ^Territory) -> i32 {
		if t == nil || t.territory_attachment == nil {
			return 0
		}
		return territory_attachment_get_production(t.territory_attachment)
	}
	p1 := prod_of(t1)
	p2 := prod_of(t2)
	if p1 < p2 {
		return -1
	}
	if p1 > p2 {
		return 1
	}
	return 0
}

// Synthetic Java lambda body emitted by javac for the inner
// Comparator<Territory> of getSingleBlockadeThenHighestToLowestBlockadeDamage.
// The captured `damage_per_blockade_zone` map is passed explicitly here
// so this proc reproduces the lambda signature exactly. Wraps the
// already-implemented comparator body via a stack-allocated record.
abstract_end_turn_delegate_lambda__get_single_blockade_then_highest_to_lowest_blockade_damage__2 :: proc(
	damage_per_blockade_zone: map[^Territory]^Tuple(i32, [dynamic]^Territory),
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	cmp := Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator{
		damage_per_blockade_zone = damage_per_blockade_zone,
	}
	return abstract_end_turn_delegate_single_blockade_then_highest_to_lowest_blockade_damage_compare(
		&cmp,
		t1,
		t2,
	)
}

// Synthetic Java lambda body emitted by javac for the inner
// Comparator<Territory> of getSingleNeighborBlockadesThenHighestToLowestProduction.
// Mirrors the captured-arg signature (map, blockade_zones, t1, t2)
// and delegates to the implemented comparator body.
abstract_end_turn_delegate_lambda__get_single_neighbor_blockades_then_highest_to_lowest_production__1 :: proc(
	game_map: ^Game_Map,
	blockade_zones: [dynamic]^Territory,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	cmp := Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator{
		blockade_zones = blockade_zones,
		game_map       = game_map,
	}
	return abstract_end_turn_delegate_single_neighbor_blockades_then_highest_to_lowest_production_compare(
		&cmp,
		t1,
		t2,
	)
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#loadState(java.io.Serializable)
// Restores delegate state from an EndTurnExtendedDelegateState. Mirrors
// the Java cast-and-assign, then forwards `superState` to the parent
// delegate's loadState (BaseTripleADelegate has no override, so this
// resolves to AbstractDelegate's via Base_Triple_A_Delegate.load_state).
abstract_end_turn_delegate_load_state :: proc(
	self: ^Abstract_End_Turn_Delegate,
	state: ^End_Turn_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
	self.has_posted_turn_summary = state.has_posted_turn_summary
}
