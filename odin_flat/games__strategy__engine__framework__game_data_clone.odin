package game


// SERIALIZATION-SHIM DIVERGENCE — Game_Data deep clone.
//
// Java's GameDataUtils.cloneGameData round-trips Game_Data through
// ObjectOutputStream / ObjectInputStream. Odin has no equivalent
// reflective serializer, so this file substitutes an in-memory deep
// clone with the same observable contract: callers receive an
// independent ^Game_Data whose mutations do not leak back into the
// source.
//
// Scope: clones every mutable sub-graph reachable from Game_Data that
// the AI's purchase / move / battle simulators write to. Static
// configuration (Unit_Type, Resource, Production_Rule, frontier lists,
// relationship types, tech advances, loader, alliance/relationship
// trackers, history) is shared by reference because it is immutable
// post-load.
//
// Memoization: a `map[rawptr]rawptr` translation table caches src→dst
// for every cloned object so cycles (Unit.transported_by, attached_to
// back-edges, holder back-pointers) terminate naturally and shared
// substructures (a Unit referenced from both Game_Player.units_held
// and Territory.unit_collection and Units_List.units) clone exactly
// once.

@(private="file")
Clone_Ctx :: struct {
	table: map[rawptr]rawptr,
	dst:   ^Game_Data,
}

@(private="file")
clone_remember :: proc(ctx: ^Clone_Ctx, src: rawptr, dst: rawptr) {
	ctx.table[src] = dst
}

@(private="file")
clone_lookup :: proc(ctx: ^Clone_Ctx, src: rawptr) -> (rawptr, bool) {
	v, ok := ctx.table[src]
	return v, ok
}

// Public entry point. Called from game_data_utils_clone_game_data
// when the source is non-nil. Returns nil on nil input.
game_data_deep_clone :: proc(src: ^Game_Data) -> ^Game_Data {
	if src == nil {
		return nil
	}
	ctx: Clone_Ctx
	ctx.table = make(map[rawptr]rawptr)
	defer delete(ctx.table)

	dst := new(Game_Data)
	dst^ = src^ // shallow copy of header (vtable + sub-pointers)
	ctx.dst = dst
	clone_remember(&ctx, rawptr(src), rawptr(dst))

	dst.player_list = clone_player_list(&ctx, src.player_list)
	dst.units_list  = clone_units_list(&ctx, src.units_list)
	dst.game_map    = clone_game_map(&ctx, src.game_map)
	dst.sequence    = clone_game_sequence(&ctx, src.sequence)
	dst.properties  = clone_game_properties(&ctx, src.properties)
	dst.state       = clone_game_data_state(&ctx, src.state)
	dst.delegates   = clone_delegates_map(&ctx, src.delegates)
	dst.relationships = clone_relationship_tracker(&ctx, src.relationships)
	dst.alliances     = clone_alliance_tracker(&ctx, src.alliances)

	return dst
}

// ============================================================================
// Player_List + Game_Player + Resource_Collection + Unit_Collection
// ============================================================================

@(private="file")
clone_player_list :: proc(ctx: ^Clone_Ctx, src: ^Player_List) -> ^Player_List {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Player_List)v
	}
	dst := new(Player_List)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	dst.players = make(map[string]^Game_Player)
	for name, p in src.players {
		dst.players[name] = clone_game_player(ctx, p)
	}
	dst.null_player = clone_game_player(ctx, src.null_player)
	return dst
}

@(private="file")
clone_game_player :: proc(ctx: ^Clone_Ctx, src: ^Game_Player) -> ^Game_Player {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Game_Player)v
	}
	dst := new(Game_Player)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	// Back-ref through Named_Attachable -> Default_Named -> Game_Data_Component.
	dst.named_attachable.default_named.game_data_component.game_data = ctx.dst
	// Cloned sub-objects.
	dst.units_held = clone_unit_collection(ctx, src.units_held)
	if dst.units_held != nil {
		dst.units_held.holder = cast(^Named_Unit_Holder)dst
	}
	dst.resources = clone_resource_collection(ctx, src.resources)
	dst.tech_attachment = clone_tech_attachment(ctx, src.tech_attachment)
	// Attachments map: snapshot loader does not populate this for
	// players, but copy it shallowly to preserve any attachments
	// added at runtime. Values stay shared (typed tech_attachment is
	// the only one cloned above; if attachments map references it,
	// the typed field clone is authoritative — reset map entry).
	if src.named_attachable.attachments != nil {
		dst.named_attachable.attachments = make(map[string]^I_Attachment)
		for k, v in src.named_attachable.attachments {
			dst.named_attachable.attachments[k] = v
		}
	}
	// production_frontier, repair_frontier, technology_frontiers are
	// shared static — preserved by the shallow `dst^ = src^` above.
	return dst
}

@(private="file")
clone_resource_collection :: proc(ctx: ^Clone_Ctx, src: ^Resource_Collection) -> ^Resource_Collection {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Resource_Collection)v
	}
	dst := new(Resource_Collection)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	// Resource keys are shared static; rebuild the map with same
	// keys + copied values so mutations don't leak.
	dst.resources = make(Integer_Map_Resource)
	for k, v in src.resources {
		dst.resources[k] = v
	}
	return dst
}

@(private="file")
clone_unit_collection :: proc(ctx: ^Clone_Ctx, src: ^Unit_Collection) -> ^Unit_Collection {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Unit_Collection)v
	}
	dst := new(Unit_Collection)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	dst.units = make([dynamic]^Unit, 0, len(src.units))
	for u in src.units {
		append(&dst.units, clone_unit(ctx, u))
	}
	// holder is fixed up by the Game_Player / Territory caller after
	// the parent itself is cloned — caller knows its own identity.
	return dst
}

// ============================================================================
// Units_List + Unit
// ============================================================================

@(private="file")
clone_units_list :: proc(ctx: ^Clone_Ctx, src: ^Units_List) -> ^Units_List {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Units_List)v
	}
	dst := new(Units_List)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst.units = make(map[Uuid]^Unit)
	for id, u in src.units {
		dst.units[id] = clone_unit(ctx, u)
	}
	return dst
}

@(private="file")
clone_unit :: proc(ctx: ^Clone_Ctx, src: ^Unit) -> ^Unit {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Unit)v
	}
	dst := new(Unit)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	// type is shared static (Unit_Type) — preserved by shallow copy.
	dst.owner          = clone_game_player(ctx, src.owner)
	dst.original_owner = clone_game_player(ctx, src.original_owner)
	dst.transported_by = clone_unit(ctx, src.transported_by)
	dst.unloaded_to    = clone_territory(ctx, src.unloaded_to)
	dst.originated_from = clone_territory(ctx, src.originated_from)
	if src.unloaded != nil {
		dst.unloaded = make([dynamic]^Unit, 0, len(src.unloaded))
		for u in src.unloaded {
			append(&dst.unloaded, clone_unit(ctx, u))
		}
	}
	return dst
}

// ============================================================================
// Game_Map + Territory + Territory_Attachment
// ============================================================================

@(private="file")
clone_game_map :: proc(ctx: ^Clone_Ctx, src: ^Game_Map) -> ^Game_Map {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Game_Map)v
	}
	dst := new(Game_Map)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	dst.territories = make([dynamic]^Territory, 0, len(src.territories))
	for t in src.territories {
		append(&dst.territories, clone_territory(ctx, t))
	}
	dst.territory_lookup = make(map[string]^Territory)
	for name, t in src.territory_lookup {
		dst.territory_lookup[name] = clone_territory(ctx, t)
	}
	// Connections: both keys and values in nested map are Territory
	// pointers — remap both via memoized clone_territory.
	dst.connections = make(map[^Territory]map[^Territory]struct{})
	for src_t, neighbours in src.connections {
		new_t := clone_territory(ctx, src_t)
		new_neighbours := make(map[^Territory]struct{})
		for n, _ in neighbours {
			new_neighbours[clone_territory(ctx, n)] = struct{}{}
		}
		dst.connections[new_t] = new_neighbours
	}
	return dst
}

@(private="file")
clone_territory :: proc(ctx: ^Clone_Ctx, src: ^Territory) -> ^Territory {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Territory)v
	}
	dst := new(Territory)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.named_attachable.default_named.game_data_component.game_data = ctx.dst
	dst.owner = clone_game_player(ctx, src.owner)
	dst.unit_collection = clone_unit_collection(ctx, src.unit_collection)
	if dst.unit_collection != nil {
		dst.unit_collection.holder = cast(^Named_Unit_Holder)dst
	}
	dst.territory_attachment = clone_territory_attachment(ctx, src.territory_attachment)
	// Attachments map: snapshot loader publishes territoryAttachment
	// here. Rebuild and point the entry at the clone so the typed
	// field and map entry stay in sync.
	if src.named_attachable.attachments != nil {
		dst.named_attachable.attachments = make(map[string]^I_Attachment)
		for k, v in src.named_attachable.attachments {
			if k == "territoryAttachment" && dst.territory_attachment != nil {
				dst.named_attachable.attachments[k] = cast(^I_Attachment)dst.territory_attachment
			} else {
				dst.named_attachable.attachments[k] = v
			}
		}
	}
	return dst
}

@(private="file")
clone_territory_attachment :: proc(ctx: ^Clone_Ctx, src: ^Territory_Attachment) -> ^Territory_Attachment {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Territory_Attachment)v
	}
	dst := new(Territory_Attachment)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.default_attachment.game_data_component.game_data = ctx.dst
	dst.original_owner = clone_game_player(ctx, src.original_owner)
	if src.convoy_attached != nil {
		dst.convoy_attached = make(map[^Territory]struct{})
		for t, _ in src.convoy_attached {
			dst.convoy_attached[clone_territory(ctx, t)] = struct{}{}
		}
	}
	if src.change_unit_owners != nil {
		dst.change_unit_owners = make([dynamic]^Game_Player, 0, len(src.change_unit_owners))
		for p in src.change_unit_owners {
			append(&dst.change_unit_owners, clone_game_player(ctx, p))
		}
	}
	if src.capture_unit_on_entering_by != nil {
		dst.capture_unit_on_entering_by = make([dynamic]^Game_Player, 0, len(src.capture_unit_on_entering_by))
		for p in src.capture_unit_on_entering_by {
			append(&dst.capture_unit_on_entering_by, clone_game_player(ctx, p))
		}
	}
	dst.resources = clone_resource_collection(ctx, src.resources)
	// territory_effect[], when_captured_by_goes_to[], primitives —
	// shallow copy was fine; rebuild dynamic arrays so they have
	// independent backing storage.
	if src.territory_effect != nil {
		dst.territory_effect = make([dynamic]^Territory_Effect, 0, len(src.territory_effect))
		for e in src.territory_effect {
			append(&dst.territory_effect, e) // shared static
		}
	}
	if src.when_captured_by_goes_to != nil {
		dst.when_captured_by_goes_to = make([dynamic]string, 0, len(src.when_captured_by_goes_to))
		for s in src.when_captured_by_goes_to {
			append(&dst.when_captured_by_goes_to, s)
		}
	}
	return dst
}

// ============================================================================
// Tech_Attachment (player-attached, shallow-clone for now)
// ============================================================================

@(private="file")
clone_tech_attachment :: proc(ctx: ^Clone_Ctx, src: ^Tech_Attachment) -> ^Tech_Attachment {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Tech_Attachment)v
	}
	dst := new(Tech_Attachment)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.default_attachment.game_data_component.game_data = ctx.dst
	return dst
}

// ============================================================================
// Game_Sequence + Game_Step
// ============================================================================

@(private="file")
clone_game_sequence :: proc(ctx: ^Clone_Ctx, src: ^Game_Sequence) -> ^Game_Sequence {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Game_Sequence)v
	}
	dst := new(Game_Sequence)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	dst.steps = make([dynamic]^Game_Step, 0, len(src.steps))
	for s in src.steps {
		append(&dst.steps, clone_game_step(ctx, s))
	}
	return dst
}

@(private="file")
clone_game_step :: proc(ctx: ^Clone_Ctx, src: ^Game_Step) -> ^Game_Step {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Game_Step)v
	}
	dst := new(Game_Step)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	dst.player = clone_game_player(ctx, src.player)
	if src.properties != nil {
		dst.properties = make(map[string]string)
		for k, v in src.properties {
			dst.properties[k] = v
		}
	}
	return dst
}

// ============================================================================
// Game_Data_State + Tech_Tracker
// ============================================================================

@(private="file")
clone_game_data_state :: proc(ctx: ^Clone_Ctx, src: ^Game_Data_State) -> ^Game_Data_State {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Game_Data_State)v
	}
	dst := new(Game_Data_State)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst.tech_tracker = clone_tech_tracker(ctx, src.tech_tracker)
	return dst
}

@(private="file")
clone_tech_tracker :: proc(ctx: ^Clone_Ctx, src: ^Tech_Tracker) -> ^Tech_Tracker {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Tech_Tracker)v
	}
	dst := new(Tech_Tracker)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst.data = ctx.dst
	dst.cache = make(map[^Tech_Tracker_Key]any) // cache is volatile
	return dst
}

// ============================================================================
// Game_Properties (shallow — editable_properties / player_properties shared)
// ============================================================================

@(private="file")
clone_game_properties :: proc(ctx: ^Clone_Ctx, src: ^Game_Properties) -> ^Game_Properties {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Game_Properties)v
	}
	dst := new(Game_Properties)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	dst.game_data_component.game_data = ctx.dst
	if src.constant_properties != nil {
		dst.constant_properties = make(map[string]Property_Value)
		for k, v in src.constant_properties {
			dst.constant_properties[k] = v
		}
	}
	if src.editable_properties != nil {
		dst.editable_properties = make(map[string]^Editable_Property)
		for k, v in src.editable_properties {
			dst.editable_properties[k] = v // shared
		}
	}
	if src.player_properties != nil {
		dst.player_properties = make(map[string]^Editable_Property)
		for k, v in src.player_properties {
			dst.player_properties[k] = v // shared
		}
	}
	if src.ordering != nil {
		dst.ordering = make([dynamic]string, 0, len(src.ordering))
		for s in src.ordering {
			append(&dst.ordering, s)
		}
	}
	return dst
}

// ============================================================================
// Delegates map — per-concrete-type switch on name.
//
// The concrete delegate type is not directly known from ^I_Delegate.
// Snapshot-game delegate names follow the GameXmlDelegateRegistry
// catalogue: "move", "purchase", "battle", "endTurn", "place",
// "endRound", "politics", "tech", "techActivation", "initialization",
// "edit", "randomStart", "userActions", "specialMove", "bidPlace",
// "bidPurchase", "noPuPurchase", "noPuEndTurn", "twoIfBySeaEndTurn",
// "noAirCheckPlace".
//
// For unrecognized names we fall back to sharing the original
// pointer; the snapshot AI path only mutates Move_Delegate and
// Purchase_Delegate state, so stale shared pointers for other
// delegates are observationally inert under the harness.
// ============================================================================

@(private="file")
clone_delegates_map :: proc(ctx: ^Clone_Ctx, src: map[string]^I_Delegate) -> map[string]^I_Delegate {
	if src == nil {
		return nil
	}
	dst := make(map[string]^I_Delegate)
	for name, d in src {
		dst[name] = clone_delegate(ctx, name, d)
	}
	return dst
}

@(private="file")
clone_delegate :: proc(ctx: ^Clone_Ctx, name: string, src: ^I_Delegate) -> ^I_Delegate {
	if src == nil {
		return nil
	}
	switch name {
	case "move":
		return cast(^I_Delegate)clone_move_delegate(ctx, cast(^Move_Delegate)src)
	case "specialMove":
		return cast(^I_Delegate)clone_special_move_delegate(ctx, cast(^Special_Move_Delegate)src)
	case "purchase":
		return cast(^I_Delegate)clone_purchase_delegate(ctx, cast(^Purchase_Delegate)src)
	case "bidPurchase":
		return cast(^I_Delegate)clone_bid_purchase_delegate(ctx, cast(^Bid_Purchase_Delegate)src)
	case "noPuPurchase":
		return cast(^I_Delegate)clone_no_pu_purchase_delegate(ctx, cast(^No_Pu_Purchase_Delegate)src)
	case "place":
		return cast(^I_Delegate)clone_place_delegate(ctx, cast(^Place_Delegate)src)
	case "bidPlace":
		return cast(^I_Delegate)clone_bid_place_delegate(ctx, cast(^Bid_Place_Delegate)src)
	case "battle":
		return cast(^I_Delegate)clone_battle_delegate(ctx, cast(^Battle_Delegate)src)
	case "endTurn":
		return cast(^I_Delegate)clone_end_turn_delegate(ctx, cast(^End_Turn_Delegate)src)
	case "tech":
		return cast(^I_Delegate)clone_technology_delegate(ctx, cast(^Technology_Delegate)src)
	case "techActivation":
		return cast(^I_Delegate)clone_tech_activation_delegate(ctx, cast(^Tech_Activation_Delegate)src)
	case "initialization":
		return cast(^I_Delegate)clone_initialization_delegate(ctx, cast(^Initialization_Delegate)src)
	case "endRound":
		return cast(^I_Delegate)clone_end_round_delegate(ctx, cast(^End_Round_Delegate)src)
	case:
		// Unknown delegate: share by reference. AI snapshot path
		// does not mutate other delegate state.
		return src
	}
}

@(private="file")
clone_abstract_delegate_in_place :: proc(ctx: ^Clone_Ctx, dst: ^Abstract_Delegate, src: ^Abstract_Delegate) {
	dst^ = src^
	// bridge / player are reset to nil — the AI's
	// set_delegate_bridge_and_player call will repopulate them on the
	// clone. Sharing the source's bridge would be wrong (it points
	// into the original game graph).
	dst.bridge = nil
	dst.player = nil
	dst.client_network_bridge = nil
	// Player remap if non-nil (defensive — typically already nil).
	_ = ctx
}

@(private="file")
clone_move_delegate :: proc(ctx: ^Clone_Ctx, src: ^Move_Delegate) -> ^Move_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Move_Delegate)v
	}
	dst := new(Move_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.abstract_move_delegate.base_triple_a_delegate.abstract_delegate, &src.abstract_move_delegate.base_triple_a_delegate.abstract_delegate)
	dst.moves_to_undo = make([dynamic]^Undoable_Move) // volatile — empty
	dst.temp_move_performer = nil
	if src.pus_lost != nil {
		dst.pus_lost = make(map[^Territory]i32)
		for t, v in src.pus_lost {
			dst.pus_lost[clone_territory(ctx, t)] = v
		}
	}
	return dst
}

@(private="file")
clone_special_move_delegate :: proc(ctx: ^Clone_Ctx, src: ^Special_Move_Delegate) -> ^Special_Move_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Special_Move_Delegate)v
	}
	dst := new(Special_Move_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.abstract_move_delegate.base_triple_a_delegate.abstract_delegate, &src.abstract_move_delegate.base_triple_a_delegate.abstract_delegate)
	dst.moves_to_undo = make([dynamic]^Undoable_Move)
	dst.temp_move_performer = nil
	return dst
}

@(private="file")
clone_purchase_delegate :: proc(ctx: ^Clone_Ctx, src: ^Purchase_Delegate) -> ^Purchase_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Purchase_Delegate)v
	}
	dst := new(Purchase_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.base_triple_a_delegate.abstract_delegate, &src.base_triple_a_delegate.abstract_delegate)
	// pending_production_rules: shallow share (^Integer_Map; rarely
	// non-nil between turns).
	return dst
}

@(private="file")
clone_bid_purchase_delegate :: proc(ctx: ^Clone_Ctx, src: ^Bid_Purchase_Delegate) -> ^Bid_Purchase_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Bid_Purchase_Delegate)v
	}
	dst := new(Bid_Purchase_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.purchase_delegate.base_triple_a_delegate.abstract_delegate, &src.purchase_delegate.base_triple_a_delegate.abstract_delegate)
	return dst
}

@(private="file")
clone_no_pu_purchase_delegate :: proc(ctx: ^Clone_Ctx, src: ^No_Pu_Purchase_Delegate) -> ^No_Pu_Purchase_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^No_Pu_Purchase_Delegate)v
	}
	dst := new(No_Pu_Purchase_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.purchase_delegate.base_triple_a_delegate.abstract_delegate, &src.purchase_delegate.base_triple_a_delegate.abstract_delegate)
	return dst
}

@(private="file")
clone_place_delegate :: proc(ctx: ^Clone_Ctx, src: ^Place_Delegate) -> ^Place_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Place_Delegate)v
	}
	dst := new(Place_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.abstract_place_delegate.base_triple_a_delegate.abstract_delegate, &src.abstract_place_delegate.base_triple_a_delegate.abstract_delegate)
	dst.abstract_place_delegate.produced = make(map[^Territory][dynamic]^Unit) // volatile — empty
	dst.abstract_place_delegate.placements = make([dynamic]^Undoable_Placement)
	return dst
}

@(private="file")
clone_bid_place_delegate :: proc(ctx: ^Clone_Ctx, src: ^Bid_Place_Delegate) -> ^Bid_Place_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Bid_Place_Delegate)v
	}
	dst := new(Bid_Place_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.abstract_place_delegate.base_triple_a_delegate.abstract_delegate, &src.abstract_place_delegate.base_triple_a_delegate.abstract_delegate)
	dst.abstract_place_delegate.produced = make(map[^Territory][dynamic]^Unit)
	dst.abstract_place_delegate.placements = make([dynamic]^Undoable_Placement)
	return dst
}

@(private="file")
clone_battle_delegate :: proc(ctx: ^Clone_Ctx, src: ^Battle_Delegate) -> ^Battle_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Battle_Delegate)v
	}
	dst := new(Battle_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.base_triple_a_delegate.abstract_delegate, &src.base_triple_a_delegate.abstract_delegate)
	// battle_tracker, rocket_helper, current_battle: volatile — reset.
	dst.battle_tracker = nil
	dst.rocket_helper = nil
	dst.current_battle = nil
	return dst
}

@(private="file")
clone_end_turn_delegate :: proc(ctx: ^Clone_Ctx, src: ^End_Turn_Delegate) -> ^End_Turn_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^End_Turn_Delegate)v
	}
	dst := new(End_Turn_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.abstract_end_turn_delegate.base_triple_a_delegate.abstract_delegate, &src.abstract_end_turn_delegate.base_triple_a_delegate.abstract_delegate)
	return dst
}

@(private="file")
clone_technology_delegate :: proc(ctx: ^Clone_Ctx, src: ^Technology_Delegate) -> ^Technology_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Technology_Delegate)v
	}
	dst := new(Technology_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.base_triple_a_delegate.abstract_delegate, &src.base_triple_a_delegate.abstract_delegate)
	if src.techs != nil {
		dst.techs = make(map[^Game_Player][dynamic]^Tech_Advance)
		for p, advances in src.techs {
			new_p := clone_game_player(ctx, p)
			new_advances := make([dynamic]^Tech_Advance, 0, len(advances))
			for a in advances {
				append(&new_advances, a) // shared static
			}
			dst.techs[new_p] = new_advances
		}
	}
	// tech_category is shared static.
	return dst
}

@(private="file")
clone_tech_activation_delegate :: proc(ctx: ^Clone_Ctx, src: ^Tech_Activation_Delegate) -> ^Tech_Activation_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Tech_Activation_Delegate)v
	}
	dst := new(Tech_Activation_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.base_triple_a_delegate.abstract_delegate, &src.base_triple_a_delegate.abstract_delegate)
	return dst
}

@(private="file")
clone_initialization_delegate :: proc(ctx: ^Clone_Ctx, src: ^Initialization_Delegate) -> ^Initialization_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Initialization_Delegate)v
	}
	dst := new(Initialization_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.base_triple_a_delegate.abstract_delegate, &src.base_triple_a_delegate.abstract_delegate)
	return dst
}

@(private="file")
clone_end_round_delegate :: proc(ctx: ^Clone_Ctx, src: ^End_Round_Delegate) -> ^End_Round_Delegate {
	if src == nil { return nil }
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^End_Round_Delegate)v
	}
	dst := new(End_Round_Delegate)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst^ = src^
	clone_abstract_delegate_in_place(ctx, &dst.base_triple_a_delegate.abstract_delegate, &src.base_triple_a_delegate.abstract_delegate)
	if src.winners != nil {
		dst.winners = make([dynamic]^Game_Player, 0, len(src.winners))
		for p in src.winners {
			append(&dst.winners, clone_game_player(ctx, p))
		}
	}
	return dst
}

// ============================================================================
// Relationship_Tracker + Alliance_Tracker
//
// Both index by ^Game_Player pointers; rebuild keys via cloned players.
// Relationship_Type values are static and stay shared.
// ============================================================================

@(private="file")
clone_relationship_tracker :: proc(ctx: ^Clone_Ctx, src: ^Relationship_Tracker) -> ^Relationship_Tracker {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Relationship_Tracker)v
	}
	dst := new(Relationship_Tracker)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst.game_data_component = make_Game_Data_Component(ctx.dst)
	dst.relationships = make(map[Related_Players]^Relationship)
	for k, v in src.relationships {
		new_key := Related_Players{
			player1 = clone_game_player(ctx, k.player1),
			player2 = clone_game_player(ctx, k.player2),
		}
		// Relationship value: shared by reference (immutable wrapper
		// around relationship_type for the snapshot harness's read-only
		// queries).
		dst.relationships[new_key] = v
	}
	return dst
}

@(private="file")
clone_alliance_tracker :: proc(ctx: ^Clone_Ctx, src: ^Alliance_Tracker) -> ^Alliance_Tracker {
	if src == nil {
		return nil
	}
	if v, ok := clone_lookup(ctx, rawptr(src)); ok {
		return cast(^Alliance_Tracker)v
	}
	dst := new(Alliance_Tracker)
	clone_remember(ctx, rawptr(src), rawptr(dst))
	dst.alliances = make(map[string][dynamic]^Game_Player)
	for name, players in src.alliances {
		new_players := make([dynamic]^Game_Player, 0, len(players))
		for p in players {
			append(&new_players, clone_game_player(ctx, p))
		}
		dst.alliances[name] = new_players
	}
	return dst
}
