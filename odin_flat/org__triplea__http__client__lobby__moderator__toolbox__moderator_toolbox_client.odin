package game

Moderator_Toolbox_Client :: struct {
	toolbox_access_log_client:           ^Toolbox_Access_Log_Client,
	toolbox_user_ban_client:             ^Toolbox_User_Ban_Client,
	toolbox_username_ban_client:         ^Toolbox_Username_Ban_Client,
	toolbox_moderator_management_client: ^Toolbox_Moderator_Management_Client,
	toolbox_bad_words_client:            ^Toolbox_Bad_Words_Client,
	toolbox_event_log_client:            ^Toolbox_Event_Log_Client,
}

