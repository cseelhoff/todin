package game

Must_Fight_Battle_10 :: struct {}

must_fight_battle_10_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_10 {
        self := new(Must_Fight_Battle_10)
        _ = outer
        return self
}
