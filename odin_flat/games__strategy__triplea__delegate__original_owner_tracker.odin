package game

import "core:fmt"

Original_Owner_Tracker :: struct {}

// games.strategy.triplea.delegate.OriginalOwnerTracker#lambda$getOriginalOwnerOrThrow$0(Territory)
//
// Java:
//   () -> new IllegalStateException(
//       String.format("GamePlayer expected for Territory %s", t.getName()))
//
// The lambda is the Supplier passed to Optional.orElseThrow; it
// builds the exception message from the captured Territory. In the
// Odin port we materialize just the formatted message string — the
// caller decides how to surface the failure.
original_owner_tracker_lambda_get_original_owner_or_throw_0 :: proc(territory: ^Territory) -> string {
	return fmt.aprintf("GamePlayer expected for Territory %s", default_named_get_name(&territory.named_attachable.default_named))
}

