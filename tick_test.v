module bobatea

import time

fn test_tick_functionality() {
	// Test that tick function creates a command that waits and returns a message
	tick_cmd := tick(50 * time.millisecond, fn (t time.Time) Msg {
		return TickMsg{
			time: t
		}
	})
	
	// Execute the command (this will sleep for 50ms)
	start_time := time.now()
	msg := tick_cmd()
	end_time := time.now()
	
	// Verify it's a TickMsg
	assert msg is TickMsg
	
	// Verify it took at least 50ms (allowing some tolerance for timing)
	elapsed := end_time - start_time
	assert elapsed.milliseconds() >= 45 // Allow 5ms tolerance
}

fn test_every_functionality() {
	// Test that every function creates a command
	every_cmd := every(100 * time.millisecond, fn (t time.Time) Msg {
		return TickMsg{
			time: t
		}
	})
	
	// Execute the command
	msg := every_cmd()
	
	// Verify it's a TickMsg
	assert msg is TickMsg
}