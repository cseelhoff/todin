package game

// games.strategy.engine.data.RelationshipTracker$RelatedPlayers
//
// Unordered pair of Game_Player pointers used as a map key.

Related_Players :: struct {
	player1: ^Game_Player,
	player2: ^Game_Player,
}

// games.strategy.engine.data.RelationshipTracker$RelatedPlayers#<init>
//
//   public RelatedPlayers(final GamePlayer player1, final GamePlayer player2) {
//     this.player1 = player1;
//     this.player2 = player2;
//   }
make_Relationship_Tracker_Related_Players :: proc(p1: ^Game_Player, p2: ^Game_Player) -> Related_Players {
	return Related_Players{player1 = p1, player2 = p2}
}

// java.util.Objects.hashCode shim: 0 for null, identity hash otherwise.
@(private="file")
related_players_player_hash :: proc(p: ^Game_Player) -> i32 {
	if p == nil {
		return 0
	}
	bits := u64(uintptr(rawptr(p)))
	return i32(bits) ~ i32(bits >> 32)
}

// games.strategy.engine.data.RelationshipTracker$RelatedPlayers#hashCode
//
//   public int hashCode() {
//     return Objects.hashCode(player1) + Objects.hashCode(player2);
//   }
related_players_hash_code :: proc(self: ^Related_Players) -> i32 {
	return related_players_player_hash(self.player1) + related_players_player_hash(self.player2)
}

related_players_equals :: proc(self: ^Related_Players, other: ^Related_Players) -> bool {
	if other == nil {
		return false
	}
	return (other.player1 == self.player1 && other.player2 == self.player2) ||
		(other.player2 == self.player1 && other.player1 == self.player2)
}

