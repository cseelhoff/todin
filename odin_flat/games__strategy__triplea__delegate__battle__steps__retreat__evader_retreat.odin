package game

import "core:fmt"

Evader_Retreat :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#addHistoryRetreat(
//   games.strategy.engine.delegate.IDelegateBridge,
//   java.util.Collection,
//   java.lang.String)
//
// Java:
//   final String transcriptText = MyFormatter.unitsToText(units) + suffix;
//   bridge.getHistoryWriter().addChildToEvent(transcriptText, new ArrayList<>(units));
evader_retreat_add_history_retreat :: proc(
	bridge: ^I_Delegate_Bridge,
	units: [dynamic]^Unit,
	suffix: string,
) {
	transcript_text := fmt.aprintf("%s%s", my_formatter_units_to_text(units), suffix)
	writer := i_delegate_bridge_get_history_writer(bridge)
	history_writer_add_child_to_event(writer, transcript_text, units)
}
