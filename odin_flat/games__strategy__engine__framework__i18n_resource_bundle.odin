package game

I18n_Resource_Bundle :: struct {
	bundle: ^Resource_Bundle,
}

// Static field mirror of Java's:
//   private static final HashMap<Locale, Double> mapSupportedLocales =
//       getNewMapSupportedLocales();
// Lazily initialized on first access.
@(private="file") map_supported_locales: map[Locale]f64
@(private="file") map_supported_locales_init: bool

@(private="file") ensure_map_supported_locales :: proc() {
	if map_supported_locales_init {
		return
	}
	map_supported_locales = i18n_resource_bundle_get_new_map_supported_locales()
	map_supported_locales_init = true
}

// private static HashMap<Locale, Double> getNewMapSupportedLocales()
i18n_resource_bundle_get_new_map_supported_locales :: proc() -> map[Locale]f64 {
	new_map_supported_locales := make(map[Locale]f64)
	new_map_supported_locales[locale_us] = 1.0
	new_map_supported_locales[locale_germany] = 0.5
	return new_map_supported_locales
}

// public static List<Locale.LanguageRange> getSupportedLanguageRange()
// The Java code builds a "tag;q=weight,..." string and parses it via
// Locale.LanguageRange.parse; the resulting list is equivalent to one
// LanguageRange per (locale, weight) entry, which we build directly.
i18n_resource_bundle_get_supported_language_range :: proc() -> [dynamic]Locale_Language_Range {
	ensure_map_supported_locales()
	result := make([dynamic]Locale_Language_Range)
	for locale, weight in map_supported_locales {
		append(&result, locale_language_range_new(locale_to_language_tag(locale), weight))
	}
	return result
}

// public String getText(final String key)
i18n_resource_bundle_get_text :: proc(self: ^I18n_Resource_Bundle, key: string) -> string {
	return resource_bundle_get_string(self.bundle, key)
}
