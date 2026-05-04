package game

import "core:fmt"

Change_Factory :: struct {}

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.ChangeFactory

change_factory_add_battle_records :: proc(records: ^Battle_Records, data: ^Game_State) -> ^Change {
	return add_battle_records_change_new(records, data)
}
change_factory_add_production_rule :: proc(rule: ^Production_Rule, frontier: ^Production_Frontier) -> ^Change {
	assert(rule != nil)
	assert(frontier != nil)
	apr := new(Add_Production_Rule)
	apr.kind = .Add_Production_Rule
	apr.rule = rule
	apr.frontier = frontier
	return &apr.change
}

// Java: ChangeFactory#addUnits(UnitHolder, Collection<Unit>) — returns a
// Change that adds `units` to `holder`'s UnitCollection. Mirrors
// `new AddUnits(holder.getUnitCollection(), units)`, which itself
// delegates to the (name, type, units) constructor reading the
// holder's name and type off the collection's NamedUnitHolder.
change_factory_add_units :: proc(holder: ^Unit_Holder, units: [dynamic]^Unit) -> ^Change {
	coll := unit_holder_get_unit_collection(holder)
	au := new(Add_Units)
	au.kind = .Add_Units
	au.name = coll.holder.named.base.name
	au.type = named_unit_holder_get_type(coll.holder)
	au.units = units
	au.unit_owner_map = add_units_build_unit_owner_map(units)
	return &au.change
}

// Java: ChangeFactory#attachmentPropertyChange(IAttachment, Object, String)
//   return new ChangeAttachmentChange(attachment, newValue, property);
change_factory_attachment_property_change :: proc(attachment: ^I_Attachment, new_value: rawptr, property_name: string) -> ^Change {
	return change_attachment_change_new(attachment, new_value, property_name)
}

// Java: ChangeFactory#changePlayerWhoAmIChange(GamePlayer, String) —
// returns `new PlayerWhoAmIChange(encodedPlayerTypeAndName, player)`,
// whose constructor reads `player.getWhoAmI()` and `player.getName()`.
change_factory_change_player_who_am_i_change :: proc(player: ^Game_Player, new_who_am_i: string) -> ^Change {
	c := new(Player_Who_Am_I_Change)
	c.kind = .Player_Who_Am_I_Change
	c.start_who_am_i = player.who_am_i
	c.end_who_am_i = new_who_am_i
	c.player_name = player.name
	return &c.change
}

// Java: ChangeFactory#changeOwner(Collection<Unit>, GamePlayer, Territory)
// — returns a Change that re-owns each unit in `units` to `owner` while
// recording the prior owner per unit-id, so the change can be inverted.
// Mirrors `new PlayerOwnerChange(units, owner, location)`.
change_factory_change_owner_3 :: proc(units: [dynamic]^Unit, owner: ^Game_Player, territory: ^Territory) -> ^Change {
	poc := new(Player_Owner_Change)
	poc.kind = .Player_Owner_Change
	poc.old_owner_names_by_unit_id = make(map[Uuid]string)
	poc.new_owner_names_by_unit_id = make(map[Uuid]string)
	poc.territory_name = territory.named.base.name
	for unit in units {
		poc.old_owner_names_by_unit_id[unit.id] = unit.owner.named.base.name
		poc.new_owner_names_by_unit_id[unit.id] = owner.named.base.name
	}
	return &poc.change
}

// Java: ChangeFactory#removeUnits(UnitHolder, Collection<Unit>) — returns a
// Change that removes `units` from `holder`'s UnitCollection. Mirrors
// `new RemoveUnits(holder.getUnitCollection(), units)`, which delegates to
// the (name, type, units) constructor reading the holder's name and type
// off the collection's NamedUnitHolder.
change_factory_remove_units :: proc(holder: ^Unit_Holder, units: [dynamic]^Unit) -> ^Change {
	coll := unit_holder_get_unit_collection(holder)
	ru := new(Remove_Units)
	ru.kind = .Remove_Units
	ru.name = coll.holder.named.base.name
	ru.type = named_unit_holder_get_type(coll.holder)
	ru.units = units
	ru.unit_owner_map = add_units_build_unit_owner_map(units)
	return &ru.change
}

// Java: ChangeFactory#bombingUnitDamage(IntegerMap<Unit>, Collection<Territory>) —
// returns a Change that SETS bombing damage on the given units (not additive).
// Mirrors `new BombingUnitDamageChange(newDamage, territoriesToNotify)`.
change_factory_bombing_unit_damage :: proc(damage: ^Integer_Map_Unit, territories: [dynamic]^Territory) -> ^Change {
	return bombing_unit_damage_change_new(damage, territories)
}

// Java: ChangeFactory#changeResourcesChange(GamePlayer, Resource, int) —
// `return new ChangeResourceChange(player, resource, quantity)`. The
// constructor stores `player.getName()` and `resource.getName()`.
change_factory_change_resources_change :: proc(player: ^Game_Player, resource: ^Resource, quantity: i32) -> ^Change {
	crc := new(Change_Resource_Change)
	crc.kind = .Change_Resource_Change
	crc.player_name = player.named.base.name
	crc.resource_name = resource.named.base.name
	crc.quantity = quantity
	return &crc.change
}


// Java: ChangeFactory#changeOwner(Territory, GamePlayer) — returns a Change
// that transfers ownership of `territory` to `owner`. Mirrors
// `new OwnerChange(territory, owner)`, which captures the current owner's
// name as `oldOwnerName`, the new owner's name (or null) as `newOwnerName`,
// and the territory's name. `owner` may be null.
change_factory_change_owner :: proc(territory: ^Territory, owner: ^Game_Player) -> ^Change {
	oc := new(Owner_Change)
	oc.kind = .Owner_Change
	oc.territory_name = default_named_get_name(&territory.named_attachable.default_named)
	if owner == nil {
		oc.new_owner_name = ""
	} else {
		oc.new_owner_name = default_named_get_name(&owner.named_attachable.default_named)
	}
	oc.old_owner_name = default_named_get_name(&territory.owner.named_attachable.default_named)
	return &oc.change
}

// Java: ChangeFactory#unitsHit(IntegerMap<Unit>, Collection<Territory>) —
// "Must already include existing damage to the unit. This does not add
// damage, it sets damage." Mirrors
// `new UnitDamageReceivedChange(newHits, territoriesToNotify)`, whose
// constructor records the new total damage (entry value) and old total
// damage (each unit's current `hits`) keyed by the unit's UUID string,
// plus the names of the territories that contain the affected units.
change_factory_units_hit :: proc(hits: ^Integer_Map_Unit, territories: [dynamic]^Territory) -> ^Change {
	udrc := new(Unit_Damage_Received_Change)
	udrc.kind = .Unit_Damage_Received_Change
	udrc.new_total_damage = make(map[string]i32, len(hits.entries))
	udrc.old_total_damage = make(map[string]i32, len(hits.entries))
	for unit, damage in hits.entries {
		id := unit.id
		key := fmt.aprintf(
			"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
			id[0], id[1], id[2], id[3],
			id[4], id[5],
			id[6], id[7],
			id[8], id[9],
			id[10], id[11], id[12], id[13], id[14], id[15],
		)
		udrc.new_total_damage[key] = damage
		udrc.old_total_damage[key] = unit.hits
	}
	udrc.territories_to_notify = make([dynamic]string, 0, len(territories))
	for territory in territories {
		append(&udrc.territories_to_notify, territory.named.base.name)
	}
	return &udrc.change
}

// Java: ChangeFactory#unitPropertyChange(Unit, Object, String)
//   return new ObjectPropertyChange(unit, propertyName, newValue);
change_factory_unit_property_change :: proc(unit: ^Unit, new_value: rawptr, property_name: string) -> ^Change {
	return object_property_change_new(unit, property_name, new_value)
}

// Java: ChangeFactory#unitPropertyChange(Unit, Object, Unit.PropertyName)
//   return unitPropertyChange(unit, newValue, unitPropertyName.toString());
change_factory_unit_property_change_property_name :: proc(unit: ^Unit, new_value: rawptr, unit_property_name: Unit_Property_Name) -> ^Change {
	pn := unit_property_name
	return change_factory_unit_property_change(unit, new_value, unit_property_name_to_string(&pn))
}

// Java: ChangeFactory#addAvailableTech(TechnologyFrontier, TechAdvance, GamePlayer)
//   return new AddAvailableTech(tf, ta, player);
change_factory_add_available_tech :: proc(tf: ^Technology_Frontier, ta: ^Tech_Advance, player: ^Game_Player) -> ^Change {
	return add_available_tech_new(tf, ta, player)
}

// Java: ChangeFactory#removeAvailableTech(TechnologyFrontier, TechAdvance, GamePlayer)
//   return new RemoveAvailableTech(tf, ta, player);
change_factory_remove_available_tech :: proc(tf: ^Technology_Frontier, ta: ^Tech_Advance, player: ^Game_Player) -> ^Change {
	return remove_available_tech_new(tf, ta, player)
}

// Java: ChangeFactory#attachmentPropertyReset(IAttachment, String)
//   return new AttachmentPropertyReset(attachment, property);
change_factory_attachment_property_reset :: proc(attachment: ^I_Attachment, property: string) -> ^Change {
	return attachment_property_reset_new(attachment, property)
}

// Java: ChangeFactory#changeProductionFrontier(GamePlayer, ProductionFrontier)
//   return new ProductionFrontierChange(frontier, player);
change_factory_change_production_frontier :: proc(player: ^Game_Player, frontier: ^Production_Frontier) -> ^Change {
	return production_frontier_change_new(frontier, player)
}

// Java: ChangeFactory#genericTechChange(TechAttachment, boolean, String)
//   return new GenericTechChange(attachment, value, property);
change_factory_generic_tech_change :: proc(attachment: ^Tech_Attachment, value: bool, property: string) -> ^Change {
	return generic_tech_change_new(attachment, value, property)
}

// Java: ChangeFactory#relationshipChange(GamePlayer, GamePlayer, RelationshipType, RelationshipType)
//   return new RelationshipChange(player, player2, currentRelation, newRelation);
change_factory_relationship_change :: proc(player: ^Game_Player, player2: ^Game_Player, current_relation: ^Relationship_Type, new_relation: ^Relationship_Type) -> ^Change {
	return relationship_change_new(player, player2, current_relation, new_relation)
}

// Java: ChangeFactory#removeProductionRule(ProductionRule, ProductionFrontier)
//   return new RemoveProductionRule(rule, frontier);
change_factory_remove_production_rule :: proc(rule: ^Production_Rule, frontier: ^Production_Frontier) -> ^Change {
	return remove_production_rule_new(rule, frontier)
}

// Java: ChangeFactory#removeResourceCollection(GamePlayer, ResourceCollection)
//   final CompositeChange compositeChange = new CompositeChange();
//   for (final Resource r : resourceCollection.getResourcesCopy().keySet()) {
//     compositeChange.add(
//         new ChangeResourceChange(gamePlayer, r, -resourceCollection.getQuantity(r)));
//   }
//   return compositeChange;
change_factory_remove_resource_collection :: proc(game_player: ^Game_Player, resource_collection: ^Resource_Collection) -> ^Change {
	composite_change := composite_change_new()
	resources_copy := resource_collection_get_resources_copy(resource_collection)
	defer delete(resources_copy)
	for r, _ in resources_copy {
		composite_change_add(
			composite_change,
			change_factory_change_resources_change(game_player, r, -resource_collection_get_quantity(resource_collection, r)),
		)
	}
	return &composite_change.change
}
