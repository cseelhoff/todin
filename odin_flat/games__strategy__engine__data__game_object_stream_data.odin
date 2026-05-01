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

