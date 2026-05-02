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

politics_text_get_message :: proc(self: ^Politics_Text, politics_key: string, message_key: string) -> string {
	return politics_text_get_string(self, fmt.tprintf("%s.%s", politics_key, message_key))
}

