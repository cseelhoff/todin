package game

Triple :: struct($A, $B, $C: typeid) {
    first:  A,
    second: B,
    third:  C,
}

triple_get_first :: proc(self: ^Triple($A, $B, $C)) -> A {
    return self.first
}

triple_get_second :: proc(self: ^Triple($A, $B, $C)) -> B {
    return self.second
}

triple_get_third :: proc(self: ^Triple($A, $B, $C)) -> C {
    return self.third
}

