package game

// Java: games.strategy.triplea.delegate.power.calculator.StrengthCalculator
// Interface — modelled as a vtable struct. Implementers wrap their concrete
// state in `concrete: rawptr` and populate the dispatch field in their
// `_to_strength_calculator` adapter proc.

Strength_Calculator :: struct {
        concrete:          rawptr,
        get_strength:      proc(self: ^Strength_Calculator, unit: ^Unit) -> ^Strength_Value,
        get_support_given: proc(self: ^Strength_Calculator) -> map[^Unit]^Integer_Map,
}

strength_calculator_get_strength :: proc(self: ^Strength_Calculator, unit: ^Unit) -> ^Strength_Value {
        return self.get_strength(self, unit)
}

// Java: Map<Unit, IntegerMap<Unit>> getSupportGiven();
strength_calculator_get_support_given :: proc(self: ^Strength_Calculator) -> map[^Unit]^Integer_Map {
        return self.get_support_given(self)
}
