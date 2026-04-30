package game

// JDK shim: java.util.Locale. The AI snapshot harness does not
// exercise localization; this is a minimal opaque marker carrying
// only language/country tags and the methods I18nResourceBundle calls.

Locale :: struct {
	language: string,
	country:  string,
}

// Static constants matching java.util.Locale.US, GERMANY, ENGLISH, GERMAN.
locale_us := Locale{language = "en", country = "US"}
locale_germany := Locale{language = "de", country = "DE"}
locale_english := Locale{language = "en", country = ""}
locale_german := Locale{language = "de", country = ""}

locale_new :: proc(language: string, country: string = "") -> Locale {
	return Locale{language = language, country = country}
}

// Mirrors Locale.toLanguageTag() — RFC-5646 form: "en-US", "de", etc.
locale_to_language_tag :: proc(self: Locale) -> string {
	if len(self.country) == 0 {
		return self.language
	}
	if len(self.language) == 0 {
		return self.country
	}
	return concat3(self.language, "-", self.country)
}

@(private="file") concat3 :: proc(a, b, c: string) -> string {
	out := make([]u8, len(a) + len(b) + len(c))
	copy(out, transmute([]u8)a)
	copy(out[len(a):], transmute([]u8)b)
	copy(out[len(a) + len(b):], transmute([]u8)c)
	return string(out)
}

locale_get_language :: proc(self: Locale) -> string {
	return self.language
}

locale_get_country :: proc(self: Locale) -> string {
	return self.country
}

locale_equals :: proc(a, b: Locale) -> bool {
	return a.language == b.language && a.country == b.country
}

// Locale.LanguageRange — represents a single weighted language range.
Locale_Language_Range :: struct {
	range:  string,
	weight: f64,
}

locale_language_range_new :: proc(range: string, weight: f64 = 1.0) -> Locale_Language_Range {
	return Locale_Language_Range{range = range, weight = weight}
}
