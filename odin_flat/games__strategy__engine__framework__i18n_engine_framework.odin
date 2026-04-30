package game

I18n_Engine_Framework :: struct {
	using base: I18n_Resource_Bundle,
}

i18n_engine_framework_get_resource_path :: proc(self: ^I18n_Engine_Framework) -> string {
	return "i18n.games.strategy.engine.framework.ui"
}

