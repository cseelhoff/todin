package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.remote.IMoveDelegate
//
// Extends IAbstractMoveDelegate<UndoableMove> and IAbstractForumPosterDelegate.

I_Move_Delegate :: struct {
	using i_abstract_move_delegate: I_Abstract_Move_Delegate,
	using i_abstract_forum_poster_delegate: I_Abstract_Forum_Poster_Delegate,
}

