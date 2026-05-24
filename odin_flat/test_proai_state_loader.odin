package game

// ProAi state sidecar loader.
//
// Java's SnapshotHarness emits `<label>-proai-state.json` next to the GameData
// JSON. The file captures per-player AbstractProAi instance state — currently
// `storedPurchaseTerritories` and `storedStrafingTerritories` — that lives on
// the AI object, not in the engine's serialized GameData. Without this
// sidecar, snapshot replay on Odin starts every phase with a fresh AI memory
// (stored_purchase_territories=nil) and diverges from Java's continuous run
// (e.g. NCM's findUnitsThatCantMove takes the ELSE/findMaxPurchaseDefenders
// branch instead of the IF/planned-place-units branch).
//
// Schema (mirrors SnapshotHarness#dumpProAiState):
//   {
//     "players": {
//       "<PlayerName>": {
//         "storedPurchaseTerritories": [
//           { "territory": "<TerritoryName>",
//             "unitProduction": <int>,
//             "canPlaceTerritories": [
//               { "territory": "<TerritoryName>",
//                 "placeUnitIds": ["<uuid>", ...] }, ... ] }, ... ],
//         "storedStrafingTerritories": ["<TerritoryName>", ...]
//       }, ...
//     }
//   }
//
// Resolution rules:
//   * Territory names → game_map_get_territory_or_null (missing → entry skipped).
//   * Unit UUIDs → gd.units_list.units[uuid] (missing → unit skipped). Units
//     in the player's holding pile from the prior purchase phase are present
//     in the GameData JSON's flat `units` list, so this lookup succeeds for
//     every planned place-unit Java emitted.
//
// Application: for each player named in the sidecar, find the Pro_Ai via the
// player_to_ai registry the harness wires up, then build fresh
// Pro_Purchase_Territory + Pro_Place_Territory graphs whose pointers reference
// the loaded GameData. The result matches what Java's purchase phase would
// have left in `storedPurchaseTerritories` after the prior phase ran.

import "core:os"
import "core:fmt"
import "core:encoding/json"
import "core:log"

test_proai_state_apply :: proc(data: ^Game_Data, path: string, ais: []^Pro_Ai) {
	bytes, read_err := os.read_entire_file_from_path(path, context.allocator)
	if read_err != nil {
		// Missing sidecar is non-fatal: older snapshot layouts (or snaps
		// generated before this field existed) just leave AI memory empty.
		return
	}
	defer delete(bytes)

	val, parse_err := json.parse(bytes)
	if parse_err != nil {
		log.errorf("proai-state: parse failed for %s: %v", path, parse_err)
		return
	}

	root, root_ok := val.(json.Object)
	if !root_ok { return }
	players_val, has_players := root["players"]
	if !has_players { return }
	players, players_ok := players_val.(json.Object)
	if !players_ok { return }

	// name → Pro_Ai lookup built from the caller-supplied slice.
	pro_by_name := make(map[string]^Pro_Ai)
	defer delete(pro_by_name)
	for pro in ais {
		if pro == nil { continue }
		nm := pro.abstract_base_player.name
		if nm != "" { pro_by_name[nm] = pro }
	}

	gmap := game_data_get_map(data)
	if gmap == nil { return }
	if data.units_list == nil { return }
	units_by_id := data.units_list.units

	for player_name, player_val in players {
		pro, ok := pro_by_name[player_name]
		if !ok || pro == nil { continue }
		pobj, pobj_ok := player_val.(json.Object)
		if !pobj_ok { continue }

		// storedPurchaseTerritories: array of {territory, unitProduction, canPlaceTerritories}
		if spt_val, has_spt := pobj["storedPurchaseTerritories"]; has_spt {
			if spt_arr, arr_ok := spt_val.(json.Array); arr_ok {
				m := make(map[^Territory]^Pro_Purchase_Territory)
				for entry in spt_arr {
					eobj, eok := entry.(json.Object)
					if !eok { continue }
					tname := _proai_state_str(eobj, "territory")
					if tname == "" { continue }
					t := game_map_get_territory_or_null(gmap, tname)
					if t == nil { continue }
					ppt := new(Pro_Purchase_Territory)
					ppt.territory = t
					ppt.unit_production = i32(_proai_state_int(eobj, "unitProduction"))
					ppt.can_place_territories = make([dynamic]^Pro_Place_Territory)

					if cp_val, has_cp := eobj["canPlaceTerritories"]; has_cp {
						if cp_arr, cp_ok := cp_val.(json.Array); cp_ok {
							for cp_entry in cp_arr {
								cobj, cok := cp_entry.(json.Object)
								if !cok { continue }
								cname := _proai_state_str(cobj, "territory")
								if cname == "" { continue }
								ct := game_map_get_territory_or_null(gmap, cname)
								if ct == nil { continue }
								place := pro_place_territory_new(ct)
								if id_val, has_ids := cobj["placeUnitIds"]; has_ids {
									if id_arr, idok := id_val.(json.Array); idok {
										// Pull richer per-unit info (type, owner) from `placeUnits`
										// when present; the IDs in `placeUnitIds` are the canonical
										// order, so iterate that array and read alongside.
										place_units_arr: json.Array
										has_pu := false
										if pu_val, has_p := cobj["placeUnits"]; has_p {
											if pa, paok := pu_val.(json.Array); paok {
												place_units_arr = pa
												has_pu = true
											}
										}
										idx := 0
										for id_v in id_arr {
											if id_str, sok := id_v.(json.String); sok {
												uuid := _proai_state_parse_uuid(string(id_str))
												u, found := units_by_id[uuid]
												if !found && has_pu && idx < len(place_units_arr) {
													// Pro_Place_Territory.placeUnits are planning-only
													// stubs produced by ProPurchaseUtils.createUnits;
													// they never enter player.getUnits() / units_list
													// on the Java side. Build the Unit but DO NOT
													// register it in data.units_list.units, or it will
													// show up as a phantom in the purchase pool diff.
													if puobj, pook := place_units_arr[idx].(json.Object); pook {
														u = _proai_state_materialize_unit(data, puobj, uuid)
														if u != nil {
															found = true
														}
													}
												}
												if found && u != nil {
													append(&place.place_units, u)
												}
											}
											idx += 1
										}
									}
								}
								// New fields written by SnapshotHarness (after the initial sidecar
								// schema was extended): canHold persistence is critical for
								// prioritize_land_territories filtering; strategic/defense values
								// and defendingUnits influence subsequent place_defenders logic.
								if _, has := cobj["canHold"]; has {
									pro_place_territory_set_can_hold(place, _proai_state_bool(cobj, "canHold"))
								}
								if _, has := cobj["strategicValue"]; has {
									pro_place_territory_set_strategic_value(place, _proai_state_float(cobj, "strategicValue"))
								}
								if _, has := cobj["defenseValue"]; has {
									pro_place_territory_set_defense_value(place, _proai_state_float(cobj, "defenseValue"))
								}
								if du_val, has_du := cobj["defendingUnitIds"]; has_du {
									if du_arr, du_ok := du_val.(json.Array); du_ok {
										def_units := make([dynamic]^Unit)
										for du_v in du_arr {
											if du_str, ds_ok := du_v.(json.String); ds_ok {
												uuid := _proai_state_parse_uuid(string(du_str))
												if u, ok := units_by_id[uuid]; ok && u != nil {
													append(&def_units, u)
												}
											}
										}
										pro_place_territory_set_defending_units(place, def_units)
									}
								}
								append(&ppt.can_place_territories, place)
							}
						}
					}
					m[t] = ppt
				}
				pro.abstract_pro_ai.stored_purchase_territories = m
			}
		}
		if sst_val, has_sst := pobj["storedStrafingTerritories"]; has_sst {
			if sst_arr, arr_ok := sst_val.(json.Array); arr_ok {
				list := make([dynamic]^Territory)
				for entry in sst_arr {
					if name_s, sok := entry.(json.String); sok {
						t := game_map_get_territory_or_null(gmap, string(name_s))
						if t != nil { append(&list, t) }
					}
				}
				// Replace the default empty list (set in abstract_pro_ai_new)
				// with the restored one. The old list is small and short-lived.
				pro.abstract_pro_ai.stored_strafing_territories = list
			}
		}
	}
}

@(private="file")
_proai_state_str :: proc(obj: json.Object, key: string) -> string {
	v, ok := obj[key]
	if !ok { return "" }
	if s, sok := v.(json.String); sok { return string(s) }
	return ""
}

@(private="file")
_proai_state_int :: proc(obj: json.Object, key: string) -> int {
	v, ok := obj[key]
	if !ok { return 0 }
	if i, iok := v.(json.Integer); iok { return int(i) }
	if f, fok := v.(json.Float); fok { return int(f) }
	return 0
}

@(private="file")
_proai_state_float :: proc(obj: json.Object, key: string) -> f64 {
	v, ok := obj[key]
	if !ok { return 0 }
	if f, fok := v.(json.Float); fok { return f64(f) }
	if i, iok := v.(json.Integer); iok { return f64(i) }
	return 0
}

@(private="file")
_proai_state_bool :: proc(obj: json.Object, key: string) -> bool {
	v, ok := obj[key]
	if !ok { return false }
	if b, bok := v.(json.Boolean); bok { return bool(b) }
	return false
}

@(private="file")
_proai_state_parse_uuid :: proc(s: string) -> Uuid {
	// Same canonical 36-char dashed UUID format Java's UUID.toString emits;
	// reuse the helper the JSON unit loader uses by inlining the byte parse
	// here (test_common's string_to_uuid is in another package).
	uuid: Uuid
	if len(s) != 36 { return uuid }
	hex_i := 0
	for i := 0; i < 36; i += 1 {
		c := s[i]
		if c == '-' { continue }
		hi := _proai_hex_nibble(c)
		if hi < 0 { return Uuid{} }
		hex_i += 1
		i2 := i + 1
		if i2 >= 36 { return Uuid{} }
		lo := _proai_hex_nibble(s[i2])
		if lo < 0 { return Uuid{} }
		byte_idx := (hex_i - 1) / 2
		if byte_idx < 16 {
			uuid[byte_idx] = u8((hi << 4) | lo)
		}
		hex_i += 1
		i = i2
	}
	return uuid
}

// Holding-pile units (purchased but not yet placed) aren't included in the
// GameData JSON's flat `units` list. The sidecar's `placeUnits` array embeds
// the type+owner for each so we can construct stub Unit objects and register
// them in `data.units_list.units` for cantMoveUnits / pointer-equality usage.
@(private="file")
_proai_state_materialize_unit :: proc(data: ^Game_Data, obj: json.Object, uuid: Uuid) -> ^Unit {
	type_name := _proai_state_str(obj, "type")
	owner_name := _proai_state_str(obj, "owner")
	if type_name == "" { return nil }
	utl := game_data_get_unit_type_list(data)
	if utl == nil { return nil }
	ut := unit_type_list_get_unit_type(utl, type_name)
	if ut == nil { return nil }
	var_owner: ^Game_Player = nil
	if owner_name != "" {
		var_owner = player_list_get_player_id(game_data_get_player_list(data), owner_name)
	}
	return unit_new_with_uuid(uuid, ut, var_owner, data)
}

@(private="file")
_proai_hex_nibble :: proc(c: u8) -> int {
	switch {
	case c >= '0' && c <= '9': return int(c - '0')
	case c >= 'a' && c <= 'f': return int(c - 'a' + 10)
	case c >= 'A' && c <= 'F': return int(c - 'A' + 10)
	}
	return -1
}
