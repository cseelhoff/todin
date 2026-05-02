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
territory_attachment_get :: proc(
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
