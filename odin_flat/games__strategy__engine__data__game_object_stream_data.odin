package game

Game_Object_Stream_Data :: struct {
    name: string,
    type: Game_Object_Stream_Data_Game_Type,
}

game_object_stream_data_new :: proc(named: ^Named) -> ^Game_Object_Stream_Data {
    self := new(Game_Object_Stream_Data)
    self^ = make_Game_Object_Stream_Data(named)
    return self
}

make_Game_Object_Stream_Data :: proc(named: ^Named) -> Game_Object_Stream_Data {
    self: Game_Object_Stream_Data
    self.name = named.base.name
    switch named.kind {
    case .Game_Player:
        self.type = .PLAYERID
    case .Territory:
        self.type = .TERRITORY
    case .Unit_Type:
        self.type = .UNITTYPE
    case .Production_Rule:
        self.type = .PRODUCTIONRULE
    case .Production_Frontier:
        self.type = .PRODUCTIONFRONTIER
    case .I_Attachment, .Other:
        panic("Wrong type")
    }
    return self
}

game_object_stream_data_can_serialize :: proc(obj: ^Named) -> bool {
    if obj == nil {
        return false
    }
    switch obj.kind {
    case .Game_Player, .Unit_Type, .Territory, .Production_Rule, .Production_Frontier, .I_Attachment:
        return true
    case .Other:
        return false
    }
    return false
}

game_object_stream_data_write_external :: proc(self: ^Game_Object_Stream_Data, out: ^Object_Output) {
    object_output_write_object(out, rawptr(&self.name))
    object_output_write_byte(out, u8(i32(self.type)))
}

game_object_stream_data_read_external :: proc(self: ^Game_Object_Stream_Data, in_stream: ^Object_Input) {
    // No-op compile-only path; see odin_flat/java__io__object_input.odin.
    _ = object_input_read_object(in_stream)
    self.name = ""
    self.type = Game_Object_Stream_Data_Game_Type(i32(object_input_read_byte(in_stream)))
}

game_object_stream_data_get_reference :: proc(self: ^Game_Object_Stream_Data, data: ^Game_Data) -> ^Named {
    if data == nil {
        panic("data must not be null")
    }
    game_data_acquire_read_lock(data)
    switch self.type {
    case .PLAYERID:
        p := player_list_get_player_id(game_data_get_player_list(data), self.name)
        if p == nil {
            return nil
        }
        return &p.named_attachable.default_named.named
    case .TERRITORY:
        t := game_map_get_territory_or_null(game_data_get_map(data), self.name)
        if t == nil {
            return nil
        }
        return &t.named_attachable.default_named.named
    case .UNITTYPE:
        ut := unit_type_list_get_unit_type_or_throw(game_data_get_unit_type_list(data), self.name)
        if ut == nil {
            return nil
        }
        return &ut.named_attachable.default_named.named
    case .PRODUCTIONRULE:
        pr := production_rule_list_get_production_rule(game_data_get_production_rule_list(data), self.name)
        if pr == nil {
            return nil
        }
        return &pr.default_named.named
    case .PRODUCTIONFRONTIER:
        pf := production_frontier_list_get_production_frontier(game_data_get_production_frontier_list(data), self.name)
        if pf == nil {
            return nil
        }
        return &pf.default_named.named
    }
    panic("Unknown type")
}

