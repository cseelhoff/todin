package game

// Java: games.strategy.triplea.delegate.power.calculator.RollCalculator
// Interface — modelled as a vtable struct.

Roll_Calculator :: struct {
        concrete: rawptr,
        get_roll: proc(self: ^Roll_Calculator, unit: ^Unit) -> ^Roll_Value,
}

roll_calculator_get_roll :: proc(self: ^Roll_Calculator, unit: ^Unit) -> ^Roll_Value {
        return self.get_roll(self, unit)
}
