module bobatea

import term.ui as tui
import lib.draw

pub struct App {
	render_debug bool
mut:
	ui            &Context = unsafe { nil }
	t_ref         &tui.Context
	initial_model Model
	event_invoked bool
	next_msg      ?Msg
	msg_queue     shared []Msg // Queue for messages from batch commands
}

pub type Cmd = fn () Msg

// Command represents either a single command or a batch of commands
pub type Command = Cmd | BatchMsg | SequenceMsg

pub interface Model {
mut:
	init() ?Cmd
	update(Msg) (Model, ?Cmd)
	view(mut Context)
	clone() Model
}

pub interface Msg {}

pub struct KeyMsg {
pub:
	code tui.KeyCode
}

pub struct QuitMsg {}

pub fn quit() Msg {
	return QuitMsg{}
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

struct NoopMsg {}

pub fn noop_cmd() Msg {
	return NoopMsg{}
}

pub fn (mut app App) run() ! {
	cmd := app.initial_model.init() or { noop_cmd }
	models_msg := cmd()

	// Handle initial command message
	match models_msg {
		QuitMsg {
			app.quit() or { panic(err) }
		}
		BatchMsg {
			app.exec_batch_msg(models_msg)
		}
		SequenceMsg {
			app.exec_sequence_msg(models_msg)
		}
		else {
			app.next_msg = models_msg
		}
	}

	ctx, run := draw.new_context(
		render_debug:         false
		user_data:            app
		event_fn:             event
		frame_fn:             frame
		capture_events:       true
		use_alternate_buffer: true
	)
	app.ui = ctx

	run()!
}

fn (mut app App) quit() ! {
	exit(0)
}

// NOTE(tauraamui) [22/10/2025]: this is invoked by the underlying runtime loop directly only
//                               when an actual event comes in, (keypress/resize, etc.,)
fn event(e draw.Event, mut app App) {
	defer { app.event_invoked = true }
	msg := match e.typ {
		.key_down {
			Msg(KeyMsg{
				code: e.code
			})
		}
		.mouse_scroll {
			Msg(NoopMsg{})
		}
		.resized {
			Msg(NoopMsg{})
		}
		else {
			Msg(NoopMsg{})
		}
	}
	app.handle_event(msg)
}

fn (mut app App) handle_event(msg Msg) {
	// Handle special batch and sequence messages
	match msg {
		BatchMsg {
			app.exec_batch_msg(msg)
			return
		}
		SequenceMsg {
			app.exec_sequence_msg(msg)
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
	}
	app.next_msg = models_msg
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
				app.msg_queue.delete(0)
			}
		}

		if msg := msg_to_process {
			app.handle_event(msg)
		} else {
			break
		}
	}
}

// NOTE(tauraamui) [22/10/2025]: this function is called on each iteration of runtime loop directly
//                               we invoke the update loop of initial model here if an actual event
//                               didn't fire, so that the initial model can still update logic per iter
fn frame(mut app App) {
	defer {
		app.event_invoked = false
	}

	// Process any queued messages from batch commands first
	app.process_queued_messages()

	// NOTE(tauraamui) [21/10/2025]: basically, if the stdlib event loop hasn't invoked update
	//                               due to a lack of an actual event, call it from frame anyway
	if app.event_invoked == false {
		msg := app.next_msg or { Msg(NoopMsg{}) }
		if app.next_msg != none {
			app.next_msg = none
		}
		app.handle_event(msg)
	}
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
