package game

import "core:fmt"

// Java owners covered by this file:
//   - org.triplea.http.client.web.socket.messages.MessageType

Message_Type :: struct {
	message_type_id: string,
	payload_type:    typeid,
}

message_type_new :: proc(message_type_id: string, payload_type: typeid) -> ^Message_Type {
	self := new(Message_Type)
	self.message_type_id = message_type_id
	self.payload_type = payload_type
	return self
}

message_type_of :: proc(class_type: typeid) -> ^Message_Type {
	return message_type_new(fmt.aprintf("%v", class_type), class_type)
}

