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

