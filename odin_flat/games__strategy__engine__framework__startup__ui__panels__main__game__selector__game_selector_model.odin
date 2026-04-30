package game

Game_Selector_Model :: struct {
    using observable: Observable,
    using game_selector: Game_Selector,
    game_data: ^Game_Data,
    game_name: string,
    game_round: string,
    file_name: string,
    can_select: bool,
    host_is_headless_bot: bool,
    client_model_for_host_bots: ^Client_Model,
    ready_for_save_load: Count_Down_Latch,
}

make_Game_Selector_Model :: proc() -> Game_Selector_Model {
    return Game_Selector_Model{}
}

