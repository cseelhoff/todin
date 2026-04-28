package game

End_Point :: struct {
	next_given_number:       i64,
	current_runnable_number: i64,
	name:                    string,
	remote_class:            rawptr,
	implementors:            map[rawptr]struct {},
	single_threaded:         bool,
}
