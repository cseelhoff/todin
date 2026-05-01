package game

import "core:os"

Exit_Status :: enum {
	Success,
	Failure,
}

// Java: private static final Collection<Runnable> exitActions = new HashSet<>();
exit_status_exit_actions: [dynamic]proc()

// Java: private final int status;
exit_status_status :: proc(self: ^Exit_Status) -> i32 {
	switch self^ {
	case .Success:
		return 0
	case .Failure:
		return 1
	}
	return 0
}

// Java: public void exit() { exitActions.forEach(Runnable::run); System.exit(status); }
exit_status_exit :: proc(self: ^Exit_Status) {
	for action in exit_status_exit_actions {
		action()
	}
	os.exit(int(exit_status_status(self)))
}
