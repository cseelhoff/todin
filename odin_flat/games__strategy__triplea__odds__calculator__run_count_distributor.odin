package game

Run_Count_Distributor :: struct {
	runs_per_worker: i32,
	target_leftover: i32,
	leftover_runs:   i32,
}

run_count_distributor_new :: proc(run_count: i32, parallelism: i32) -> ^Run_Count_Distributor {
	assert(parallelism > 0, "The parallelism level has to be positive!")
	self := new(Run_Count_Distributor)
	self.runs_per_worker = run_count / parallelism
	self.leftover_runs = run_count % parallelism
	self.target_leftover = self.leftover_runs - parallelism
	return self
}

run_count_distributor_next_run_count :: proc(self: ^Run_Count_Distributor) -> i32 {
	leftover := self.leftover_runs
	self.leftover_runs -= 1
	if leftover <= self.target_leftover {
		panic("nextRunCount() was called more times than specified by provided level of parallelism")
	}
	extra: i32 = 0
	if leftover > 0 {
		extra = 1
	}
	return extra + self.runs_per_worker
}
