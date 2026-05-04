package game

import "core:strings"

// Java owners covered by this file:
//   - games.strategy.triplea.ui.NotificationMessages

Notification_Messages :: struct {
	properties: Properties,
}

NOTIFICATION_MESSAGES_SOUND_CLIP_SUFFIX :: "_sounds"

notification_messages_get_message :: proc(self: ^Notification_Messages, notification_message_key: string) -> string {
	return properties_get_property(&self.properties, notification_message_key)
}

notification_messages_get_sounds_key :: proc(self: ^Notification_Messages, notification_message_key: string) -> string {
	key := strings.concatenate({notification_message_key, NOTIFICATION_MESSAGES_SOUND_CLIP_SUFFIX})
	defer delete(key)
	return properties_get_property(&self.properties, key)
}

notification_messages_new :: proc(rl: ^Resource_Loader) -> ^Notification_Messages {
	self := new(Notification_Messages)
	self.properties = resource_loader_load_property_file(rl, "notifications.properties")^
	return self
}

