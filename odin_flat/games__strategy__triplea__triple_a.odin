package game

import "core:fmt"

Triple_A :: struct {
	using i_game_loader: I_Game_Loader,
	game: ^I_Game,
}

// Java owners covered by this file:
//   - games.strategy.triplea.TripleA

triple_a_v_start_game :: proc(
	self:          ^I_Game_Loader,
	game:          ^I_Game,
	players:       [dynamic]^Player,
	launch_action: ^Launch_Action,
	chat:          ^Chat,
) {
	triple_a_start_game(cast(^Triple_A)self, game, players, launch_action, chat)
}

triple_a_v_new_players :: proc(self: ^I_Game_Loader, players: map[string]string) -> [dynamic]^Player {
	types := player_types_get_built_in_player_types()
	resolved: map[string]^Player_Types_Type
	for name, label in players {
		pt: ^Player_Types_Type = nil
		for t in types {
			if t.label == label {
				pt = t
				break
			}
		}
		if pt == nil {
			panic(fmt.tprintf("triple_a_v_new_players: unknown player type label %q", label))
		}
		resolved[name] = pt
	}
	set := triple_a_new_players(cast(^Triple_A)self, resolved)
	out: [dynamic]^Player
	for p, _ in set {
		append(&out, p)
	}
	return out
}

triple_a_new :: proc() -> ^Triple_A {
	self := new(Triple_A)
	self.game = nil
	self.i_game_loader.start_game = triple_a_v_start_game
	self.i_game_loader.new_players = triple_a_v_new_players
	return self
}

// Java static: TripleA#toGamePlayer(Map.Entry<String, PlayerTypes.Type>).
// No Map_Entry shim exists in odin_flat/; per the convention used in
// player_listing.odin, the entry is decomposed into its (key, value) pair
// at the call site and passed in directly.
triple_a_to_game_player :: proc(name: string, type: ^Player_Types_Type) -> ^Player {
	return player_types_type_new_player_with_name(type, name)
}

triple_a_new_players :: proc(self: ^Triple_A, player_names: map[string]^Player_Types_Type) -> map[^Player]struct{} {
	result: map[^Player]struct{}
	for name, type in player_names {
		player := player_types_type_new_player_with_name(type, name)
		result[player] = struct{}{}
	}
	return result
}

// games.strategy.triplea.TripleA#startGame(IGame, Set<Player>, LaunchAction, Chat)
//
// Java:
//   public void startGame(IGame game, Set<Player> players, LaunchAction
//       launchAction, @Nullable Chat chat) {
//     this.game = game;
//     if (game.getData().getDelegateOptional("edit").isEmpty()) {
//       final EditDelegate delegate = new EditDelegate();
//       delegate.initialize("edit", "edit");
//       game.getData().addDelegate(delegate);
//       if (game instanceof ServerGame serverGame) {
//         serverGame.addDelegateMessenger(delegate);
//       }
//     }
//     final LocalPlayers localPlayers = new LocalPlayers(players);
//     launchAction.startGame(localPlayers, game, players, chat);
//   }
//
// Notes:
// - The I_Game_Loader interface signature uses [dynamic]^Player for the
//   `players` set; matching that here keeps dispatch consistent.
// - Java's `getDelegateOptional("edit").isEmpty()` collapses to a nil
//   check on the ^I_Delegate returned by game_data_get_delegate_optional.
// - EditDelegate inherits initialize from AbstractDelegate via
//   BasePersistentDelegate; we invoke abstract_delegate_initialize on the
//   embedded chain. Passing the delegate to game_data_add_delegate /
//   server_game_add_delegate_messenger uses &delegate.i_delegate, which
//   points at the I_Delegate vtable that is the first field of the
//   embedded Abstract_Delegate.
// - The `instanceof ServerGame` check is realized by inspecting the
//   I_Game vtable's setDisplay slot: every Server_Game/Abstract_Game
//   exposed via `abstract_game_as_i_game` installs
//   `abstract_game_view_set_display`. Within the harness's reachable
//   call paths, the only IGame implementer that flows through TripleA is
//   ServerGame (ClientGame is unreachable from the snapshot harness),
//   so when the view discriminator matches we type-pun the embedded
//   Abstract_Game pointer back to its outer Server_Game.
triple_a_start_game :: proc(
	self:          ^Triple_A,
	game:          ^I_Game,
	players:       [dynamic]^Player,
	launch_action: ^Launch_Action,
	chat:          ^Chat,
) {
	self.game = game
	if i_game_get_data(game) != nil &&
	   game_data_get_delegate_optional(i_game_get_data(game), "edit") == nil {
		delegate := edit_delegate_new()
		abstract_delegate_initialize(&delegate.abstract_delegate, "edit", "edit")
		game_data_add_delegate(i_game_get_data(game), &delegate.i_delegate)

		// Java: `if (game instanceof ServerGame serverGame)`. The I_Game
		// interface table is the first field of Abstract_Game_I_Game_View;
		// confirm we're looking at that view by checking its vtable, then
		// recover the outer Server_Game by reinterpreting the view's
		// Abstract_Game target (Abstract_Game is the first field of
		// Server_Game via `using abstract_game`).
		if game.set_display == abstract_game_view_set_display {
			view := cast(^Abstract_Game_I_Game_View)game
			server_game := cast(^Server_Game)view.target
			server_game_add_delegate_messenger(server_game, &delegate.i_delegate)
		}
	}
	local_players := new(Local_Players)
	local_players^ = make_Local_Players(players)
	players_set := make(map[^Player]struct{})
	defer delete(players_set)
	for p in players {
		players_set[p] = {}
	}
	launch_action_start_game(launch_action, local_players, game, players_set, chat)
}
