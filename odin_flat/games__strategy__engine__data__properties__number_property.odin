package game

// games.strategy.engine.data.properties.NumberProperty

Number_Property :: struct {
	using parent: Abstract_Editable_Property,
	max:          i32,
	min:          i32,
	value:        i32,
}

