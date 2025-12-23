module bobatea

import lib.term.ui as tui
import lib.draw
import time

@[heap]
pub struct App {
	render_debug bool
mut:
	ui             &draw.Contextable = unsafe { nil }
	t_ref          &tui.Context
	initial_model  Model
	event_invoked  bool
	update_invoked bool
	next_msg       ?Msg
	msg_queue      shared []Msg // Queue for messages from batch commands
	update_rate    int = 2000 // Update rate in Hz (2000 = 0.5ms intervals)
}

pub type Cmd = fn () Msg

// Command represents either a single command or a batch of commands
pub type Command = Cmd | BatchMsg | SequenceMsg | TickCmd

// TickCmd represents a delayed command that will be executed after a duration
pub struct TickCmd {
	duration time.Duration
	callback fn (time.Time) Msg = unsafe { nil }
}

pub interface Model {
mut:
	init() ?Cmd
	update(Msg) (Model, ?Cmd)
	view(mut Context)
	clone() Model
}

pub interface Msg {}

pub struct QuitMsg {}

pub fn quit() Msg {
	return QuitMsg{}
}

pub struct TickMsg {
pub:
	time time.Time
}

struct QuerySize {}

pub fn emit_resize() Msg {
	return QuerySize{}
}

pub type BatchMsg = []Cmd

pub type SequenceMsg = []Cmd

pub fn batch(cmds ...Cmd) Cmd {
	mut valid_cmds := []Cmd{}
	for cmd in cmds {
		if !isnil(cmd) {
			valid_cmds << cmd
		}
	}
	match valid_cmds.len {
		0 {
			return noop_cmd
		}
		1 {
			return valid_cmds[0]
		}
		else {
			return fn [valid_cmds] () Msg {
				return BatchMsg(valid_cmds)
			}
		}
	}
}

// sequence runs the given commands one at a time, in order. Contrast this with
// batch, which runs commands concurrently.
pub fn sequence(cmds ...Cmd) Cmd {
	mut valid_cmds := []Cmd{}
	for cmd in cmds {
		if !isnil(cmd) {
			valid_cmds << cmd
		}
	}
	match valid_cmds.len {
		0 {
			return noop_cmd
		}
		1 {
			return valid_cmds[0]
		}
		else {
			return fn [valid_cmds] () Msg {
				return SequenceMsg(valid_cmds)
			}
		}
	}
}

// batch_array creates a batch command from an array of commands
pub fn batch_array(cmds []Cmd) Cmd {
	mut valid_cmds := []Cmd{}
	for cmd in cmds {
		if !isnil(cmd) {
			valid_cmds << cmd
		}
	}
	match valid_cmds.len {
		0 {
			return noop_cmd
		}
		1 {
			return valid_cmds[0]
		}
		else {
			return fn [valid_cmds] () Msg {
				return BatchMsg(valid_cmds)
			}
		}
	}
}

// batch_optional creates a batch command from an array of optional commands,
// filtering out none values
// @deprecated
/*
pub fn batch_optional(cmds []?Cmd) Cmd {
	mut valid_cmds := []Cmd{}
	for cmd in cmds {
		if c := cmd {
			valid_cmds << c
		}
	}
	match valid_cmds.len {
		0 {
			return noop_cmd
		}
		1 {
			return valid_cmds[0]
		}
		else {
			return fn [valid_cmds] () Msg {
				return BatchMsg(valid_cmds)
			}
		}
	}
}
*/

pub struct NoopMsg {}

pub fn noop_cmd() Msg {
	return NoopMsg{}
}

// tick produces a command at an interval independent of the system clock at
// the given duration. That is, the timer begins precisely when invoked,
// and runs for its entire duration.
//
// To produce the command, pass a duration and a function which returns
// a message containing the time at which the tick occurred.
//
//	type TickMsg time.Time
//
//	cmd := tick(time.second, fn (t time.Time) Msg {
//		return TickMsg{time: t}
//	})
//
// Beginners' note: tick sends a single message and won't automatically
// dispatch messages at an interval. To do that, you'll want to return another
// tick command after receiving your tick message. For example:
//
//	fn do_tick() Cmd {
//		return tick(time.second, fn (t time.Time) Msg {
//			return TickMsg{time: t}
//		})
//	}
//
//	fn (m model) init() ?Cmd {
//		return do_tick()
//	}
//
//	fn (mut m model) update(msg Msg) (Model, ?Cmd) {
//		match msg {
//			TickMsg {
//				// Return your tick command again to loop.
//				return m, do_tick()
//			}
//			else {}
//		}
//		return m, none
//	}
pub fn tick(d time.Duration, f fn (time.Time) Msg) Cmd {
	return fn [d, f] () Msg {
		return TickCmd{
			duration: d
			callback: f
		}
	}
}

// every produces a command at an interval aligned to the system clock.
// That is, the timer begins at the next interval boundary.
//
// To produce the command, pass a duration and a function which returns
// a message containing the time at which the tick occurred.
//
//	type TickMsg time.Time
//
//	cmd := every(time.second, fn (t time.Time) Msg {
//		return TickMsg{time: t}
//	})
//
// Beginners' note: every sends a single message and won't automatically
// dispatch messages at an interval. To do that, you'll want to return another
// every command after receiving your tick message.
pub fn every(duration time.Duration, f fn (time.Time) Msg) Cmd {
	return fn [duration, f] () Msg {
		now := time.now()
		// Calculate time until next interval boundary
		nanos_per_duration := duration.nanoseconds()
		current_nanos := now.unix_nano()
		next_boundary := ((current_nanos / nanos_per_duration) + 1) * nanos_per_duration
		wait_duration := time.Duration(next_boundary - current_nanos)

		return TickCmd{
			duration: wait_duration
			callback: f
		}
	}
}

pub fn (mut app App) run() ! {
	mut ctx, run := draw.new_context(
		render_debug:         false
		user_data:            app
		event_fn:             event
		frame_fn:             frame
		update_fn:            update_loop // Pass our update function
		capture_events:       true
		use_alternate_buffer: true
	)
	app.ui = ctx

	cmd := app.initial_model.init() or { noop_cmd }
	models_msg := cmd()

	// Store the initial message to be processed after the TUI loop starts
	app.next_msg = models_msg

	run()!
}

fn (mut app App) quit() ! {
	exit(0)
}

pub struct ResizedMsg {
pub:
	window_width  int
	window_height int
}

pub struct FocusedMsg {}
pub struct BlurredMsg {}

pub struct ClearScreenMsg {}

pub fn clear_screen() Msg {
	return ClearScreenMsg{}
}

// NOTE(tauraamui) [22/10/2025]: this is invoked by the underlying runtime loop directly only
//                               when an actual event comes in, (keypress/resize, etc.,)
fn event(e draw.Event, mut app App) {
	msg := match e.typ {
		.key_down {
			Msg(resolve_key_msg(e))
		}
		.mouse_scroll {
			Msg(NoopMsg{})
		}
		.resized {
			Msg(ResizedMsg{
				window_width:  e.width
				window_height: e.height
			})
		}
		.focused {
			Msg(FocusedMsg{})
		}
		.unfocused {
			Msg(BlurredMsg{})
		}
		else {
			Msg(NoopMsg{})
		}
	}
	// Queue the event instead of handling immediately
	app.send(msg)
}

fn (mut app App) handle_event(msg Msg) {
	// handle special batch and sequence messages
	match msg {
		NoopMsg {
			return
		}
		ClearScreenMsg {
			app.ui.clear_prev_data()
			return
		}
		BatchMsg {
			app.exec_batch_msg(msg)
			return
		}
		SequenceMsg {
			app.exec_sequence_msg(msg)
			return
		}
		TickCmd {
			app.exec_tick_cmd(msg)
			return
		}
		QuitMsg {
			app.quit() or { panic(err) }
			return
		}
		QuerySize {
			app.next_msg = Msg(ResizedMsg{
				window_width:  app.ui.window_width()
				window_height: app.ui.window_height()
			})
			return
		}
		else {}
	}

	m, cmd := app.initial_model.update(msg)
	app.initial_model = m
	u_cmd := cmd or { noop_cmd }
	models_msg := u_cmd()
	if models_msg is QuitMsg {
		app.quit() or { panic(err) }
		return
	}

	// Handle the returned message immediately instead of deferring
	match models_msg {
		NoopMsg {
			// Do nothing
		}
		BatchMsg {
			app.exec_batch_msg(models_msg)
		}
		ClearScreenMsg {
			app.ui.clear_prev_data()
			return
		}

		SequenceMsg {
			app.exec_sequence_msg(models_msg)
		}
		TickCmd {
			app.exec_tick_cmd(models_msg)
		}
		QuerySize {
			app.next_msg = Msg(ResizedMsg{
				window_width:  app.ui.window_width()
				window_height: app.ui.window_height()
			})
		}
		else {
			// For other messages, queue them for next frame
			app.next_msg = models_msg
		}
	}
}

// exec_tick_cmd executes a tick command asynchronously
fn (mut app App) exec_tick_cmd(tick_cmd TickCmd) {
	go fn [mut app, tick_cmd] () {
		time.sleep(tick_cmd.duration)
		msg := tick_cmd.callback(time.now())
		app.send(msg)
	}()
}

// exec_batch_msg executes commands concurrently using go
fn (mut app App) exec_batch_msg(batch_msg BatchMsg) {
	for cmd in batch_msg {
		if isnil(cmd) {
			continue
		}
		go app.exec_cmd_async(cmd)
	}
}

// exec_sequence_msg executes commands one at a time in order
fn (mut app App) exec_sequence_msg(seq_msg SequenceMsg) {
	for cmd in seq_msg {
		if isnil(cmd) {
			continue
		}
		msg := cmd()
		match msg {
			BatchMsg {
				app.exec_batch_msg(msg)
			}
			SequenceMsg {
				app.exec_sequence_msg(msg)
			}
			TickCmd {
				app.exec_tick_cmd(msg)
			}
			QuitMsg {
				app.quit() or { panic(err) }
				return
			}
			QuerySize {
				app.send(ResizedMsg{
					window_width:  app.ui.window_width()
					window_height: app.ui.window_height()
				})
			}
			else {
				app.send(msg)
			}
		}
	}
}

// exec_cmd_async executes a single command asynchronously and sends result to queue
fn (mut app App) exec_cmd_async(cmd Cmd) {
	msg := cmd()
	match msg {
		BatchMsg {
			app.exec_batch_msg(msg)
		}
		SequenceMsg {
			app.exec_sequence_msg(msg)
		}
		TickCmd {
			app.exec_tick_cmd(msg)
		}
		QuitMsg {
			app.quit() or { panic(err) }
		}
		QuerySize {
			app.send(ResizedMsg{
				window_width:  app.ui.window_width()
				window_height: app.ui.window_height()
			})
		}
		else {
			app.send(msg)
		}
	}
}

// send adds a message to the queue for processing
fn (mut app App) send(msg Msg) {
	lock app.msg_queue {
		app.msg_queue << msg
	}
}

// process_queued_messages processes all messages in the queue
fn (mut app App) process_queued_messages() {
	for {
		mut msg_to_process := ?Msg(none)
		lock app.msg_queue {
			if app.msg_queue.len > 0 {
				msg_to_process = app.msg_queue[0]
				if app.msg_queue.len == 1 {
					app.msg_queue.clear()
				} else {
					app.msg_queue = app.msg_queue[1..]
				}
			}
		}

		if msg := msg_to_process {
			app.handle_event(msg)
		} else {
			break
		}
	}
}

// Update loop - runs at high frequency for model updates
fn update_loop(mut app App) {
	// Process all queued messages (from input events and batch commands)
	app.process_queued_messages()

	// Also process next_msg if present (from previous frame's commands)
	msg := app.next_msg or { Msg(NoopMsg{}) }
	if app.next_msg != none {
		app.next_msg = none
		app.handle_event(msg)
	}
}

// NOTE(tauraamui) [22/10/2025]: this function is called on each iteration of runtime loop directly
//                               we now only handle rendering here, update logic moved to update_loop
fn frame(mut app App) {
	app.ui.clear()
	app.ui.hide_cursor() // make it default, should think harder about this
	// when it comes time to implement dynamic input fields etc.,
	app.initial_model.view(mut app.ui)
	app.ui.reset()
	app.ui.flush()
}

pub fn new_program(mut m Model) App {
	return App{
		t_ref:         tui.init(tui.Config{})
		initial_model: m
	}
}
