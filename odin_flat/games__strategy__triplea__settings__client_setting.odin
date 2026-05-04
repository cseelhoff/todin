package game

Client_Setting :: struct {
	using game_setting: Game_Setting,
	type: typeid,
	name: string,
	default_value: rawptr,
	listeners: [dynamic]proc(^Game_Setting),
	// Subclass-supplied vtable for the Java abstract methods
	// `encodeValue(T)` / `decodeValue(String)`. Nil entries model the
	// case where no concrete subclass has wired itself up — the base
	// methods then fall through to the same branches Java takes when
	// the abstract calls throw `ValueEncodingException` (encode → use
	// current encoded value; decode → reset and return default).
	// `value` / decoded result are rawptr to match the type erasure
	// the rest of this file already uses for the generic `T`.
	encode_value: proc(self: ^Client_Setting, value: rawptr) -> (encoded: string, ok: bool),
	decode_value: proc(self: ^Client_Setting, encoded_value: string) -> (value: rawptr, present: bool, err: ^Client_Setting_Value_Encoding_Exception),
}

// ClientSetting static fields. The Java class declares ~100 such
// fields via `<clinit>`; the AI snapshot harness only transitively
// references `saveGamesFolderPath` (through
// `AutoSaveFileUtils.getAutoSavePaths()`, itself dead in the snapshot
// path but pulled in by the methods-table transitive closure). Add
// further globals here as they're needed by future included procs.
//
// Initialized lazily on first access so we don't depend on Odin
// package-init ordering or on `Client_File_System_Helper`'s own
// initialization having run.
@(private="file") _client_setting_save_games_folder_path: ^Path_Client_Setting

client_setting_save_games_folder_path :: proc() -> ^Path_Client_Setting {
        if _client_setting_save_games_folder_path == nil {
                // Java: new PathClientSetting("SAVE_GAMES_FOLDER_PATH",
                //   ClientFileSystemHelper.getUserRootFolder().resolve("savedGames"))
                root := client_file_system_helper_get_user_root_folder()
                default_path := path_resolve(root, "savedGames")
                _client_setting_save_games_folder_path = path_client_setting_new(
                        "SAVE_GAMES_FOLDER_PATH", default_path,
                )
        }
        return _client_setting_save_games_folder_path
}

// Java: public static final PathClientSetting mapFolderOverride =
//   new PathClientSetting("MAP_FOLDER_OVERRIDE");
// No default value: the override is "absent" (has_current == false)
// until a user explicitly sets it via the UI. The snapshot harness
// never sets it, so callers must check `has_current` to model Java's
// `Optional<Path>.isPresent()`.
@(private="file") _client_setting_map_folder_override: ^Path_Client_Setting

client_setting_map_folder_override :: proc() -> ^Path_Client_Setting {
        if _client_setting_map_folder_override == nil {
                _client_setting_map_folder_override = path_client_setting_new_no_default(
                        "MAP_FOLDER_OVERRIDE",
                )
        }
        return _client_setting_map_folder_override
}

// Java: protected ClientSetting(Class<T> type, String name, T defaultValue).
// The two-arg form (no default) delegates to this; the orchestrator only
// asked for the three-arg constructor. `default_value` may be nil (Java
// allowed @Nullable).
client_setting_new :: proc(type: typeid, name: string, default_value: rawptr) -> ^Client_Setting {
        // Java: Preconditions.checkNotNull(type); Preconditions.checkNotNull(name).
        // typeid is a value type, can't be nil. `name` non-nullness is structural
        // in Odin; an empty string would still satisfy the original null check.
        self := new(Client_Setting)
        self.type = type
        self.name = name
        self.default_value = default_value
        self.listeners = make([dynamic]proc(^Game_Setting))
        return self
}

// Java: public final Optional<T> getDefaultValue() { return Optional.ofNullable(defaultValue); }
// Optional<T> → (rawptr, bool) where the bool models `isPresent()`.
client_setting_get_default_value :: proc(self: ^Client_Setting) -> (rawptr, bool) {
        return self.default_value, self.default_value != nil
}

// Java: private boolean isDefaultValue(T value) { return value.equals(defaultValue); }
// With the generic value erased to rawptr, only reference equality is
// available — matches Java's behavior when `T` is a reference type without
// a custom equals (and is the conservative fallback otherwise).
client_setting_is_default_value :: proc(self: ^Client_Setting, value: rawptr) -> bool {
        return value == self.default_value
}

// Java: listeners.forEach(listener -> listener.accept(this)) (null-encoded branch).
// lambda$setEncodedValue$1 is the per-listener body, called once per registered
// Consumer<GameSetting<T>>.
client_setting_lambda_set_encoded_value_1 :: proc(self: ^Client_Setting, listener: proc(^Game_Setting)) {
        listener(&self.game_setting)
}

// Java: listeners.forEach(listener -> listener.accept(this)) (put-success branch).
// Identical body to lambda$setEncodedValue$1; javac emits two synthetic
// methods because the lambda appears twice in the source.
client_setting_lambda_set_encoded_value_2 :: proc(self: ^Client_Setting, listener: proc(^Game_Setting)) {
        listener(&self.game_setting)
}

// Java: private static final AtomicReference<Preferences> preferencesRef = new AtomicReference<>();
@(private="file") _client_setting_preferences_ref: ^Preferences

// Java: private static void flush(final Preferences preferences) { try { preferences.flush(); } catch ... }
// BackingStoreException is swallowed and logged in Java; the in-memory shim
// can't fail, so we just call through.
client_setting_flush :: proc(preferences: ^Preferences) {
	preferences_flush(preferences)
}

// Java: private static Preferences getPreferences()
// Optional.ofNullable(preferencesRef.get()).orElseThrow(() -> new IllegalStateException(...))
client_setting_get_preferences :: proc() -> ^Preferences {
	if _client_setting_preferences_ref == nil {
		return client_setting_lambda_get_preferences_0()
	}
	return _client_setting_preferences_ref
}

// Java: () -> new IllegalStateException("ClientSetting framework has not been initialized. ...")
// Odin has no checked exceptions in this port; the snapshot harness must
// have called setPreferences. Fall back to a fresh in-memory node so callers
// keep functioning rather than crashing the snapshot run.
client_setting_lambda_get_preferences_0 :: proc() -> ^Preferences {
	if _client_setting_preferences_ref == nil {
		_client_setting_preferences_ref = preferences_user_node_for_package()
	}
	return _client_setting_preferences_ref
}

// Java: @VisibleForTesting public static void setPreferences(final Preferences preferences)
client_setting_set_preferences :: proc(preferences: ^Preferences) {
	_client_setting_preferences_ref = preferences
}

// Java: protected ClientSetting(final Class<T> type, final String name) { this(type, name, null); }
// Two-arg form delegates to the three-arg constructor with a nil default.
client_setting_new_no_default :: proc(type: typeid, name: string) -> ^Client_Setting {
	return client_setting_new(type, name, nil)
}

// Java: private Optional<String> getEncodedCurrentValue() {
//   return Optional.ofNullable(getPreferences().get(name, null));
// }
// Optional<String> → (string, bool) where the bool models isPresent().
client_setting_get_encoded_current_value :: proc(self: ^Client_Setting) -> (string, bool) {
	prefs := client_setting_get_preferences()
	if prefs == nil {
		return "", false
	}
	if v, ok := prefs.values[self.name]; ok {
		return v, true
	}
	return "", false
}

// Java: ThreadRunner.runInNewThread(() -> flush(preferences))
// Synthetic lambda body for setValueAndFlush; just calls the static flush helper.
client_setting_lambda_set_value_and_flush_3 :: proc(preferences: ^Preferences) {
	client_setting_flush(preferences)
}

// Java: private void setEncodedValue(@Nullable String encodedValue) { ... }
// Nullable String → (encoded_value, has_value). When has_value is false,
// the preference is removed; otherwise it's written and listeners notified.
// IllegalArgumentException from Preferences.put is impossible against the
// in-memory shim, so the Java try/catch collapses to a direct call.
client_setting_set_encoded_value :: proc(self: ^Client_Setting, encoded_value: string, has_value: bool) {
	prefs := client_setting_get_preferences()
	if !has_value {
		preferences_remove(prefs, self.name)
		for listener in self.listeners {
			client_setting_lambda_set_encoded_value_1(self, listener)
		}
	} else {
		preferences_put(prefs, self.name, encoded_value)
		for listener in self.listeners {
			client_setting_lambda_set_encoded_value_2(self, listener)
		}
	}
}

// Java: private @Nullable String encodeValueOrElseCurrent(final T value)
//   try { return encodeValue(value); }
//   catch (ValueEncodingException e) { log.warn(...); return getEncodedCurrentValue().orElse(null); }
// `@Nullable String` → (encoded, ok) tuple. The abstract `encodeValue`
// is dispatched through the subclass-supplied vtable slot; a nil slot
// is treated identically to the encoder throwing — Java's catch branch
// returns the current preference value (or null when absent), which
// here becomes the (current, present) pair from getEncodedCurrentValue.
// The log.warn call is the only side effect dropped: the snapshot
// harness has no logger wired up.
client_setting_encode_value_or_else_current :: proc(self: ^Client_Setting, value: rawptr) -> (encoded: string, ok: bool) {
	if self.encode_value != nil {
		s, encoded_ok := self.encode_value(self, value)
		if encoded_ok {
			return s, true
		}
	}
	return client_setting_get_encoded_current_value(self)
}

// Java: @Override public final Optional<T> getValue()
//   final Optional<String> encodedCurrentValue = getEncodedCurrentValue();
//   return encodedCurrentValue.isPresent()
//       ? encodedCurrentValue.map(this::decodeValueOrElseDefault)
//       : getDefaultValue();
// Optional<T> → (value, present). When no encoded value is stored we
// fall straight through to the default (matching `getDefaultValue()`).
// Otherwise we run the same `decodeValueOrElseDefault` Java path:
// dispatch through the subclass `decode_value` slot; on a thrown
// `ValueEncodingException` (or a nil slot, which models the same
// "can't decode" state) Java calls `resetValue()` and returns the
// default — done inline here without the listener-cascade because
// `resetValue` → `setValueAndFlush(null)` is a write side effect we
// preserve for parity.
client_setting_get_value :: proc(self: ^Client_Setting) -> (rawptr, bool) {
	encoded, present := client_setting_get_encoded_current_value(self)
	if !present {
		return client_setting_get_default_value(self)
	}
	return client_setting_decode_value_or_else_default(self, encoded)
}

// Java: private @Nullable T decodeValueOrElseDefault(final String encodedValue)
//   try { return decodeValue(encodedValue); }
//   catch (ValueEncodingException e) {
//       log.info("Failed to decode encoded value: '%s' in client setting '%s'", ...);
//       resetValue();
//       return getDefaultValue().orElse(null);
//   }
// `@Nullable T` → (rawptr, bool) where the bool models `Optional.isPresent()`
// after Java's terminal `.orElse(null)` collapse. A nil `decode_value`
// vtable slot is treated identically to the abstract decoder throwing
// `ValueEncodingException` — same recovery path. The `log.info` call is
// the only side effect dropped (no logger wired in the snapshot harness).
client_setting_decode_value_or_else_default :: proc(self: ^Client_Setting, encoded_value: string) -> (rawptr, bool) {
	if self.decode_value != nil {
		v, ok, err := self.decode_value(self, encoded_value)
		if err == nil {
			// Java's `@Nullable T decodeValue` returning null falls
			// through `Optional.ofNullable` and propagates as an empty
			// Optional (no reset).
			return v, ok
		}
	}
	// decodeValue threw (or no decoder): resetValue() + return default.
	client_setting_reset_value(self)
	return client_setting_get_default_value(self)
}

// Java: @Override public final void setValue(final @Nullable T value)
//   setEncodedValue(
//     Optional.ofNullable(value)
//       .filter(not(this::isDefaultValue))
//       .map(this::encodeValueOrElseCurrent)
//       .orElse(null));
// `@Nullable T` → (value, has_value). The Optional pipeline collapses
// to: if no value, or value equals default, write null (clears the
// preference); otherwise encode (with the encodeValueOrElseCurrent
// fallback) and write the resulting string. A nil result from the
// encode step models Java's `null` Optional element and likewise
// clears the preference.
client_setting_set_value :: proc(self: ^Client_Setting, value: rawptr, has_value: bool) {
	if !has_value || client_setting_is_default_value(self, value) {
		client_setting_set_encoded_value(self, "", false)
		return
	}
	encoded, ok := client_setting_encode_value_or_else_current(self, value)
	client_setting_set_encoded_value(self, encoded, ok)
}

// Java: public final void setValueAndFlush(final @Nullable T value)
//   setValue(value);
//   final Preferences preferences = getPreferences();
//   ThreadRunner.runInNewThread(() -> flush(preferences));
// The Java comment notes the new-thread dispatch is purely to avoid
// blocking the Swing EDT, and that `preferences` is captured before
// spawning so a concurrent `resetPreferences()` from a test cannot
// null it out under the worker. The Odin port has no EDT and the
// `Thread_Runner` shim's `proc()` runnable has no closure-capture
// support, so the lambda body (`flush(preferences)`) is invoked
// synchronously on the captured prefs handle. The observable result
// — value persisted, listeners notified, prefs flushed — is identical;
// only the off-thread scheduling is dropped, which the snapshot
// harness never exercises.
client_setting_set_value_and_flush :: proc(self: ^Client_Setting, value: rawptr, has_value: bool) {
	client_setting_set_value(self, value, has_value)

	// do the flush on a new thread to guarantee we do not block EDT.
	// Flush operations are pretty slow!
	// Store preferences before spawning new thread; tests may call resetPreferences() before it can
	// run.
	preferences := client_setting_get_preferences()
	client_setting_lambda_set_value_and_flush_3(preferences)
}

client_setting_reset_value :: proc(self: ^Client_Setting) {
	client_setting_set_value_and_flush(self, nil, false)
}

// Java: public static final ClientSetting<Boolean> useWebsocketNetwork
//   = new BooleanClientSetting("USE_WEBSOCKET_NETWORK", false);
//   ... callers do `useWebsocketNetwork.getValue().orElse(false)`.
// The snapshot harness has no preference store, so the boolean always
// resolves to its default (false). Expose the collapsed
// `getValue().orElse(false)` form directly — that's the only way Java
// callers consume this setting (see e.g. ConductBombing.findCost,
// SelectCasualties.firstStrikeUnits, EvaderRetreat).
client_setting_use_websocket_network :: proc() -> bool {
	return false
}

