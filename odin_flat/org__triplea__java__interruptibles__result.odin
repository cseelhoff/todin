package game

Interruptibles_Result :: struct($T: typeid) {
	completed:      bool,
	result_present: bool,
	result:         T,
}

// Java owners covered by this file:
//   - org.triplea.java.Interruptibles$Result

interruptibles_result_new :: proc($T: typeid, completed: bool, result_present: bool, result: T) -> ^Interruptibles_Result(T) {
	r := new(Interruptibles_Result(T))
	r.completed = completed
	r.result_present = result_present
	r.result = result
	return r
}

