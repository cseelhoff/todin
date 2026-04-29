package game

// JDK shim: java.util.concurrent.TimeUnit. Only the constants the
// TripleA codebase uses are listed; conversion procs are not
// implemented here because the synchronous CountDownLatch /
// Executor shims do not actually wait.

Time_Unit :: enum {
	NANOSECONDS,
	MICROSECONDS,
	MILLISECONDS,
	SECONDS,
	MINUTES,
	HOURS,
	DAYS,
}
