package game

I18n_Engine_Framework :: struct {
	using base: I18n_Resource_Bundle,
}

// public I18nEngineFramework() — implicit no-arg constructor; chains to
// I18nResourceBundle() which loads the bundle for getResourcePath().
i18n_engine_framework_new :: proc() -> ^I18n_Engine_Framework {
	ensure_i18n_locale()
	self := new(I18n_Engine_Framework)
	self.base.bundle = resource_bundle_new()
	return self
}

i18n_engine_framework_get_resource_path :: proc(self: ^I18n_Engine_Framework) -> string {
	return "i18n.games.strategy.engine.framework.ui"
}

// private static I18nResourceBundle instance;
@(private="file") instance: ^I18n_Resource_Bundle

// public static I18nResourceBundle get()
i18n_engine_framework_get :: proc() -> ^I18n_Resource_Bundle {
	if instance == nil {
		instance = &i18n_engine_framework_new().base
	}
	return instance
}

