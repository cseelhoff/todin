package game

// Java owners covered by this file:
//   - games.strategy.engine.vault.Vault
Vault :: struct {
	secret_key_factory: ^Secret_Key_Factory,
	key_gen:            ^Key_Generator,
	channel_messenger:  ^I_Channel_Messenger,
	secret_keys:        map[^Vault_Id]^Secret_Key,
	unverified_values:  map[^Vault_Id][dynamic]u8,
	verified_values:    map[^Vault_Id][dynamic]u8,
	wait_for_lock:      struct {},
	remote_vault:       ^I_Remote_Vault,
}

VAULT_CHANNEL_NAME :: "games.strategy.engine.vault.IServerVault.VAULT_CHANNEL"

vault_channel :: proc() -> ^Remote_Name {
	return remote_name_new(VAULT_CHANNEL_NAME, class_new("games.strategy.engine.vault.Vault$IRemoteVault", "IRemoteVault"))
}

vault_new :: proc(channel_messenger: ^I_Channel_Messenger) -> ^Vault {
	self := new(Vault)
	self.channel_messenger = channel_messenger
	self.secret_keys = make(map[^Vault_Id]^Secret_Key)
	self.unverified_values = make(map[^Vault_Id][dynamic]u8)
	self.verified_values = make(map[^Vault_Id][dynamic]u8)
	self.remote_vault = new(I_Remote_Vault)
	i_channel_messenger_register_channel_subscriber(self.channel_messenger, self.remote_vault, vault_channel())
	self.secret_key_factory = new(Secret_Key_Factory)
	self.key_gen = new(Key_Generator)
	return self
}

vault_shut_down :: proc(self: ^Vault) {
	i_channel_messenger_unregister_channel_subscriber(self.channel_messenger, self.remote_vault, vault_channel())
}

