package game

import "core:fmt"
import "core:strings"

Territory_Attachment :: struct {
	using default_attachment: Default_Attachment,
	capital: string,
	original_factory: bool,
	production: i32,
	victory_city: i32,
	is_impassable: bool,
	original_owner: ^Game_Player,
	convoy_route: bool,
	convoy_attached: map[^Territory]struct{},
	change_unit_owners: [dynamic]^Game_Player,
	capture_unit_on_entering_by: [dynamic]^Game_Player,
	naval_base: bool,
	air_base: bool,
	kamikaze_zone: bool,
	unit_production: i32,
	blockade_zone: bool,
	territory_effect: [dynamic]^Territory_Effect,
	when_captured_by_goes_to: [dynamic]string,
	resources: ^Resource_Collection,
}

// =====================================================================
// Method ports — TerritoryAttachment instance/static accessors at
// method_layer 0. Java Optional<X> getters map to:
//   Optional<String>           -> string ("" denotes empty)
//   Optional<GamePlayer>       -> ^Game_Player (nil denotes empty)
//   Optional<ResourceCollection> -> ^Resource_Collection (nil denotes empty)
// Java getters that throw GameParseException are inlined as fmt.panicf
// matching the project convention (see canal_attachment_set_*).
// =====================================================================

// Java: public boolean getAirBase() { return airBase; }
territory_attachment_get_air_base :: proc(self: ^Territory_Attachment) -> bool {
	return self.air_base
}

// Java: public boolean getBlockadeZone() { return blockadeZone; }
territory_attachment_get_blockade_zone :: proc(self: ^Territory_Attachment) -> bool {
	return self.blockade_zone
}

// Java: public Optional<String> getCapital() { return Optional.ofNullable(capital); }
// "" denotes the Java null/absent case (see field declaration default).
territory_attachment_get_capital :: proc(self: ^Territory_Attachment) -> string {
	return self.capital
}

// Java: public List<GamePlayer> getCaptureUnitOnEnteringBy() {
//         return getListProperty(captureUnitOnEnteringBy);
//       }
territory_attachment_get_capture_unit_on_entering_by :: proc(
	self: ^Territory_Attachment,
) -> [dynamic]^Game_Player {
	return default_attachment_get_list_property(self.capture_unit_on_entering_by)
}

// Java: public Set<Territory> getConvoyAttached() {
//         return getSetProperty(convoyAttached);
//       }
territory_attachment_get_convoy_attached :: proc(
	self: ^Territory_Attachment,
) -> map[^Territory]struct {} {
	return default_attachment_get_set_property(self.convoy_attached)
}

// Java: public boolean getConvoyRoute() { return convoyRoute; }
territory_attachment_get_convoy_route :: proc(self: ^Territory_Attachment) -> bool {
	return self.convoy_route
}

// Java: public boolean getIsImpassable() { return isImpassable; }
territory_attachment_get_is_impassable :: proc(self: ^Territory_Attachment) -> bool {
	return self.is_impassable
}

// Java: public boolean getKamikazeZone() { return kamikazeZone; }
territory_attachment_get_kamikaze_zone :: proc(self: ^Territory_Attachment) -> bool {
	return self.kamikaze_zone
}

// Java: public boolean getNavalBase() { return navalBase; }
territory_attachment_get_naval_base :: proc(self: ^Territory_Attachment) -> bool {
	return self.naval_base
}

// Java: public boolean getOriginalFactory() { return originalFactory; }
territory_attachment_get_original_factory :: proc(self: ^Territory_Attachment) -> bool {
	return self.original_factory
}

// Java: public Optional<GamePlayer> getOriginalOwner() {
//         return Optional.ofNullable(originalOwner);
//       }
territory_attachment_get_original_owner :: proc(
	self: ^Territory_Attachment,
) -> ^Game_Player {
	return self.original_owner
}

// Java: @Getter private int production;
territory_attachment_get_production :: proc(self: ^Territory_Attachment) -> i32 {
	return self.production
}

// Java: public Optional<ResourceCollection> getResources() {
//         return Optional.ofNullable(resources);
//       }
territory_attachment_get_resources :: proc(
	self: ^Territory_Attachment,
) -> ^Resource_Collection {
	return self.resources
}

// Java: public List<TerritoryEffect> getTerritoryEffect() {
//         return getListProperty(territoryEffect);
//       }
territory_attachment_get_territory_effect :: proc(
	self: ^Territory_Attachment,
) -> [dynamic]^Territory_Effect {
	return default_attachment_get_list_property(self.territory_effect)
}

// Java: @Getter private int unitProduction;
territory_attachment_get_unit_production :: proc(self: ^Territory_Attachment) -> i32 {
	return self.unit_production
}

// Java: private List<String> getWhenCapturedByGoesTo() {
//         return getListProperty(whenCapturedByGoesTo);
//       }
territory_attachment_get_when_captured_by_goes_to :: proc(
	self: ^Territory_Attachment,
) -> [dynamic]string {
	return default_attachment_get_list_property(self.when_captured_by_goes_to)
}

// Java: public boolean isCapital() { return capital != null; }
// Empty Odin string mirrors Java's null sentinel.
territory_attachment_is_capital :: proc(self: ^Territory_Attachment) -> bool {
	return self.capital != ""
}

// Java: public void setCapital(final String value) throws GameParseException
// Validates that `value` resolves to a known player, then stores the name.
// Inlines `getPlayerByName` (Optional.ofNullable(getData().getPlayerList()
// .getPlayerId(name))) since DefaultAttachment.getPlayerByName is not yet
// ported. Java's GameParseException message is preserved verbatim.
territory_attachment_set_capital :: proc(self: ^Territory_Attachment, value: string) {
	game_data := game_data_component_get_data(
		&self.default_attachment.game_data_component,
	)
	player := player_list_get_player_id(game_data_get_player_list(game_data), value)
	if player == nil {
		fmt.panicf(
			"TerritoryAttachment: Setting capital with value %s not possible; No such player found",
			value,
		)
	}
	self.capital = value
}

// Java: private void setIsImpassable(final boolean value) { isImpassable = value; }
territory_attachment_set_is_impassable :: proc(self: ^Territory_Attachment, value: bool) {
	self.is_impassable = value
}

// Java: private void setOriginalOwner(final @Nullable GamePlayer gamePlayer) {
//         originalOwner = gamePlayer;
//       }
territory_attachment_set_original_owner :: proc(
	self: ^Territory_Attachment,
	game_player: ^Game_Player,
) {
	self.original_owner = game_player
}

// Java: private void setProduction(final String value) {
//         production = getInt(value);
//         unitProduction = production;  // do NOT remove
//       }
territory_attachment_set_production :: proc(self: ^Territory_Attachment, value: string) {
	parsed := default_attachment_get_int(&self.default_attachment, value)
	self.production = parsed
	self.unit_production = parsed
}

// Java: private void setVictoryCity(final int value) { victoryCity = value; }
territory_attachment_set_victory_city :: proc(self: ^Territory_Attachment, value: i32) {
	self.victory_city = value
}

// =====================================================================
// Synthetic javac-extracted lambdas. Each captures variables Java would
// pull from the enclosing scope; the Odin port passes them as explicit
// parameters since Odin's bare proc type cannot hold environment.
// =====================================================================

// Java: lambda$getFirstOwnedCapitalOrFirstUnownedCapitalOrThrow$0(GamePlayer)
// Source site: () -> new IllegalStateException(
//     String.format("Player %s has no owned capital or unowned capital as expected", player))
// Captures `player`. Returns the formatted message; surfaces Java's
// orElseThrow as fmt.panicf to match project convention.
territory_attachment_lambda_get_first_owned_capital_or_first_unowned_capital_or_throw_0 :: proc(
	player: ^Game_Player,
) -> string {
	if player == nil {
		return "Player null has no owned capital or unowned capital as expected"
	}
	return fmt.aprintf(
		"Player %s has no owned capital or unowned capital as expected",
		default_named_get_name(&player.named_attachable.default_named),
	)
}

// Java: lambda$getAllCapitals$1(GamePlayer player, List capitals,
//                               Territory current, String capital)
// Source site (inside getAllCapitals' ifPresent): capital ->
//   { if (player.getName().equals(capital)) capitals.add(current); }
// Captures `player`, `capitals`, `current`; the lambda parameter is `capital`.
territory_attachment_lambda_get_all_capitals_1 :: proc(
	player: ^Game_Player,
	capitals: ^[dynamic]^Territory,
	current: ^Territory,
	capital: string,
) {
	if player == nil || capitals == nil {
		return
	}
	if default_named_get_name(&player.named_attachable.default_named) == capital {
		append(capitals, current)
	}
}

// Java: lambda$getOrThrow$3(Territory)
// Source site (inside getOrThrow): () -> new IllegalStateException(
//     String.format("No territory attachment for %s, but expected here", t.getName()))
// Captures `t`.
territory_attachment_lambda_get_or_throw_3 :: proc(t: ^Territory) -> string {
	if t == nil {
		return "No territory attachment for null, but expected here"
	}
	return fmt.aprintf(
		"No territory attachment for %s, but expected here",
		default_named_get_name(&t.named_attachable.default_named),
	)
}

// Java: lambda$getWhatTerritoriesThisIsUsedInConvoysFor$4(Territory territory,
//                                                        Territory current)
// Source site: current -> !current.equals(territory)
// Captures `territory`; lambda param is `current`. Returned bool is the
// stream filter result.
territory_attachment_lambda_get_what_territories_this_is_used_in_convoys_for_4 :: proc(
	territory: ^Territory,
	current: ^Territory,
) -> bool {
	return current != territory
}

// Java: lambda$getCapitalOrThrow$7()
// Source site: () -> new IllegalStateException(
//     String.format("No expected capital found for TerritoryAttachment %s", this))
// Captures `this` (the receiver).
territory_attachment_lambda_get_capital_or_throw_7 :: proc(
	self: ^Territory_Attachment,
) -> string {
	rendered := default_attachment_to_string(&self.default_attachment)
	defer delete(rendered)
	return fmt.aprintf("No expected capital found for TerritoryAttachment %s", rendered)
}

// Java: lambda$getOriginalOwnerOrThrow$9()
// Source site: () -> new IllegalStateException(
//     String.format("Original owner expected for %s", this))
// Captures `this`.
territory_attachment_lambda_get_original_owner_or_throw_9 :: proc(
	self: ^Territory_Attachment,
) -> string {
	rendered := default_attachment_to_string(&self.default_attachment)
	defer delete(rendered)
	return fmt.aprintf("Original owner expected for %s", rendered)
}

// Java: lambda$toStringForInfo$14(StringBuilder sb, String br, GamePlayer origOwner)
// Source site (inside toStringForInfo's ifPresent): origOwner ->
//   { sb.append("Original Owner: ").append(origOwner.getName()); sb.append(br); }
// Captures `sb`, `br`; lambda param is `origOwner`.
territory_attachment_lambda_to_string_for_info_14 :: proc(
	sb: ^strings.Builder,
	br: string,
	orig_owner: ^Game_Player,
) {
	if sb == nil || orig_owner == nil {
		return
	}
	strings.write_string(sb, "Original Owner: ")
	strings.write_string(
		sb,
		default_named_get_name(&orig_owner.named_attachable.default_named),
	)
	strings.write_string(sb, br)
}

// Java: lambda$toStringForInfo$15(String br, String name)
// Source site (inside toStringForInfo's territoryEffect collector): name ->
//   "&nbsp;&nbsp;&nbsp;&nbsp;" + name + br
// Captures `br`; lambda param is `name`. Returns a freshly allocated string
// owned by the caller (matches Java's heap-allocated String result).
territory_attachment_lambda_to_string_for_info_15 :: proc(
	br: string,
	name: string,
) -> string {
	return fmt.aprintf("&nbsp;&nbsp;&nbsp;&nbsp;%s%s", name, br)
}

// Java: lambda$getPropertyOrEmpty$17() — () -> 0
// Source site: MutableProperty.ofMapper(getInt, setVictoryCity,
//   getVictoryCity, () -> 0) — supplier of the victoryCity default value.
territory_attachment_lambda_get_property_or_empty_17 :: proc() -> i32 {
	return 0
}

// Java: lambda$getPropertyOrEmpty$19() — () -> 0
// Source site: MutableProperty.ofMapper(getInt, setUnitProduction,
//   getUnitProduction, () -> 0) — supplier of the unitProduction default value.
territory_attachment_lambda_get_property_or_empty_19 :: proc() -> i32 {
	return 0
}

// =====================================================================
// Static accessors / extra setters and the remaining synthetic lambdas
// (method_layer 1).
// =====================================================================

// Java: static Optional<TerritoryAttachment> get(Territory t, String nameOfAttachment)
//   final TerritoryAttachment territoryAttachment =
//       (TerritoryAttachment) t.getAttachment(nameOfAttachment);
//   if (territoryAttachment == null && !t.isWater()) {
//       throw new IllegalStateException(
//           "No territory attachment for: " + t.getName()
//             + "(non-water) with name: " + nameOfAttachment);
//   }
//   return Optional.ofNullable(territoryAttachment);
// Odin: nil mirrors Optional.empty(); the IllegalStateException is
// surfaced via fmt.panicf in keeping with the project convention.
territory_attachment_get_named :: proc(
	t: ^Territory,
	name_of_attachment: string,
) -> ^Territory_Attachment {
	raw := named_attachable_get_attachment(&t.named_attachable, name_of_attachment)
	territory_attachment := cast(^Territory_Attachment)raw
	if territory_attachment == nil && !territory_is_water(t) {
		fmt.panicf(
			"No territory attachment for: %s(non-water) with name: %s",
			default_named_get_name(&t.named_attachable.default_named),
			name_of_attachment,
		)
	}
	return territory_attachment
}

// Java: public String getCapitalOrThrow()
//   return getCapital().orElseThrow(() -> new IllegalStateException(
//       String.format("No expected capital found for TerritoryAttachment %s", this)));
// Empty Odin string mirrors Java's null/absent capital.
territory_attachment_get_capital_or_throw :: proc(self: ^Territory_Attachment) -> string {
	if self.capital == "" {
		msg := territory_attachment_lambda_get_capital_or_throw_7(self)
		defer delete(msg)
		fmt.panicf("%s", msg)
	}
	return self.capital
}

// Java: private GamePlayer getOriginalOwnerOrNull()
//   return getOriginalOwner().orElse(null);
territory_attachment_get_original_owner_or_null :: proc(
	self: ^Territory_Attachment,
) -> ^Game_Player {
	return self.original_owner
}

// Java: public Collection<CaptureOwnershipChange> getCaptureOwnershipChanges()
//   return getWhenCapturedByGoesTo().stream()
//       .map(this::parseCaptureOwnershipChange)
//       .collect(Collectors.toList());
//
// `parseCaptureOwnershipChange` has no row in `port.sqlite` (it is not on
// the AI-test reachable surface), so its body is inlined here. The Java
// method splits each encoded string on ":", asserts two tokens, looks up
// both players, and wraps any GameParseException as IllegalStateException;
// both error paths are surfaced through fmt.panicf.
territory_attachment_get_capture_ownership_changes :: proc(
	self: ^Territory_Attachment,
) -> [dynamic]^Territory_Attachment_Capture_Ownership_Change {
	source := territory_attachment_get_when_captured_by_goes_to(self)
	result := make([dynamic]^Territory_Attachment_Capture_Ownership_Change)
	game_data := game_data_component_get_data(&self.default_attachment.game_data_component)
	players := game_data_get_player_list(game_data)
	for encoded in source {
		tokens := default_attachment_split_on_colon(encoded)
		defer delete(tokens)
		assert(len(tokens) == 2)
		from_player := player_list_get_player_id(players, tokens[0])
		if from_player == nil {
			msg := territory_attachment_lambda_parse_capture_ownership_change_11(
				self,
				encoded,
				tokens[:],
			)
			defer delete(msg)
			fmt.panicf("%s", msg)
		}
		to_player := player_list_get_player_id(players, tokens[1])
		if to_player == nil {
			msg := territory_attachment_lambda_parse_capture_ownership_change_12(
				self,
				encoded,
				tokens[:],
			)
			defer delete(msg)
			fmt.panicf("%s", msg)
		}
		change := new(Territory_Attachment_Capture_Ownership_Change)
		change.capturing_player = from_player
		change.receiving_player = to_player
		append(&result, change)
	}
	return result
}

// Java: private void setIsImpassable(final String value)
//   setIsImpassable(getBool(value));
// The boolean overload is `territory_attachment_set_is_impassable` (above);
// this Odin proc disambiguates the String overload via a `_str` suffix.
territory_attachment_set_is_impassable_str :: proc(self: ^Territory_Attachment, value: string) {
	territory_attachment_set_is_impassable(
		self,
		default_attachment_get_bool(&self.default_attachment, value),
	)
}

// Java: lambda$getAllCurrentlyOwnedCapitals$2(GamePlayer player,
//                                             Territory current,
//                                             List capitals,
//                                             String capital)
// Source site (inside getAllCurrentlyOwnedCapitals' ifPresent): capital ->
//   { if (player.getName().equals(capital) && player.equals(current.getOwner()))
//       capitals.add(current); }
// Captures `player`, `current`, `capitals`; lambda parameter is `capital`.
territory_attachment_lambda_get_all_currently_owned_capitals_2 :: proc(
	player: ^Game_Player,
	current: ^Territory,
	capitals: ^[dynamic]^Territory,
	capital: string,
) {
	if player == nil || current == nil || capitals == nil {
		return
	}
	if default_named_get_name(&player.named_attachable.default_named) == capital &&
	   player == territory_get_owner(current) {
		append(capitals, current)
	}
}

// Java: lambda$getPropertyOrEmpty$16(String) — javac-synthesized bridge for
// `DefaultAttachment::getInt` used by MutableProperty.ofMapper(...) on the
// `victoryCity` branch. Returns the parsed int (Java boxes to Integer to
// satisfy Function<String,Integer>).
territory_attachment_lambda_get_property_or_empty_16 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// Java: lambda$getPropertyOrEmpty$18(String) — same bridge for the
// `unitProduction` branch.
territory_attachment_lambda_get_property_or_empty_18 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// Java: lambda$parseCaptureOwnershipChange$11(String encoded, String[] tokens)
//   () -> new GameParseException(MessageFormat.format(
//     "Invalid captureOwnershipChange with value {0} \n from-player: {1} unknown{2}",
//     encodedCaptureOwnershipChange, tokens[0], thisErrorMsg()))
// Captures `encoded`, `tokens`, and `this` (for thisErrorMsg). Returned
// string is heap-allocated; caller deletes.
territory_attachment_lambda_parse_capture_ownership_change_11 :: proc(
	self: ^Territory_Attachment,
	encoded: string,
	tokens: []string,
) -> string {
	suffix := default_attachment_this_error_msg(&self.default_attachment)
	defer delete(suffix)
	return fmt.aprintf(
		"Invalid captureOwnershipChange with value %s \n from-player: %s unknown%s",
		encoded,
		tokens[0],
		suffix,
	)
}

// Java: lambda$parseCaptureOwnershipChange$12(String encoded, String[] tokens)
//   () -> new GameParseException(MessageFormat.format(
//     "Invalid captureOwnershipChange with value {0} \n to-player: {1} unknown{2}",
//     encodedCaptureOwnershipChange, tokens[1], thisErrorMsg()))
territory_attachment_lambda_parse_capture_ownership_change_12 :: proc(
	self: ^Territory_Attachment,
	encoded: string,
	tokens: []string,
) -> string {
	suffix := default_attachment_this_error_msg(&self.default_attachment)
	defer delete(suffix)
	return fmt.aprintf(
		"Invalid captureOwnershipChange with value %s \n to-player: %s unknown%s",
		encoded,
		tokens[1],
		suffix,
	)
}

// Java: lambda$setCapital$6(String value)
//   () -> new GameParseException(MessageFormat.format(
//     "TerritoryAttachment: Setting capital with value {0} not possible; No such player found",
//     value))
territory_attachment_lambda_set_capital_6 :: proc(value: string) -> string {
	return fmt.aprintf(
		"TerritoryAttachment: Setting capital with value %s not possible; No such player found",
		value,
	)
}

// Java: lambda$setOriginalOwner$8(String player)
//   () -> new GameParseException(MessageFormat.format(
//     "TerritoryAttachment: Setting originalOwner with value {0} not possible; No such player found",
//     player))
territory_attachment_lambda_set_original_owner_8 :: proc(player: string) -> string {
	return fmt.aprintf(
		"TerritoryAttachment: Setting originalOwner with value %s not possible; No such player found",
		player,
	)
}

// Java: lambda$setWhenCapturedByGoesTo$10(String value, String name)
//   () -> new GameParseException(MessageFormat.format(
//     "TerritoryAttachment: Setting whenCapturedByGoesTo with value {0} not possible; No player found for {1}",
//     value, name))
// Captures `value` and the loop's `name`.
territory_attachment_lambda_set_when_captured_by_goes_to_10 :: proc(
	value: string,
	name: string,
) -> string {
	return fmt.aprintf(
		"TerritoryAttachment: Setting whenCapturedByGoesTo with value %s not possible; No player found for %s",
		value,
		name,
	)
}

// Java: lambda$setConvoyAttached$13(String value, String subString)
//   () -> new GameParseException(MessageFormat.format(
//     "TerritoryAttachment: No territory found for {0}; Setting convoyAttached not possible with value {1}",
//     subString, value))
// Captures `value` and the loop's `subString`.
territory_attachment_lambda_set_convoy_attached_13 :: proc(
	value: string,
	sub_string: string,
) -> string {
	return fmt.aprintf(
		"TerritoryAttachment: No territory found for %s; Setting convoyAttached not possible with value %s",
		sub_string,
		value,
	)
}

// Java: public TerritoryAttachment(
//         final String name, final Attachable attachable, final GameData gameData) {
//   super(name, attachable, gameData);
// }
// Per the `default_attachment_new` comment ("Subclass constructors should
// allocate their own concrete struct and embed/initialize via field
// assignment instead of calling this proc directly"), the
// `DefaultAttachment` super-constructor body is replicated inline on the
// embedded `default_attachment` field. The Java field initializers (all
// `false`/`0`/`null`) match Odin's zero values, so no extra assignments
// are needed.
territory_attachment_new :: proc(
	name: string,
	attachable: ^Attachable,
	game_data: ^Game_Data,
) -> ^Territory_Attachment {
	self := new(Territory_Attachment)
	self.default_attachment.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	return self
}

// Java: public static Optional<TerritoryAttachment> get(final Territory t) {
//   return get(t, Constants.TERRITORY_ATTACHMENT_NAME);
// }
// The 2-arg package-private overload is not separately exposed in the port;
// its body is inlined here. `Optional<TerritoryAttachment>` maps to
// `^Territory_Attachment` (nil denotes the empty Optional).
//
//   static Optional<TerritoryAttachment> get(final Territory t, final String nameOfAttachment) {
//     final TerritoryAttachment territoryAttachment =
//         (TerritoryAttachment) t.getAttachment(nameOfAttachment);
//     if (territoryAttachment == null && !t.isWater()) {
//       throw new IllegalStateException(
//           "No territory attachment for: " + t.getName()
//               + "(non-water) with name: " + nameOfAttachment);
//     }
//     return Optional.ofNullable(territoryAttachment);
//   }
//
// `Constants.TERRITORY_ATTACHMENT_NAME` is the literal "territoryAttachment"
// (see Constants.java line 27); inlined since the Odin Constants file has
// not yet exported this token.
territory_attachment_get :: proc(t: ^Territory) -> ^Territory_Attachment {
	if t == nil {
		return nil
	}
	name_of_attachment := "territoryAttachment"
	att := named_attachable_get_attachment(&t.named_attachable, name_of_attachment)
	territory_attachment := cast(^Territory_Attachment)att
	if territory_attachment == nil && !territory_is_water(t) {
		fmt.panicf(
			"No territory attachment for: %s(non-water) with name: %s",
			default_named_get_name(&t.named_attachable.default_named),
			name_of_attachment,
		)
	}
	return territory_attachment
}

// Java: public static TerritoryAttachment getOrThrow(final @Nonnull Territory t) {
//   return get(t, Constants.TERRITORY_ATTACHMENT_NAME)
//       .orElseThrow(
//           () -> new IllegalStateException(
//               String.format(
//                   "No territory attachment for %s, but expected here", t.getName())));
// }
territory_attachment_get_or_throw :: proc(t: ^Territory) -> ^Territory_Attachment {
	result := territory_attachment_get(t)
	if result == nil {
		fmt.panicf(
			"No territory attachment for %s, but expected here",
			default_named_get_name(&t.named_attachable.default_named),
		)
	}
	return result
}

// Java: public static List<Territory> getAllCapitals(GamePlayer, GameMap)
//   final List<Territory> capitals = new ArrayList<>();
//   for (final Territory current : gameMap.getTerritories()) {
//     TerritoryAttachment.get(current)
//         .flatMap(TerritoryAttachment::getCapital)
//         .ifPresent(capital -> {
//           if (player.getName().equals(capital)) capitals.add(current);
//         });
//   }
//   if (!capitals.isEmpty()) return capitals;
//   if (player.getOptional()) return capitals;
//   throw new IllegalStateException("Capital not found for: " + player);
//
// `Optional.flatMap(getCapital)` collapses an absent attachment OR an absent
// capital field; in Odin both map to the empty string sentinel / nil pointer.
territory_attachment_get_all_capitals :: proc(
	player: ^Game_Player,
	game_map: ^Game_Map,
) -> [dynamic]^Territory {
	capitals := make([dynamic]^Territory)
	territories := game_map_get_territories(game_map)
	for current in territories {
		att := territory_attachment_get(current)
		if att == nil {
			continue
		}
		capital := territory_attachment_get_capital(att)
		if capital == "" {
			continue
		}
		territory_attachment_lambda_get_all_capitals_1(player, &capitals, current, capital)
	}
	if len(capitals) != 0 {
		return capitals
	}
	if game_player_get_optional(player) {
		return capitals
	}
	fmt.panicf(
		"Capital not found for: %s",
		default_named_get_name(&player.named_attachable.default_named),
	)
}

// Java: public static List<Territory> getAllCurrentlyOwnedCapitals(GamePlayer, GameMap)
//   final List<Territory> capitals = new ArrayList<>();
//   for (final Territory current : gameMap.getTerritories()) {
//     TerritoryAttachment.get(current)
//         .flatMap(TerritoryAttachment::getCapital)
//         .ifPresent(capital -> {
//           if (player.getName().equals(capital) && player.equals(current.getOwner()))
//             capitals.add(current);
//         });
//   }
//   return capitals;
territory_attachment_get_all_currently_owned_capitals :: proc(
	player: ^Game_Player,
	game_map: ^Game_Map,
) -> [dynamic]^Territory {
	capitals := make([dynamic]^Territory)
	territories := game_map_get_territories(game_map)
	for current in territories {
		att := territory_attachment_get(current)
		if att == nil {
			continue
		}
		capital := territory_attachment_get_capital(att)
		if capital == "" {
			continue
		}
		territory_attachment_lambda_get_all_currently_owned_capitals_2(
			player,
			current,
			&capitals,
			capital,
		)
	}
	return capitals
}

// Java: public static Optional<Territory> getFirstOwnedCapitalOrFirstUnownedCapital(
//         GamePlayer player, GameMap gameMap)
// See Java for the full body. `^Territory` (nil = empty Optional). Iteration
// order mirrors Java's: first owned capital with neighbors wins; otherwise
// any unowned capital, otherwise an owned capital with no neighbors;
// otherwise empty for optional players, panic otherwise.
territory_attachment_get_first_owned_capital_or_first_unowned_capital :: proc(
	player: ^Game_Player,
	game_map: ^Game_Map,
) -> ^Territory {
	capitals := make([dynamic]^Territory)
	defer delete(capitals)
	no_neighbor_capitals := make([dynamic]^Territory)
	defer delete(no_neighbor_capitals)
	player_name := default_named_get_name(&player.named_attachable.default_named)
	territories := game_map_get_territories(game_map)
	for current in territories {
		att := territory_attachment_get(current)
		if att == nil {
			continue
		}
		capital := territory_attachment_get_capital(att)
		if capital == "" {
			continue
		}
		if player_name != capital {
			continue
		}
		if player == territory_get_owner(current) {
			neighbors := game_map_get_neighbors(game_map, current)
			if len(neighbors) != 0 {
				return current
			}
			append(&no_neighbor_capitals, current)
		} else {
			append(&capitals, current)
		}
	}
	if len(capitals) != 0 {
		return capitals[0]
	}
	if len(no_neighbor_capitals) != 0 {
		return no_neighbor_capitals[0]
	}
	if game_player_get_optional(player) {
		return nil
	}
	fmt.panicf("Capital not found for: %s", player_name)
}

// Java: public static int getProduction(final Territory t)
//   return TerritoryAttachment.get(t).map(TerritoryAttachment::getProduction).orElse(0);
// `territory_attachment_get(t)` returns nil for water territories with no
// attachment (Optional.empty); panics for non-water without attachment, which
// matches Java's behavior since `.map().orElse(0)` is only reached when the
// Optional is non-empty (or empty due to water).
territory_attachment_static_get_production :: proc(t: ^Territory) -> i32 {
	att := territory_attachment_get(t)
	if att == nil {
		return 0
	}
	return territory_attachment_get_production(att)
}

// Java: public static int getUnitProduction(final Territory t)
//   return TerritoryAttachment.get(t).map(TerritoryAttachment::getUnitProduction).orElse(0);
territory_attachment_static_get_unit_production :: proc(t: ^Territory) -> i32 {
	att := territory_attachment_get(t)
	if att == nil {
		return 0
	}
	return territory_attachment_get_unit_production(att)
}

// Java: public static boolean hasNavalBase(final Territory t)
//   final Optional<TerritoryAttachment> opt = TerritoryAttachment.get(t);
//   return opt.isPresent() && opt.get().getNavalBase();
territory_attachment_has_naval_base :: proc(t: ^Territory) -> bool {
	att := territory_attachment_get(t)
	return att != nil && territory_attachment_get_naval_base(att)
}

// Java: public static boolean hasAirBase(final Territory t)
//   final Optional<TerritoryAttachment> opt = TerritoryAttachment.get(t);
//   return opt.isPresent() && opt.get().getAirBase();
territory_attachment_has_air_base :: proc(t: ^Territory) -> bool {
	att := territory_attachment_get(t)
	return att != nil && territory_attachment_get_air_base(att)
}

// Java: public static Collection<Territory> getWhatTerritoriesThisIsUsedInConvoysFor(
//         Territory territory, GameState data)
//   final Optional<TerritoryAttachment> optionalTerritoryAttachment =
//       TerritoryAttachment.get(territory);
//   if (optionalTerritoryAttachment.isEmpty()
//       || !optionalTerritoryAttachment.get().getConvoyRoute()) {
//     return new HashSet<>();
//   }
//   final Collection<Territory> territories = new HashSet<>();
//   data.getMap().getTerritories().stream()
//       .filter(current -> !current.equals(territory))                 // lambda 4
//       .forEach(current -> { ...lambda 5 body... });
//   return territories;
//
// Odin Set<Territory> -> map[^Territory]struct{}.
territory_attachment_get_what_territories_this_is_used_in_convoys_for :: proc(
	territory: ^Territory,
	data: ^Game_State,
) -> map[^Territory]struct {} {
	result := make(map[^Territory]struct {})
	att := territory_attachment_get(territory)
	if att == nil || !territory_attachment_get_convoy_route(att) {
		return result
	}
	territories := game_map_get_territories(game_state_get_map(data))
	for current in territories {
		if !territory_attachment_lambda_get_what_territories_this_is_used_in_convoys_for_4(
			territory,
			current,
		) {
			continue
		}
		territory_attachment_lambda_get_what_territories_this_is_used_in_convoys_for_5(
			territory,
			&result,
			current,
		)
	}
	return result
}

// Java: lambda$getWhatTerritoriesThisIsUsedInConvoysFor$5(
//         Territory territory, Collection<Territory> territories, Territory current)
// Source site (forEach body inside getWhatTerritoriesThisIsUsedInConvoysFor):
//   current -> {
//     final Optional<TerritoryAttachment> optionalCurrentTerritoryAttachment =
//         TerritoryAttachment.get(current);
//     if (optionalCurrentTerritoryAttachment.isEmpty()
//         || !optionalCurrentTerritoryAttachment.get().getConvoyRoute()) {
//       return;
//     }
//     if (optionalCurrentTerritoryAttachment.get().getConvoyAttached().contains(territory)) {
//       territories.add(current);
//     }
//   }
// Captures `territory` and the result set `territories`; lambda param is `current`.
territory_attachment_lambda_get_what_territories_this_is_used_in_convoys_for_5 :: proc(
	territory: ^Territory,
	territories: ^map[^Territory]struct {},
	current: ^Territory,
) {
	att := territory_attachment_get(current)
	if att == nil || !territory_attachment_get_convoy_route(att) {
		return
	}
	convoy_attached := territory_attachment_get_convoy_attached(att)
	if territory in convoy_attached {
		territories[current] = {}
	}
}

// =====================================================================
// Phase B method-layer additions:
//   * doWeHaveEnoughCapitalsToProduce
//   * getFirstOwnedCapitalOrFirstUnownedCapitalOrThrow
//   * getPropertyOrEmpty
// =====================================================================

// Java: public static boolean doWeHaveEnoughCapitalsToProduce(
//         GamePlayer player, GameMap gameMap)
//   final List<Territory> capitalsListOriginal =
//       TerritoryAttachment.getAllCapitals(player, gameMap);
//   final List<Territory> capitalsListOwned =
//       TerritoryAttachment.getAllCurrentlyOwnedCapitals(player, gameMap);
//   final PlayerAttachment pa = PlayerAttachment.get(player);
//   if (pa == null) {
//     return capitalsListOriginal.isEmpty() || !capitalsListOwned.isEmpty();
//   }
//   return pa.getRetainCapitalProduceNumber() <= capitalsListOwned.size();
territory_attachment_do_we_have_enough_capitals_to_produce :: proc(
	player: ^Game_Player,
	game_map: ^Game_Map,
) -> bool {
	capitals_list_original := territory_attachment_get_all_capitals(player, game_map)
	defer delete(capitals_list_original)
	capitals_list_owned := territory_attachment_get_all_currently_owned_capitals(
		player,
		game_map,
	)
	defer delete(capitals_list_owned)
	pa := player_attachment_get(player)
	if pa == nil {
		return len(capitals_list_original) == 0 || len(capitals_list_owned) != 0
	}
	return player_attachment_get_retain_capital_produce_number(pa) <=
		cast(i32)len(capitals_list_owned)
}

// Java: public static Territory getFirstOwnedCapitalOrFirstUnownedCapitalOrThrow(
//         GamePlayer player, GameMap gameMap)
//   return getFirstOwnedCapitalOrFirstUnownedCapital(player, gameMap)
//       .orElseThrow(() -> new IllegalStateException(String.format(
//           "Player %s has no owned capital or unowned capital as expected", player)));
territory_attachment_get_first_owned_capital_or_first_unowned_capital_or_throw :: proc(
	player: ^Game_Player,
	game_map: ^Game_Map,
) -> ^Territory {
	result := territory_attachment_get_first_owned_capital_or_first_unowned_capital(
		player,
		game_map,
	)
	if result == nil {
		msg := territory_attachment_lambda_get_first_owned_capital_or_first_unowned_capital_or_throw_0(
			player,
		)
		fmt.panicf("%s", msg)
	}
	return result
}

// Java: @Override public Optional<MutableProperty<?>> getPropertyOrEmpty(
//         final @NonNls String propertyName)
// A 19-arm switch over property names; each arm wires four Mutable_Property
// slots (typed setter / string setter / getter / resetter) following the
// pattern established in tech_attachment / canal_attachment. Slot thunks
// receive the receiver via ctx (rawptr → ^Territory_Attachment); getters
// heap-box scalar values to mirror Java's autoboxing. Default arm returns
// nil to model Optional.empty().
//
// String-setter parsing logic mirrors the Java private setters
// (setOriginalFactory(String), setProductionOnly(String), setConvoyRoute(String),
// setConvoyAttached(String), setChangeUnitOwners(String) [parsePlayerList],
// setCaptureUnitOnEnteringBy(String) [parsePlayerList], setNavalBase(String),
// setAirBase(String), setKamikazeZone(String), setBlockadeZone(String),
// setTerritoryEffect(String), setWhenCapturedByGoesTo(String),
// setResources(String)). DefaultAttachment.parsePlayerList is not yet
// individually ported, so its loop body (splitOnColon + getPlayerByName +
// orElseThrow) is inlined into the two arms that need it.
territory_attachment_get_property_or_empty :: proc(
	self: ^Territory_Attachment,
	property_name: string,
) -> Maybe(^Mutable_Property) {
	switch property_name {
	case "capital":
		return mutable_property_of_string(
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					territory_attachment_set_capital(cast(^Territory_Attachment)ctx, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(string)
					out^ = (cast(^Territory_Attachment)ctx).capital
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).capital = ""
				},
				ctx = self,
			},
		)
	case "originalFactory":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).original_factory = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.original_factory = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).original_factory
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).original_factory = false
				},
				ctx = self,
			},
		)
	case "production":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					value := (cast(^i32)v)^
					s.production = value
					s.unit_production = value
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					territory_attachment_set_production(cast(^Territory_Attachment)ctx, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = (cast(^Territory_Attachment)ctx).production
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					s := cast(^Territory_Attachment)ctx
					s.production = 0
					s.unit_production = 0
				},
				ctx = self,
			},
		)
	case "productionOnly":
		return mutable_property_of_write_only_string(
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.production = default_attachment_get_int(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
		)
	case "victoryCity":
		return mutable_property_of_mapper(
			proc(value: string) -> (rawptr, Maybe(string)) {
				out := new(i32)
				out^ = territory_attachment_lambda_get_property_or_empty_16(value)
				return out, nil
			},
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					territory_attachment_set_victory_city(
						cast(^Territory_Attachment)ctx,
						(cast(^i32)v)^,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = (cast(^Territory_Attachment)ctx).victory_city
					return out
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = territory_attachment_lambda_get_property_or_empty_17()
					return out
				},
				ctx = nil,
			},
		)
	case "isImpassable":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					territory_attachment_set_is_impassable(
						cast(^Territory_Attachment)ctx,
						(cast(^bool)v)^,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					territory_attachment_set_is_impassable_str(
						cast(^Territory_Attachment)ctx,
						v,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).is_impassable
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).is_impassable = false
				},
				ctx = self,
			},
		)
	case "originalOwner":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					territory_attachment_set_original_owner(
						cast(^Territory_Attachment)ctx,
						cast(^Game_Player)v,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					player := default_attachment_get_player_by_name(
						&s.default_attachment,
						v,
					)
					if player == nil {
						return territory_attachment_lambda_set_original_owner_8(v)
					}
					s.original_owner = player
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					return rawptr(
						territory_attachment_get_original_owner_or_null(
							cast(^Territory_Attachment)ctx,
						),
					)
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).original_owner = nil
				},
				ctx = self,
			},
		)
	case "convoyRoute":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).convoy_route = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.convoy_route = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).convoy_route
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).convoy_route = false
				},
				ctx = self,
			},
		)
	case "convoyAttached":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if v == nil {
						s.convoy_attached = nil
					} else {
						s.convoy_attached = (cast(^map[^Territory]struct {})v)^
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, value: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if len(value) == 0 {
						return nil
					}
					parts := default_attachment_split_on_colon(value)
					defer delete(parts)
					for sub_string in parts {
						territory := default_attachment_get_territory(
							&s.default_attachment,
							sub_string,
						)
						if territory == nil {
							return territory_attachment_lambda_set_convoy_attached_13(
								value,
								sub_string,
							)
						}
						if s.convoy_attached == nil {
							s.convoy_attached = make(map[^Territory]struct {})
						}
						s.convoy_attached[territory] = {}
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(map[^Territory]struct {})
					out^ = territory_attachment_get_convoy_attached(
						cast(^Territory_Attachment)ctx,
					)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).convoy_attached = nil
				},
				ctx = self,
			},
		)
	case "changeUnitOwners":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if v == nil {
						s.change_unit_owners = nil
					} else {
						s.change_unit_owners = (cast(^[dynamic]^Game_Player)v)^
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, value: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if strings.equal_fold(value, "true") ||
					   strings.equal_fold(value, "false") {
						s.change_unit_owners = nil
						return nil
					}
					parts := default_attachment_split_on_colon(value)
					defer delete(parts)
					for name in parts {
						player := default_attachment_get_player_by_name(
							&s.default_attachment,
							name,
						)
						if player == nil {
							return fmt.aprintf(
								"DefaultAttachment: Parsing PlayerList with value %s not possible; No player found for %s",
								value,
								name,
							)
						}
						if s.change_unit_owners == nil {
							s.change_unit_owners = make([dynamic]^Game_Player)
						}
						append(&s.change_unit_owners, player)
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new([dynamic]^Game_Player)
					out^ = default_attachment_get_list_property(
						(cast(^Territory_Attachment)ctx).change_unit_owners,
					)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).change_unit_owners = nil
				},
				ctx = self,
			},
		)
	case "captureUnitOnEnteringBy":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if v == nil {
						s.capture_unit_on_entering_by = nil
					} else {
						s.capture_unit_on_entering_by =
							(cast(^[dynamic]^Game_Player)v)^
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, value: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					parts := default_attachment_split_on_colon(value)
					defer delete(parts)
					for name in parts {
						player := default_attachment_get_player_by_name(
							&s.default_attachment,
							name,
						)
						if player == nil {
							return fmt.aprintf(
								"DefaultAttachment: Parsing PlayerList with value %s not possible; No player found for %s",
								value,
								name,
							)
						}
						if s.capture_unit_on_entering_by == nil {
							s.capture_unit_on_entering_by = make([dynamic]^Game_Player)
						}
						append(&s.capture_unit_on_entering_by, player)
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new([dynamic]^Game_Player)
					out^ = default_attachment_get_list_property(
						(cast(^Territory_Attachment)ctx).capture_unit_on_entering_by,
					)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).capture_unit_on_entering_by = nil
				},
				ctx = self,
			},
		)
	case "navalBase":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).naval_base = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.naval_base = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).naval_base
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).naval_base = false
				},
				ctx = self,
			},
		)
	case "airBase":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).air_base = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.air_base = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).air_base
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).air_base = false
				},
				ctx = self,
			},
		)
	case "kamikazeZone":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).kamikaze_zone = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.kamikaze_zone = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).kamikaze_zone
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).kamikaze_zone = false
				},
				ctx = self,
			},
		)
	case "unitProduction":
		return mutable_property_of_mapper(
			proc(value: string) -> (rawptr, Maybe(string)) {
				out := new(i32)
				out^ = territory_attachment_lambda_get_property_or_empty_18(value)
				return out, nil
			},
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).unit_production = (cast(^i32)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = (cast(^Territory_Attachment)ctx).unit_production
					return out
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = territory_attachment_lambda_get_property_or_empty_19()
					return out
				},
				ctx = nil,
			},
		)
	case "blockadeZone":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).blockade_zone = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					s.blockade_zone = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Territory_Attachment)ctx).blockade_zone
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).blockade_zone = false
				},
				ctx = self,
			},
		)
	case "territoryEffect":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if v == nil {
						s.territory_effect = nil
					} else {
						s.territory_effect = (cast(^[dynamic]^Territory_Effect)v)^
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, value: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					data := game_data_component_get_data(
						&s.default_attachment.game_data_component,
					)
					tel := game_data_get_territory_effect_list(data)
					parts := default_attachment_split_on_colon(value)
					defer delete(parts)
					for name in parts {
						effect, ok := tel[name]
						if !ok {
							suffix := default_attachment_this_error_msg(
								&s.default_attachment,
							)
							defer delete(suffix)
							return fmt.aprintf(
								"No TerritoryEffect named: %s%s",
								name,
								suffix,
							)
						}
						if s.territory_effect == nil {
							s.territory_effect = make([dynamic]^Territory_Effect)
						}
						append(&s.territory_effect, effect)
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new([dynamic]^Territory_Effect)
					out^ = territory_attachment_get_territory_effect(
						cast(^Territory_Attachment)ctx,
					)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).territory_effect = nil
				},
				ctx = self,
			},
		)
	case "whenCapturedByGoesTo":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					if v == nil {
						s.when_captured_by_goes_to = nil
					} else {
						s.when_captured_by_goes_to = (cast(^[dynamic]string)v)^
					}
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, value: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					parts := default_attachment_split_on_colon(value)
					defer delete(parts)
					if len(parts) != 2 {
						suffix := default_attachment_this_error_msg(
							&s.default_attachment,
						)
						defer delete(suffix)
						return fmt.aprintf(
							"whenCapturedByGoesTo must have 2 player names separated by a colon%s",
							suffix,
						)
					}
					for name in parts {
						if default_attachment_get_player_by_name(
							   &s.default_attachment,
							   name,
						   ) ==
						   nil {
							return territory_attachment_lambda_set_when_captured_by_goes_to_10(
								value,
								name,
							)
						}
					}
					if s.when_captured_by_goes_to == nil {
						s.when_captured_by_goes_to = make([dynamic]string)
					}
					append(&s.when_captured_by_goes_to, value)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new([dynamic]string)
					out^ = territory_attachment_get_when_captured_by_goes_to(
						cast(^Territory_Attachment)ctx,
					)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).when_captured_by_goes_to = nil
				},
				ctx = self,
			},
		)
	case "resources":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Territory_Attachment)ctx).resources = cast(^Resource_Collection)v
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, value: string) -> Maybe(string) {
					s := cast(^Territory_Attachment)ctx
					data := game_data_component_get_data(
						&s.default_attachment.game_data_component,
					)
					if s.resources == nil {
						s.resources = resource_collection_new(data)
					}
					parts := default_attachment_split_on_colon(value)
					defer delete(parts)
					if len(parts) < 2 {
						suffix := default_attachment_this_error_msg(
							&s.default_attachment,
						)
						defer delete(suffix)
						return fmt.aprintf(
							"resources must have an int amount and a resource name separated by a colon%s",
							suffix,
						)
					}
					amount := default_attachment_get_int(&s.default_attachment, parts[0])
					if parts[1] == "PUs" {
						suffix := default_attachment_this_error_msg(
							&s.default_attachment,
						)
						defer delete(suffix)
						return fmt.aprintf(
							"Please set PUs using production, not resource%s",
							suffix,
						)
					}
					resource := resource_list_get_resource_or_throw(
						game_data_get_resource_list(data),
						parts[1],
					)
					s.resources.resources[resource] = amount
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					return rawptr((cast(^Territory_Attachment)ctx).resources)
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Territory_Attachment)ctx).resources = nil
				},
				ctx = self,
			},
		)
	}
	return nil
}
