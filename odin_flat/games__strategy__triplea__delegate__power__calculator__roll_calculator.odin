package game

// Java: games.strategy.triplea.delegate.power.calculator.RollCalculator
// Interface — modelled as a vtable struct.

Roll_Calculator :: struct {
        concrete:          rawptr,
        get_roll:          proc(self: ^Roll_Calculator, unit: ^Unit) -> ^Roll_Value,
        get_support_given: proc(self: ^Roll_Calculator) -> map[^Unit]^Integer_Map,
}

roll_calculator_get_roll :: proc(self: ^Roll_Calculator, unit: ^Unit) -> ^Roll_Value {
        return self.get_roll(self, unit)
}

// Java: Map<Unit, IntegerMap<Unit>> getSupportGiven();
roll_calculator_get_support_given :: proc(self: ^Roll_Calculator) -> map[^Unit]^Integer_Map {
        return self.get_support_given(self)
}
