package test_common

import "core:os"
import "core:strings"
import "core:fmt"
import "core:log"
import "core:encoding/json"
import "core:slice"
import "core:strconv"
import "core:path/filepath"
import "core:mem"
import game "../../odin_flat"

// ============================================================================
// Snapshot directory utilities
// ============================================================================

// Lists all snapshot IDs (subdirectory names) in a snapshots directory.
// Returns sorted array of strings like ["0001", "0002", ...].
list_snapshot_ids :: proc(snapshot_dir: string) -> [dynamic]string {
	ids: [dynamic]string
	dh, err := os.open(snapshot_dir)
	if err != nil {
		log.warnf("Cannot open snapshot dir: %s", snapshot_dir)
		return ids
	}
	defer os.close(dh)

	entries, read_err := os.read_dir(dh, -1, context.allocator)
	if read_err != nil {
		return ids
	}
	for entry in entries {
		if entry.type == .Directory {
			append(&ids, strings.clone(entry.name))
		}
	}
	slice.sort(ids[:])
	return ids
}

// ============================================================================
// JSON Game State Loader
// ============================================================================

// Loads a game state JSON file and deserializes it into a Game_Data struct.
// path: e.g. "server_game_run_next_step/snapshots"
// id: e.g. "0001"
// filename: e.g. "before.json"
load_game_state :: proc(snapshot_dir: string, id: string, filename: string) -> ^game.Game_Data {
	full_path := fmt.tprintf("%s/%s/%s", snapshot_dir, id, filename)
	data, read_err := os.read_entire_file(full_path, context.allocator)
	if read_err != nil {
		log.errorf("Failed to read file: %s", full_path)
		return nil
	}
	defer delete(data)

	json_val, json_err := json.parse(data)
	if json_err != nil {
		log.errorf("Failed to parse JSON from %s: %v", full_path, json_err)
		return nil
	}

	root, root_ok := json_val.(json.Object)
	if !root_ok {
		log.errorf("JSON root is not an object in %s", full_path)
		return nil
	}

	return deserialize_game_data(root)
}

// ============================================================================
// Deserialization — JSON Object → Game_Data
// ============================================================================

deserialize_game_data :: proc(root: json.Object) -> ^game.Game_Data {
	gd := new(game.Game_Data)

	gd.game_name = get_string(root, "gameName")
	gd.dice_sides = get_i32(root, "diceSides")

	// Sequence
	if seq_obj, ok := get_object(root, "sequence"); ok {
		gd.sequence = deserialize_sequence(seq_obj)
	}

	// Resources
	gd.resource_list = game.resource_list_new(gd)
	if res_arr, ok := get_array(root, "resources"); ok {
		for item in res_arr {
			if name, name_ok := item.(json.String); name_ok {
				r := game.resource_new_simple(strings.clone(name), gd)
				game.resource_list_add_resource(gd.resource_list, r)
			}
		}
	}

	// Unit types
	gd.unit_type_list = new(game.Unit_Type_List)
	gd.unit_type_list.unit_types = make(map[string]^game.Unit_Type)
	if ut_arr, ok := get_array(root, "unitTypes"); ok {
		for item in ut_arr {
			if ut_obj, ut_ok := item.(json.Object); ut_ok {
				ut := deserialize_unit_type(ut_obj)
				if ut != nil {
					gd.unit_type_list.unit_types[strings.clone(ut.named.base.name)] = ut
				}
			}
		}
	}

	// Players
	gd.player_list = new(game.Player_List)
	gd.player_list.players = make(map[string]^game.Game_Player)
	// Provision the "Neutral" null player so territories whose JSON
	// "owner" string is "Neutral" can resolve to a non-nil Game_Player.
	// Java's GamePlayer.getOwner() never returns null for a parsed
	// territory; the XML game parser always assigns Neutral as a
	// real Game_Player object whose isNull() returns true.
	gd.player_list.null_player = game.player_list_create_null_player(gd)
	gd.player_list.players[strings.clone("Neutral")] = gd.player_list.null_player
	if pl_arr, ok := get_array(root, "players"); ok {
		for item in pl_arr {
			if p_obj, p_ok := item.(json.Object); p_ok {
				p := deserialize_player(p_obj, gd)
				if p != nil {
					gd.player_list.players[strings.clone(p.named.base.name)] = p
				}
			}
		}
	}

	// Territories
	gd.game_map = new(game.Game_Map)
	gd.game_map.territory_lookup = make(map[string]^game.Territory)
	if terr_arr, ok := get_array(root, "territories"); ok {
		for item in terr_arr {
			if t_obj, t_ok := item.(json.Object); t_ok {
				t := deserialize_territory(t_obj, gd)
				if t != nil {
					append(&gd.game_map.territories, t)
					gd.game_map.territory_lookup[strings.clone(t.named.base.name)] = t
				}
			}
		}
	}

	// Overlay XML-derived TerritoryAttachment data. Snapshot JSON only
	// carries dynamic per-step state; static map metadata (production,
	// capital, isImpassable, etc.) lives in the game XML, which the
	// snapshot harness has no parser for. The companion script
	// `scripts/extract_ww2v5_territory_attachments.py` extracts them
	// into a sidecar JSON file alongside the harness sources.
	apply_xml_territory_attachments(gd)

	// Units
	gd.units_list = new(game.Units_List)
	gd.units_list.units = make(map[game.Uuid]^game.Unit)
	if units_arr, ok := get_array(root, "units"); ok {
		for item in units_arr {
			if u_obj, u_ok := item.(json.Object); u_ok {
				u := deserialize_unit(u_obj, gd)
				if u != nil {
					gd.units_list.units[u.id] = u
				}
			}
		}
	}

	// Alliances
	gd.alliances = new(game.Alliance_Tracker)
	gd.alliances.alliances = make(map[string][dynamic]^game.Game_Player)
	if alliances_obj, ok := get_object(root, "alliances"); ok {
		for alliance_name, val in alliances_obj {
			if players_arr, arr_ok := val.(json.Array); arr_ok {
				player_list: [dynamic]^game.Game_Player
				for p_val in players_arr {
					if p_name, p_ok := p_val.(json.String); p_ok {
						if player, found := gd.player_list.players[p_name]; found {
							append(&player_list, player)
						}
					}
				}
				gd.alliances.alliances[strings.clone(alliance_name)] = player_list
			}
		}
	}

	// Properties
	gd.properties = new(game.Game_Properties)
	gd.properties.constant_properties = make(map[string]game.Property_Value)
	gd.properties.editable_properties = make(map[string]^game.Editable_Property)
	if props_obj, ok := get_object(root, "properties"); ok {
		if constants, c_ok := get_object(props_obj, "constants"); c_ok {
			for key, val in constants {
				gd.properties.constant_properties[strings.clone(key)] = json_to_property_value(val)
			}
		}
	}

	// Relationships
	gd.relationships = new(game.Relationship_Tracker)
	gd.relationships.relationships = make(map[game.Related_Players]^game.Relationship)

	// Relationship types
	gd.relationship_type_list = new(game.Relationship_Type_List)
	gd.relationship_type_list.relationship_types = make(map[string]^game.Relationship_Type)
	if rt_arr, ok := get_array(root, "relationshipTypes"); ok {
		for item in rt_arr {
			if rt_obj, rt_ok := item.(json.Object); rt_ok {
				name := get_string(rt_obj, "name")
				rt := new(game.Relationship_Type)
				rt.named.base.name = name
				// Provision Relationship_Type_Attachment with arche_type
				// inferred from the relation name (snapshot JSON only
				// carries the name; archeType comes from XML in Java).
				rta := new(game.Relationship_Type_Attachment)
				switch name {
				case "default_war_relation", "war":
					rta.arche_type = game.RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR
				case "default_allied_relation", "allied":
					rta.arche_type = game.RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_ALLIED
				case:
					rta.arche_type = game.RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_NEUTRAL
				}
				rt.attachments = make(map[string]^game.I_Attachment)
				rt.attachments["relationshipTypeAttachment"] = cast(^game.I_Attachment)rta
				gd.relationship_type_list.relationship_types[strings.clone(name)] = rt
			}
		}
	}

	// Relationships (must run AFTER relationship_types and player_list)
	// Backfill the relationship_tracker's game_data backref so the
	// set_*_relations procs can resolve the relationship type list.
	gd.relationships.game_data_component.game_data = gd
	// Ensure "null_relation" exists in the type list. The snapshot JSON
	// only carries default_allied_relation / default_war_relation /
	// self_relation; Java's parser also emits null_relation (used for
	// player↔Neutral pairs by relationship_tracker_set_null_player_relations).
	if _, has_null := gd.relationship_type_list.relationship_types["null_relation"]; !has_null {
		nr := new(game.Relationship_Type)
		nr.named.base.name = strings.clone("null_relation")
		nr.attachments = make(map[string]^game.I_Attachment)
		nrta := new(game.Relationship_Type_Attachment)
		nrta.arche_type = game.RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR
		nr.attachments["relationshipTypeAttachment"] = cast(^game.I_Attachment)nrta
		gd.relationship_type_list.relationship_types[strings.clone("null_relation")] = nr
	}
	if rel_arr, ok := get_array(root, "relationships"); ok {
		for item in rel_arr {
			if rel_obj, rel_ok := item.(json.Object); rel_ok {
				p1_name := get_string(rel_obj, "player1")
				p2_name := get_string(rel_obj, "player2")
				type_name := get_string(rel_obj, "type")
				round_created := get_i32(rel_obj, "roundCreated")
				p1, p1_found := gd.player_list.players[p1_name]
				p2, p2_found := gd.player_list.players[p2_name]
				rt, rt_found := gd.relationship_type_list.relationship_types[type_name]
				if p1_found && p2_found && rt_found {
					rel := new(game.Relationship)
					rel.relationship_type = rt
					rel.round_created = round_created
					// Java's Related_Players.equals/hashCode is order-
					// agnostic, but Odin's map keys by struct identity.
					// Insert both directions so lookup works either way.
					key1 := game.make_Relationship_Tracker_Related_Players(p1, p2)
					key2 := game.make_Relationship_Tracker_Related_Players(p2, p1)
					gd.relationships.relationships[key1] = rel
					gd.relationships.relationships[key2] = rel
				}
			}
		}
	}
	// After explicit relationships are loaded, fill in player↔null and
	// self relations the way Java's RelationshipTracker.setupRelations
	// does. set_null_player_relations needs game_data backref.
	game.relationship_tracker_set_self_relations(gd.relationships)
	game.relationship_tracker_set_null_player_relations(gd.relationships)

	// Post-linking: connect sequence step players to player objects
	if gd.sequence != nil && gd.player_list != nil {
		seq_obj_ref, seq_ok := get_object(root, "sequence")
		if seq_ok {
			if steps_arr, sa_ok := get_array(seq_obj_ref, "steps"); sa_ok {
				for item, i in steps_arr {
					if step_obj, s_ok := item.(json.Object); s_ok {
						player_name := get_string(step_obj, "player")
						if player_name != "" && i < len(gd.sequence.steps) {
							if p, found := gd.player_list.players[player_name]; found {
								gd.sequence.steps[i].player = p
							}
						}
					}
				}
			}
		}
	}

	// Production rules
	gd.production_rule_list = game.production_rule_list_new(gd)
	if pr_arr, ok := get_array(root, "productionRules"); ok {
		for item in pr_arr {
			if pr_obj, pr_ok := item.(json.Object); pr_ok {
				rule_name := get_string(pr_obj, "name")
				pr := game.production_rule_new(rule_name, gd)
				if costs_obj, cok := get_object(pr_obj, "costs"); cok {
					for res_name, val in costs_obj {
						amount := json_to_i32(val)
						if r, found := gd.resource_list.resources[res_name]; found {
							game.production_rule_add_cost(pr, r, amount)
						}
					}
				}
				if results_obj, rok := get_object(pr_obj, "results"); rok {
					for key_name, val in results_obj {
						amount := json_to_i32(val)
						// Java NamedAttachable: try unit type first, fall back to resource.
						if ut, found := gd.unit_type_list.unit_types[key_name]; found {
							game.integer_map_put(&pr.results, rawptr(ut), amount)
						} else if r, found := gd.resource_list.resources[key_name]; found {
							game.integer_map_put(&pr.results, rawptr(r), amount)
						}
					}
				}
				game.production_rule_list_add_production_rule(gd.production_rule_list, pr)
			}
		}
	}

	// Production frontiers
	gd.production_frontier_list = game.production_frontier_list_new(gd)
	if pf_arr, ok := get_array(root, "productionFrontiers"); ok {
		for item in pf_arr {
			if pf_obj, pf_ok := item.(json.Object); pf_ok {
				frontier_name := get_string(pf_obj, "name")
				pf := game.production_frontier_new(frontier_name, gd)
				if rules_arr, rok := get_array(pf_obj, "rules"); rok {
					for r_val in rules_arr {
						if rule_name, rn_ok := r_val.(json.String); rn_ok {
							if rule := game.production_rule_list_get_production_rule(gd.production_rule_list, rule_name); rule != nil {
								append(&pf.rules, rule)
							}
						}
					}
				}
				game.production_frontier_list_add_production_frontier(gd.production_frontier_list, pf)
			}
		}
	}

	// Technology frontier (single object).
	if tf_obj, ok := get_object(root, "technologyFrontier"); ok {
		tf_name := get_string(tf_obj, "name")
		gd.technology_frontier = game.technology_frontier_new(tf_name, gd)
		if techs_arr, tok := get_array(tf_obj, "techs"); tok {
			// Build a display-name → factory lookup by instantiating each
			// predefined factory once and reading its name. Mirrors the Java
			// TechAdvance.ALL_PREDEFINED_TECHNOLOGIES surface keyed by display name.
			predefined := game.tech_advance_new_predefined_technology_map()
			defer delete(predefined)
			by_display: map[string]^game.Tech_Advance
			by_display = make(map[string]^game.Tech_Advance)
			for _, factory in predefined {
				adv := factory(gd)
				by_display[adv.named.base.name] = adv
			}
			for t_val in techs_arr {
				if tech_name, tn_ok := t_val.(json.String); tn_ok {
					if adv, found := by_display[tech_name]; found {
						append(&gd.technology_frontier.techs, adv)
					} else {
						// Unknown tech (e.g. generic-tech XML name) — synthesize
						// a placeholder Tech_Advance carrying just the display name.
						placeholder := new(game.Tech_Advance)
						placeholder.named.base.name = strings.clone(tech_name)
						append(&gd.technology_frontier.techs, placeholder)
					}
				}
			}
			delete(by_display)
		}
	}

	return gd
}

// ============================================================================
// Sub-struct deserialization
// ============================================================================

deserialize_sequence :: proc(obj: json.Object) -> ^game.Game_Sequence {
	seq := new(game.Game_Sequence)
	seq.round = get_i32(obj, "round")
	seq.current_index = get_i32(obj, "stepIndex")
	if steps_arr, ok := get_array(obj, "steps"); ok {
		for item in steps_arr {
			if step_obj, s_ok := item.(json.Object); s_ok {
				step := new(game.Game_Step)
				step.name = get_string(step_obj, "name")
				step.display_name = get_string(step_obj, "displayName")
				step.delegate_name = get_string(step_obj, "delegateName")
				// Java: GameStep.maxRunCount default is -1 (unlimited). JSON
				// export only emits the field when non-default, so absence
				// must map to -1, not 0.
				if _, has_mrc := step_obj["maxRunCount"]; has_mrc {
					step.max_run_count = get_i32(step_obj, "maxRunCount")
				} else {
					step.max_run_count = -1
				}
				append(&seq.steps, step)
			}
		}
	}
	return seq
}

deserialize_unit_type :: proc(obj: json.Object) -> ^game.Unit_Type {
	ut := new(game.Unit_Type)
	ut.named.base.name = get_string(obj, "name")
	if ua_obj, ok := get_object(obj, "unitAttachment"); ok {
		ut.unit_attachment = deserialize_unit_attachment(ua_obj)
	}
	return ut
}

deserialize_unit_attachment :: proc(obj: json.Object) -> ^game.Unit_Attachment {
	ua := new(game.Unit_Attachment)
	ua.is_air = get_bool(obj, "isAir")
	ua.is_sea = get_bool(obj, "isSea")
	ua.movement = get_i32(obj, "movement")
	ua.can_blitz = get_bool(obj, "canBlitz")
	ua.is_kamikaze = get_bool(obj, "isKamikaze")
	ua.can_not_move_during_combat_move = get_bool(obj, "canNotMoveDuringCombatMove")
	ua.attack = get_i32(obj, "attack")
	ua.defense = get_i32(obj, "defense")
	ua.attack_rolls = get_i32(obj, "attackRolls")
	ua.defense_rolls = get_i32(obj, "defenseRolls")
	ua.hit_points = get_i32(obj, "hitPoints")
	ua.is_infrastructure = get_bool(obj, "isInfrastructure")
	ua.can_bombard = get_bool(obj, "canBombard")
	ua.bombard = get_i32(obj, "bombard")
	ua.artillery = get_bool(obj, "artillery")
	ua.artillery_supportable = get_bool(obj, "artillerySupportable")
	ua.is_marine = get_i32(obj, "isMarine")
	ua.is_suicide_on_attack = get_bool(obj, "isSuicideOnAttack")
	ua.is_suicide_on_defense = get_bool(obj, "isSuicideOnDefense")
	ua.is_suicide_on_hit = get_bool(obj, "isSuicideOnHit")
	ua.choose_best_roll = get_bool(obj, "chooseBestRoll")
	ua.can_evade = get_bool(obj, "canEvade")
	ua.is_first_strike = get_bool(obj, "isFirstStrike")
	ua.can_move_through_enemies = get_bool(obj, "canMoveThroughEnemies")
	ua.can_be_moved_through_by_enemies = get_bool(obj, "canBeMovedThroughByEnemies")
	ua.is_destroyer = get_bool(obj, "isDestroyer")
	ua.is_combat_transport = get_bool(obj, "isCombatTransport")
	ua.transport_capacity = get_i32(obj, "transportCapacity")
	ua.transport_cost = get_i32(obj, "transportCost")
	ua.carrier_capacity = get_i32(obj, "carrierCapacity")
	ua.carrier_cost = get_i32(obj, "carrierCost")
	ua.is_air_transport = get_bool(obj, "isAirTransport")
	ua.is_air_transportable = get_bool(obj, "isAirTransportable")
	ua.is_land_transport = get_bool(obj, "isLandTransport")
	ua.is_land_transportable = get_bool(obj, "isLandTransportable")
	ua.is_aa_for_combat_only = get_bool(obj, "isAaForCombatOnly")
	ua.is_aa_for_bombing_this_unit_only = get_bool(obj, "isAaForBombingThisUnitOnly")
	ua.is_aa_for_fly_over_only = get_bool(obj, "isAaForFlyOverOnly")
	ua.is_rocket = get_bool(obj, "isRocket")
	ua.attack_aa = get_i32(obj, "attackAa")
	ua.offensive_attack_aa = get_i32(obj, "offensiveAttackAa")
	ua.attack_aa_max_die_sides = get_i32(obj, "attackAaMaxDieSides")
	ua.offensive_attack_aa_max_die_sides = get_i32(obj, "offensiveAttackAaMaxDieSides")
	ua.max_aa_attacks = get_i32(obj, "maxAaAttacks")
	ua.max_rounds_aa = get_i32(obj, "maxRoundsAa")
	ua.type_aa = get_string(obj, "typeAa")
	ua.may_over_stack_aa = get_bool(obj, "mayOverStackAa")
	ua.damageable_aa = get_bool(obj, "damageableAa")
	ua.is_strategic_bomber = get_bool(obj, "isStrategicBomber")
	ua.bombing_max_die_sides = get_i32(obj, "bombingMaxDieSides")
	ua.bombing_bonus = get_i32(obj, "bombingBonus")
	ua.can_intercept = get_bool(obj, "canIntercept")
	ua.can_escort = get_bool(obj, "canEscort")
	ua.can_air_battle = get_bool(obj, "canAirBattle")
	ua.air_defense = get_i32(obj, "airDefense")
	ua.air_attack = get_i32(obj, "airAttack")
	ua.can_produce_units = get_bool(obj, "canProduceUnits")
	ua.can_produce_x_units = get_i32(obj, "canProduceXUnits")
	ua.can_be_damaged = get_bool(obj, "canBeDamaged")
	ua.max_damage = get_i32(obj, "maxDamage")
	ua.max_operational_damage = get_i32(obj, "maxOperationalDamage")
	ua.can_die_from_reaching_max_damage = get_bool(obj, "canDieFromReachingMaxDamage")
	ua.is_construction = get_bool(obj, "isConstruction")
	ua.construction_type = get_string(obj, "constructionType")
	ua.constructions_per_terr_per_type_per_turn = get_i32(obj, "constructionsPerTerrPerTypePerTurn")
	ua.max_constructions_per_type_per_terr = get_i32(obj, "maxConstructionsPerTypePerTerr")
	ua.when_captured_sustains_damage = get_i32(obj, "whenCapturedSustainsDamage")
	return ua
}

deserialize_player :: proc(obj: json.Object, gd: ^game.Game_Data) -> ^game.Game_Player {
	p := new(game.Game_Player)
	p.named.base.name = get_string(obj, "name")
	p.named.kind = .Game_Player
	p.optional = get_bool(obj, "optional")
	p.can_be_disabled = get_bool(obj, "canBeDisabled")
	p.is_disabled = get_bool(obj, "isDisabled")
	p.who_am_i = get_string(obj, "whoAmI")

	// Resources
	if res_obj, ok := get_object(obj, "resources"); ok {
		p.resources = new(game.Resource_Collection)
		p.resources.resources = make(game.Integer_Map_Resource)
		for res_name, val in res_obj {
			amount := json_to_i32(val)
			if r, found := gd.resource_list.resources[res_name]; found {
				p.resources.resources[r] = amount
			}
		}
	}

	// Tech attachment
	if ta_obj, ok := get_object(obj, "techAttachment"); ok {
		p.tech_attachment = deserialize_tech_attachment(ta_obj)
	}

	return p
}

deserialize_tech_attachment :: proc(obj: json.Object) -> ^game.Tech_Attachment {
	ta := new(game.Tech_Attachment)
	ta.tech_cost = get_i32(obj, "techCost")
	ta.heavy_bomber = get_bool(obj, "heavyBomber")
	ta.long_range_air = get_bool(obj, "longRangeAir")
	ta.jet_power = get_bool(obj, "jetPower")
	ta.rocket = get_bool(obj, "rocket")
	ta.industrial_technology = get_bool(obj, "industrialTechnology")
	ta.super_sub = get_bool(obj, "superSub")
	ta.destroyer_bombard = get_bool(obj, "destroyerBombard")
	ta.improved_artillery_support = get_bool(obj, "improvedArtillerySupport")
	ta.paratroopers = get_bool(obj, "paratroopers")
	ta.increased_factory_production = get_bool(obj, "increasedFactoryProduction")
	ta.war_bonds = get_bool(obj, "warBonds")
	ta.mechanized_infantry = get_bool(obj, "mechanizedInfantry")
	ta.aa_radar = get_bool(obj, "aaRadar")
	ta.shipyards = get_bool(obj, "shipyards")
	return ta
}

// Loads `ww2v5_territory_attachments.json` (produced by
// scripts/extract_ww2v5_territory_attachments.py from the game XML) and
// applies it to every territory that didn't already get a
// TerritoryAttachment from the snapshot JSON. No-op if the file is
// missing — most snapshots' before.json doesn't carry the static fields,
// so the overlay is what populates production/isImpassable/capital.
apply_xml_territory_attachments :: proc(gd: ^game.Game_Data) {
	// The harness binary's working directory is `triplea/`, so the path
	// is relative to that.
	candidates := [?]string{
		"conversion/odin_tests/test_common/ww2v5_territory_attachments.json",
		"triplea/conversion/odin_tests/test_common/ww2v5_territory_attachments.json",
	}
	bytes: []u8
	read_ok: bool
	for path in candidates {
		b, err := os.read_entire_file(path, context.allocator)
		if err == nil {
			bytes = b
			read_ok = true
			break
		}
	}
	if !read_ok {
		log.warnf("apply_xml_territory_attachments: sidecar JSON not found")
		return
	}
	defer delete(bytes)
	parsed, perr := json.parse(bytes)
	if perr != nil { return }
	defer json.destroy_value(parsed)
	root, root_ok := parsed.(json.Object)
	if !root_ok { return }
	applied := 0

	for terr_name, val in root {
		t, found := gd.game_map.territory_lookup[terr_name]
		if !found { continue }
		if t.territory_attachment != nil { continue }
		opts, opts_ok := val.(json.Object)
		if !opts_ok { continue }
		ta := new(game.Territory_Attachment)
		// Default attachment backref so any code reaching
		// game_data_component_get_data_or_throw on the TA finds gd.
		ta.default_attachment.game_data_component.game_data = gd
		if v, ok := opts["production"]; ok {
			if s, sok := v.(json.String); sok {
				if n, nerr := strconv.parse_int(s); nerr {
					ta.production = i32(n)
				}
			}
		}
		if v, ok := opts["unitProduction"]; ok {
			if s, sok := v.(json.String); sok {
				if n, nerr := strconv.parse_int(s); nerr {
					ta.unit_production = i32(n)
				}
			}
		}
		if v, ok := opts["victoryCity"]; ok {
			if s, sok := v.(json.String); sok {
				if n, nerr := strconv.parse_int(s); nerr {
					ta.victory_city = i32(n)
				}
			}
		}
		if v, ok := opts["capital"]; ok {
			if s, sok := v.(json.String); sok {
				ta.capital = strings.clone(s)
			}
		}
		ta.is_impassable    = xml_bool_opt(opts, "isImpassable")
		ta.convoy_route     = xml_bool_opt(opts, "convoyRoute")
		ta.naval_base       = xml_bool_opt(opts, "navalBase")
		ta.air_base         = xml_bool_opt(opts, "airBase")
		ta.kamikaze_zone    = xml_bool_opt(opts, "kamikazeZone")
		ta.blockade_zone    = xml_bool_opt(opts, "blockadeZone")
		ta.original_factory = xml_bool_opt(opts, "originalFactory")
		t.territory_attachment = ta
		// territory_attachment_get reads from named.attachments, not the
		// direct field — populate both so all access paths see the TA.
		if t.attachments == nil {
			t.attachments = make(map[string]^game.I_Attachment)
		}
		t.attachments["territoryAttachment"] = cast(^game.I_Attachment)ta
		applied += 1
	}
	_ = applied
}

@(private="file")
xml_bool_opt :: proc(opts: json.Object, key: string) -> bool {
	v, ok := opts[key]
	if !ok { return false }
	s, sok := v.(json.String)
	if !sok { return false }
	return s == "true"
}

deserialize_territory :: proc(obj: json.Object, gd: ^game.Game_Data) -> ^game.Territory {
	t := new(game.Territory)
	t.named.base.name = get_string(obj, "name")
	// kind discriminator drives unit_holder_get_unit_collection's
	// type-erasure switch — without it Territory's unit_collection is
	// unreachable through the ^Unit_Holder interface.
	t.named.kind = .Territory
	t.water = get_bool(obj, "water")
	owner_name := get_string(obj, "owner")
	if owner_name != "" {
		if p, found := gd.player_list.players[owner_name]; found {
			t.owner = p
		}
	}
	t.unit_collection = new(game.Unit_Collection)
	// Territory attachment
	if ta_obj, ok := get_object(obj, "territoryAttachment"); ok {
		ta := new(game.Territory_Attachment)
		ta.production       = get_i32(ta_obj, "production")
		ta.unit_production  = get_i32(ta_obj, "unitProduction")
		ta.capital          = get_string(ta_obj, "capital")
		ta.victory_city     = get_i32(ta_obj, "victoryCity")
		ta.is_impassable    = get_bool(ta_obj, "isImpassable")
		ta.convoy_route     = get_bool(ta_obj, "convoyRoute")
		ta.naval_base       = get_bool(ta_obj, "navalBase")
		ta.air_base         = get_bool(ta_obj, "airBase")
		ta.kamikaze_zone    = get_bool(ta_obj, "kamikazeZone")
		ta.blockade_zone    = get_bool(ta_obj, "blockadeZone")
		ta.original_factory = get_bool(ta_obj, "originalFactory")
		// originalOwner: resolve by player name if present.
		if orig_owner_name := get_string(ta_obj, "originalOwner"); orig_owner_name != "" {
			if p, found := gd.player_list.players[orig_owner_name]; found {
				ta.original_owner = p
			}
		}
		t.territory_attachment = ta
		// Also publish via the attachments map: territory_attachment_get
		// reads from named_attachable.attachments, not the direct field.
		if t.attachments == nil {
			t.attachments = make(map[string]^game.I_Attachment)
		}
		t.attachments["territoryAttachment"] = cast(^game.I_Attachment)ta
	}
	return t
}

deserialize_unit :: proc(obj: json.Object, gd: ^game.Game_Data) -> ^game.Unit {
	u := new(game.Unit)
	// ID — stored as UUID string, parse to Uuid bytes (simplified: store hash)
	id_str := get_string(obj, "id")
	u.id = string_to_uuid(id_str)
	// Type
	type_name := get_string(obj, "type")
	if ut, found := gd.unit_type_list.unit_types[type_name]; found {
		u.type = ut
	}
	// Owner
	owner_name := get_string(obj, "owner")
	if owner_name != "" {
		if p, found := gd.player_list.players[owner_name]; found {
			u.owner = p
		}
	}
	u.hits = get_i32(obj, "hits")
	u.was_loaded_this_turn = get_bool(obj, "wasLoadedThisTurn")
	u.was_unloaded_in_combat_phase = get_bool(obj, "wasUnloadedInCombatPhase")
	u.already_moved = get_f64(obj, "alreadyMoved")
	u.bonus_movement = get_i32(obj, "bonusMovement")
	u.unit_damage = get_i32(obj, "unitDamage")
	u.submerged = get_bool(obj, "submerged")
	u.was_in_combat = get_bool(obj, "wasInCombat")
	u.was_loaded_after_combat = get_bool(obj, "wasLoadedAfterCombat")
	u.was_amphibious = get_bool(obj, "wasAmphibious")
	u.was_scrambled = get_bool(obj, "wasScrambled")
	u.max_scramble_count = get_i32(obj, "maxScrambleCount")
	u.was_in_air_battle = get_bool(obj, "wasInAirBattle")
	u.disabled = get_bool(obj, "disabled")
	u.launched = get_i32(obj, "launched")
	u.airborne = get_bool(obj, "airborne")
	u.charged_flat_fuel_cost = get_bool(obj, "chargedFlatFuelCost")
	// originalOwner
	orig_owner := get_string(obj, "originalOwner")
	if orig_owner != "" {
		if p, found := gd.player_list.players[orig_owner]; found {
			u.original_owner = p
		}
	}
	return u
}

// ============================================================================
// JSON helper functions
// ============================================================================

get_string :: proc(obj: json.Object, key: string) -> string {
	if val, ok := obj[key]; ok {
		if s, s_ok := val.(json.String); s_ok {
			return strings.clone(s)
		}
	}
	return ""
}

get_i32 :: proc(obj: json.Object, key: string) -> i32 {
	if val, ok := obj[key]; ok {
		return json_to_i32(val)
	}
	return 0
}

get_f64 :: proc(obj: json.Object, key: string) -> f64 {
	if val, ok := obj[key]; ok {
		#partial switch v in val {
		case json.Float:
			return v
		case json.Integer:
			return f64(v)
		}
	}
	return 0
}

get_bool :: proc(obj: json.Object, key: string) -> bool {
	if val, ok := obj[key]; ok {
		if b, b_ok := val.(json.Boolean); b_ok {
			return b
		}
	}
	return false
}

get_object :: proc(obj: json.Object, key: string) -> (json.Object, bool) {
	if val, ok := obj[key]; ok {
		if o, o_ok := val.(json.Object); o_ok {
			return o, true
		}
	}
	return {}, false
}

get_array :: proc(obj: json.Object, key: string) -> (json.Array, bool) {
	if val, ok := obj[key]; ok {
		if a, a_ok := val.(json.Array); a_ok {
			return a, true
		}
	}
	return {}, false
}

json_to_i32 :: proc(val: json.Value) -> i32 {
	#partial switch v in val {
	case json.Integer:
		return i32(v)
	case json.Float:
		return i32(v)
	}
	return 0
}

json_to_property_value :: proc(val: json.Value) -> game.Property_Value {
	#partial switch v in val {
	case json.Boolean:
		return v
	case json.Integer:
		return i32(v)
	case json.Float:
		return f64(v)
	case json.String:
		return strings.clone(v)
	}
	return nil
}

// Simple UUID string → Uuid bytes conversion.
// Java format: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
string_to_uuid :: proc(s: string) -> game.Uuid {
	uuid: game.Uuid
	// Remove dashes manually
	hex_buf: [32]u8
	hi := 0
	for c in s {
		if c != '-' && hi < 32 {
			hex_buf[hi] = u8(c)
			hi += 1
		}
	}
	if hi != 32 { return uuid }
	for i := 0; i < 16; i += 1 {
		hi_val := hex_digit(hex_buf[i*2])
		lo_val := hex_digit(hex_buf[i*2+1])
		uuid[i] = (hi_val << 4) | lo_val
	}
	return uuid
}

hex_digit :: proc(c: u8) -> u8 {
	switch {
	case c >= '0' && c <= '9':
		return c - '0'
	case c >= 'a' && c <= 'f':
		return c - 'a' + 10
	case c >= 'A' && c <= 'F':
		return c - 'A' + 10
	}
	return 0
}
