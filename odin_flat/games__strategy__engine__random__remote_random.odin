package game

// Java owners covered by this file:
//   - games.strategy.engine.random.RemoteRandom

Remote_Random :: struct {
	plain_random:       ^Plain_Random_Source,
	game:               ^I_Game,
	remote_vault_id:    ^Vault_Id,
	annotation:         string,
	max:                int,
	waiting_for_unlock: bool,
	local_numbers:      []int,
}
