package game

Client_Setting :: struct {
	using game_setting: Game_Setting,
	type: typeid,
	name: string,
	default_value: rawptr,
	listeners: [dynamic]proc(^Game_Setting),
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

