package game

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteName

// Description for a Channel or a Remote end point.
Remote_Name :: struct {
	name:  string,
	clazz: string, // Java Class<?> (interface) -> store class name
}

