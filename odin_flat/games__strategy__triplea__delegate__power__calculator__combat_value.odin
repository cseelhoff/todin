package game

// Java: games.strategy.triplea.delegate.power.calculator.CombatValue (interface)

Combat_Value :: struct {}


// Lambda: unit -> cache.computeIfAbsent(unit, getStrength) == 0
combat_value_lambda_unit_comparator_1 :: proc(cache: ^map[rawptr]int, get_strength: proc(rawptr) -> int, unit: rawptr) -> bool {
    val, ok := cache[unit]
    if !ok {
        val = get_strength(unit)
        cache[unit] = val
    }
    return val == 0
}
