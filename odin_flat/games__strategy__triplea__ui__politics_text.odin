package game

import "core:fmt"

// Java owners covered by this file:
//   - games.strategy.triplea.ui.PoliticsText

Politics_Text :: struct {
	properties: ^Properties,
}

politics_text_get_string :: proc(self: ^Politics_Text, key: string) -> string {
	return properties_get_property_or_default(self.properties, key, fmt.tprintf("NO: %s set.", key))
}

