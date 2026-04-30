package game

Must_Fight_Battle_6 :: struct {}

must_fight_battle_6_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_6 {
        self := new(Must_Fight_Battle_6)
        _ = outer
        return self
}
