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

politics_text_get_notification_success :: proc(self: ^Politics_Text, politics_key: string) -> string {
	return politics_text_get_message(self, politics_key, "NOTIFICATION_SUCCESS")
}

politics_text_get_notification_success_others :: proc(self: ^Politics_Text, politics_key: string) -> string {
	return politics_text_get_message(self, politics_key, "OTHER_NOTIFICATION_SUCCESS")
}

politics_text_get_notification_failure :: proc(self: ^Politics_Text, politics_key: string) -> string {
	return politics_text_get_message(self, politics_key, "NOTIFICATION_FAILURE")
}

politics_text_get_notification_failure_others :: proc(self: ^Politics_Text, politics_key: string) -> string {
	return politics_text_get_message(self, politics_key, "OTHER_NOTIFICATION_FAILURE")
}

politics_text_get_acceptance_question :: proc(self: ^Politics_Text, politics_key: string) -> string {
	return politics_text_get_message(self, politics_key, "ACCEPT_QUESTION")
}

politics_text_new :: proc(rl: ^Resource_Loader) -> ^Politics_Text {
	self := new(Politics_Text)
	self.properties = resource_loader_load_property_file(rl, "politicstext.properties")
	return self
}

