package game

Message_Broadcaster :: struct {
	message_sender: proc(^Web_Socket_Session, ^Message_Envelope),
}
// Java owners covered by this file:
//   - org.triplea.web.socket.MessageBroadcaster

