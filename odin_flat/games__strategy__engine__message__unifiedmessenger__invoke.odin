package game

Invoke :: struct {
	method_call_id:     Uuid,
	need_return_values: bool,
	call:               ^Remote_Method_Call,
}

// Java owners covered by this file:
//   - games.strategy.engine.message.unifiedmessenger.Invoke

// Mirrors `Invoke(UUID, boolean, RemoteMethodCall)`. Java raises
// IllegalArgumentException when `needReturnValues` disagrees with whether
// `methodCallId` is null; here `Uuid` is a value type ([16]u8), so the
// "absent" id is the zero UUID.
invoke_new :: proc(
	method_call_id: Uuid,
	need_return_values: bool,
	call: ^Remote_Method_Call,
) -> ^Invoke {
	zero: Uuid
	if need_return_values && method_call_id == zero {
		panic("Cant have no id and need return values")
	}
	if !need_return_values && method_call_id != zero {
		panic("Cant have id and not need return values")
	}
	self := new(Invoke)
	self.method_call_id = method_call_id
	self.need_return_values = need_return_values
	self.call = call
	return self
}

