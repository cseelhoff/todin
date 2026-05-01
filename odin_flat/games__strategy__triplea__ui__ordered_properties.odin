package game

Ordered_Properties :: struct {
	using parent: Properties,
	keys:         map[string]struct{},
}

// Java owners covered by this file:
//   - games.strategy.triplea.ui.OrderedProperties

ordered_properties_new :: proc() -> ^Ordered_Properties {
	p := new(Ordered_Properties)
	p.values = make(map[string]string)
	p.keys = make(map[string]struct{})
	return p
}
