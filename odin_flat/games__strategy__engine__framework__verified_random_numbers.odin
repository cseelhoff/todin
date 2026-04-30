package game

Verified_Random_Numbers :: struct {
    values:     [dynamic]i32,
    annotation: string,
}

make_Verified_Random_Numbers :: proc(annotation: string, values: []i32) -> Verified_Random_Numbers {
    self := Verified_Random_Numbers{}
    self.values = make([dynamic]i32, 0, len(values))
    for v in values {
        append(&self.values, v)
    }
    self.annotation = annotation
    return self
}

// Java owners covered by this file:
//   - games.strategy.engine.framework.VerifiedRandomNumbers

