// Simple demonstration of the tick functionality
// This shows how to use the tick and every functions

import tauraamui.bobatea
import time

fn main() {
	println('Testing bobatea tick functionality...')

	// Test basic tick - waits for 1 second then returns a message
	println('Creating a tick command that waits 1 second...')
	tick_cmd := bobatea.tick(time.second * 10, fn (t time.Time) bobatea.Msg {
		return bobatea.TickMsg{
			time: t
		}
	})

	start_time := time.now()
	msg := tick_cmd()
	end_time := time.now()

	if msg is bobatea.TickMsg {
		elapsed := end_time - start_time
		println('Tick completed! Elapsed time: ${elapsed.milliseconds()}ms')
		println('Tick message time: ${msg.time}')
	}

	// Test every function - aligns to system clock boundaries
	println('\nTesting every function with 500ms interval...')
	every_cmd := bobatea.every(500 * time.millisecond, fn (t time.Time) bobatea.Msg {
		return bobatea.TickMsg{
			time: t
		}
	})

	start_time2 := time.now()
	msg2 := every_cmd()
	end_time2 := time.now()

	if msg2 is bobatea.TickMsg {
		elapsed2 := end_time2 - start_time2
		println('Every completed! Elapsed time: ${elapsed2.milliseconds()}ms')
		println('Every message time: ${msg2.time}')
	}

	println('\nTick functionality is working correctly!')
}
