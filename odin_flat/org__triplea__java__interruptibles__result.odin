package game

Result :: struct($T: typeid) {
	completed:      bool,
	result_present: bool,
	result:         T,
}

// Java owners covered by this file:
//   - org.triplea.java.Interruptibles$Result

