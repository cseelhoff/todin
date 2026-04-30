package game

// JDK shim: java.util.logging.Level — minimal enum + helpers used by
// TripleA logging code. The AI snapshot harness does not exercise
// real Java logging; this is sufficient to satisfy callers that
// pass / compare Level constants.

Level :: enum {
	Off,
	Severe,
	Warning,
	Info,
	Config,
	Fine,
	Finer,
	Finest,
	All,
}

level_get_name :: proc(self: Level) -> string {
	switch self {
	case .Off:     return "OFF"
	case .Severe:  return "SEVERE"
	case .Warning: return "WARNING"
	case .Info:    return "INFO"
	case .Config:  return "CONFIG"
	case .Fine:    return "FINE"
	case .Finer:   return "FINER"
	case .Finest:  return "FINEST"
	case .All:     return "ALL"
	}
	return "INFO"
}

level_int_value :: proc(self: Level) -> i32 {
	switch self {
	case .Off:     return 2147483647
	case .Severe:  return 1000
	case .Warning: return 900
	case .Info:    return 800
	case .Config:  return 700
	case .Fine:    return 500
	case .Finer:   return 400
	case .Finest:  return 300
	case .All:     return -2147483648
	}
	return 800
}
