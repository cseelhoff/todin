package game

// Anonymous inner class #1 of games.strategy.engine.vault.Vault
// Implements IRemoteVault; captures enclosing Vault instance.
Vault_1 :: struct {
	outer: ^Vault,
}

vault_1_new :: proc(outer: ^Vault) -> ^Vault_1 {
	self := new(Vault_1)
	self.outer = outer
	return self
}

