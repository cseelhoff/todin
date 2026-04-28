package game

Invoke :: struct {
	method_call_id:     Uuid,
	need_return_values: bool,
	call:               ^Remote_Method_Call,
}

// Java owners covered by this file:
//   - games.strategy.engine.message.unifiedmessenger.Invoke

