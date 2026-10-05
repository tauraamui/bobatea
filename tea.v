module bobatea

import time

@[heap]
pub struct App {
	render_debug bool
mut:
	ui             &Context = unsafe { nil }
	initial_model  Model
	event_invoked  bool
	update_invoked bool
	next_msg       ?Msg
	msg_queue      shared []Msg // Queue for messages from batch commands
	update_rate    int = 60 // Update rate in Hz (2000 = 0.5ms intervals)

	last_activity_mono u64
	is_idle            bool
	needs_render       bool = true
	on_quit            ?fn ()

	// pending_cmd holds the model's init command until the loop starts.
	pending_cmd ?Cmd
}

// Cmd is what a model asks the runtime to do once its update has returned.
//
// It is a sum type rather than a function because the overwhelmingly common
// command is "deliver this message", and expressing that as a function forces
// a closure to carry the message. V registers every closure's captured context
// in a process-wide table that nothing empties for an ordinary closure, so the
// context - and everything it transitively reaches - is pinned for the life of
// the process. A command built per keystroke is therefore an unbounded leak.
//
// As a sum type, "deliver this message" is MsgCmd: a plain value that the GC
// can reclaim. Batching, sequencing and ticking are variants too, so the whole
// command layer allocates no closures. CmdFn remains for the genuine case of
// work that must run before its message exists.
pub type Cmd = BatchCmd | CmdFn | EveryCmd | MsgCmd | NoCmd | SequenceCmd | TickCmd

// CmdFn computes a message when the runtime dispatches it.
//
// This is the escape hatch, for work that has to happen before the message
// exists. Prefer msg_cmd when the message is already in hand: a plain function
// is free, but a closure over captured state is pinned forever. A non-capturing
// function assigned here costs nothing.
//
// Build one with cmd_fn, and never hand a bare function to something that
// takes a Cmd. V miscompiles that implicit coercion in an argument position:
// the Cmd it produces carries no variant tag, so every match on it falls
// through every arm and the command is silently dropped - no error, no crash,
// the work simply never happens. Coercion in return position is handled
// correctly, but cmd_fn is the one spelling that is always right.
pub type CmdFn = fn () Msg

// cmd_fn wraps a function as a command, for work that has to run before its
// message exists.
//
// Always go through this rather than passing a bare function where a Cmd is
// expected - see the note on CmdFn for what the implicit coercion does.
pub fn cmd_fn(f fn () Msg) Cmd {
	return CmdFn(f)
}

// call_cmd_fn runs a command function.
//
// It takes CmdFn as a parameter rather than calling the value in place, because
// a sum-type match arm does not reliably give back something callable.
fn call_cmd_fn(f CmdFn) Msg {
	return f()
}

// NoCmd asks the runtime for nothing. Use the `no_cmd` constant.
pub struct NoCmd {}

// MsgCmd delivers a message that has already been built.
pub struct MsgCmd {
pub:
	msg Msg
}

// BatchCmd runs its commands concurrently, in no guaranteed order.
pub struct BatchCmd {
pub:
	cmds []Cmd
}

// SequenceCmd runs its commands one at a time, in order, each completing
// before the next begins.
pub struct SequenceCmd {
pub:
	cmds []Cmd
}

// TickCmd delivers callback(time.now()) once duration has elapsed, timed from
// the moment the runtime dispatches it.
pub struct TickCmd {
pub:
	duration time.Duration
	callback fn (time.Time) Msg = unsafe { nil }
}

// EveryCmd is TickCmd aligned to the system clock: it waits only until the
// next duration boundary, so a one-second EveryCmd fires on the second.
pub struct EveryCmd {
pub:
	duration time.Duration
	callback fn (time.Time) Msg = unsafe { nil }
}

pub interface Model {
mut:
	init() Cmd
	update(Msg) (Model, Cmd)
	view(mut Context)
	clone() Model
}

pub interface Msg {}

pub struct QuitMsg {}

// quit ends the program.
pub fn quit() Cmd {
	return msg_cmd(QuitMsg{})
}

pub struct TickMsg {
pub:
	time time.Time
}

struct QuerySize {}

// emit_resize asks the runtime to re-report the window size, so a model that
// has just changed its layout can lay out against the real dimensions.
pub fn emit_resize() Cmd {
	return msg_cmd(QuerySize{})
}

// no_cmd is the command that does nothing. Returning it from update is how a
// model says it needs no follow-up work.
pub const no_cmd = Cmd(NoCmd{})

// msg_cmd builds a command that delivers an already-constructed message.
//
// This replaces the closure-returning constructor that command helpers used to
// be written as. Instead of
//
//	fn open_file(path string) Cmd {
//		return fn [path] () Msg { return OpenFileMsg{path} }   // leaks `path`
//	}
//
// write
//
//	fn open_file(path string) Cmd {
//		return msg_cmd(OpenFileMsg{path})                      // allocates nothing pinned
//	}
pub fn msg_cmd(m Msg) Cmd {
	return MsgCmd{
		msg: m
	}
}

// delivered_msgs walks a command and returns every message it would deliver,
// in the order a sequence would deliver them.
//
// Batches are walked in order too, though at runtime they are concurrent and
// so have no order. TickCmd and EveryCmd are returned as themselves, since
// their message does not exist until their delay has run; nothing here sleeps.
// Any CmdFn is called, so this is for commands whose functions are pure -
// which is what tests inspecting a model's commands usually want.
pub fn (c Cmd) delivered_msgs() []Msg {
	mut out := []Msg{}
	c.collect_delivered_msgs(mut out, 0)
	return out
}

// first_delivered_msg returns the first message a command would deliver.
pub fn (c Cmd) first_delivered_msg() ?Msg {
	msgs := c.delivered_msgs()
	if msgs.len == 0 {
		return none
	}
	return msgs[0]
}

// max_cmd_depth bounds the walk, so a command that somehow contains itself
// cannot recurse forever.
const max_cmd_depth = 32

fn (c Cmd) collect_delivered_msgs(mut out []Msg, depth int) {
	if depth > max_cmd_depth {
		return
	}
	match c {
		NoCmd {}
		MsgCmd {
			out << c.msg
		}
		CmdFn {
			if !isnil(c) {
				out << call_cmd_fn(c)
			}
		}
		BatchCmd {
			for inner in c.cmds {
				inner.collect_delivered_msgs(mut out, depth + 1)
			}
		}
		SequenceCmd {
			for inner in c.cmds {
				inner.collect_delivered_msgs(mut out, depth + 1)
			}
		}
		TickCmd {
			out << c
		}
		EveryCmd {
			out << c
		}
	}
}

// collect_cmds drops the commands that would be no-ops, so batch and sequence
// do not spin up work for them.
fn collect_cmds(cmds []Cmd) []Cmd {
	mut out := []Cmd{cap: cmds.len}
	for cmd in cmds {
		if cmd is NoCmd {
			continue
		}
		if cmd is CmdFn {
			if isnil(cmd) {
				continue
			}
		}
		out << cmd
	}
	return out
}

// CmdGroup says how a group of commands is to be run.
pub enum CmdGroup {
	batch
	sequence
}

// group_cmds builds the command that runs cmds as a batch or as a sequence.
//
// batch, sequence and their array forms all come through here rather than each
// building its own variant. Two public functions whose bodies were the same
// but for a tail call to a different builder were miscompiled by the v3
// backend: `sequence` returned a BatchCmd, because the call in
// `return sequence_array(cmds)` resolved to batch_array. Routing every form
// through one helper, with the variant chosen by a value, leaves nothing for
// that to collapse. See the group_cmds tests in tea_test.v.
fn group_cmds(group CmdGroup, cmds []Cmd) Cmd {
	valid := collect_cmds(cmds)
	if valid.len == 0 {
		return no_cmd
	}
	if valid.len == 1 {
		return valid[0]
	}
	if group == .sequence {
		return SequenceCmd{
			cmds: valid
		}
	}
	return BatchCmd{
		cmds: valid
	}
}

// batch runs the given commands concurrently, in no guaranteed order. Contrast
// this with sequence, which runs them one at a time, in order.
pub fn batch(cmds ...Cmd) Cmd {
	return group_cmds(.batch, cmds)
}

// batch_array is batch, taking the commands as an array.
pub fn batch_array(cmds []Cmd) Cmd {
	return group_cmds(.batch, cmds)
}

// sequence runs the given commands one at a time, in order, each completing
// before the next begins. Contrast this with batch, which runs them
// concurrently.
pub fn sequence(cmds ...Cmd) Cmd {
	return group_cmds(.sequence, cmds)
}

// sequence_array is sequence, taking the commands as an array.
pub fn sequence_array(cmds []Cmd) Cmd {
	return group_cmds(.sequence, cmds)
}

pub struct NoopMsg {}

// noop_cmd is a command function that delivers NoopMsg.
//
// Prefer the `no_cmd` constant, which asks the runtime for nothing at all
// rather than round-tripping a message that it then ignores. This remains for
// a caller that needs a CmdFn-shaped no-op.
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
	return TickCmd{
		duration: d
		callback: f
	}
}

// tick_msg builds a tick as a bare message, for a CmdFn that re-arms a tick on
// every message it delivers.
//
// This predates Cmd becoming a sum type, when `tick` had to capture its
// arguments in a closure and so pinned them for the life of the process.
// `tick` no longer captures anything, so prefer it; this is kept because a
// CmdFn must return a Msg and so cannot return a Cmd.
pub fn tick_msg(d time.Duration, f fn (time.Time) Msg) Msg {
	return TickCmd{
		duration: d
		callback: f
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
	return EveryCmd{
		duration: duration
		callback: f
	}
}

pub fn (mut app App) run() ! {
	mut ctx, run := new_context(
		render_debug:         false
		user_data:            app
		event_fn:             event
		frame_fn:             frame
		update_fn:            update_loop // Pass our update function
		capture_events:       true
		use_alternate_buffer: true
	)
	$if windows {
		switch_codepage_to_65001()
	}
	app.ui = ctx

	// The initial command is held until the TUI loop is running, so that
	// anything it delivers is handled by the same path as every later command.
	app.pending_cmd = app.initial_model.init()

	run()!
}

fn (mut app App) quit() ! {
	if cleanup := app.on_quit {
		cleanup()
	}
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

// clear_screen discards the renderer's record of what is on screen, so the
// next frame is drawn from scratch.
pub fn clear_screen() Cmd {
	return msg_cmd(ClearScreenMsg{})
}

// NOTE(tauraamui) [22/10/2025]: this is invoked by the underlying runtime loop directly only
//                               when an actual event comes in, (keypress/resize, etc.,)
fn event(e Event, mut app App) {
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
	// The runtime interprets its own control messages rather than passing them
	// to the model.
	match msg {
		NoopMsg {
			return
		}
		ClearScreenMsg {
			app.ui.clear_prev_data()
			return
		}
		TickCmd {
			app.exec_tick_cmd(msg)
			return
		}
		EveryCmd {
			app.exec_every_cmd(msg)
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
	app.needs_render = true
	app.exec_cmd(cmd)
}

// exec_cmd carries out a command on the update thread.
//
// Anything it delivers synchronously goes through next_msg, so it is handled on
// the next turn of the update loop rather than recursing into the model here.
fn (mut app App) exec_cmd(cmd Cmd) {
	match cmd {
		NoCmd {}
		MsgCmd {
			app.deliver(cmd.msg)
		}
		CmdFn {
			if !isnil(cmd) {
				app.deliver(call_cmd_fn(cmd))
			}
		}
		BatchCmd {
			app.exec_batch_cmd(cmd)
		}
		SequenceCmd {
			app.exec_sequence_cmd(cmd)
		}
		TickCmd {
			app.exec_tick_cmd(cmd)
		}
		EveryCmd {
			app.exec_every_cmd(cmd)
		}
	}
}

// deliver routes a message produced by a command on the update thread.
//
// Control messages are acted on at once; everything else is held in next_msg
// for the next turn of the loop, which is what keeps a command from reentering
// the model mid-update.
fn (mut app App) deliver(msg Msg) {
	match msg {
		NoopMsg {}
		ClearScreenMsg {
			app.ui.clear_prev_data()
		}
		QuitMsg {
			app.quit() or { panic(err) }
		}
		TickCmd {
			app.exec_tick_cmd(msg)
		}
		EveryCmd {
			app.exec_every_cmd(msg)
		}
		QuerySize {
			app.next_msg = Msg(ResizedMsg{
				window_width:  app.ui.window_width()
				window_height: app.ui.window_height()
			})
		}
		else {
			app.next_msg = msg
		}
	}
}

// exec_tick_cmd waits out a tick off the update thread.
fn (mut app App) exec_tick_cmd(tick_cmd TickCmd) {
	if isnil(tick_cmd.callback) {
		return
	}
	// spawned as a method rather than as a captured closure: the closure would
	// be registered in V's process-wide closure table and never released, so a
	// repeating tick would leak its context once per tick.
	spawn app.run_tick_cmd(tick_cmd)
}

// run_tick_cmd waits out a tick's duration and delivers its message.
fn (mut app App) run_tick_cmd(tick_cmd TickCmd) {
	time.sleep(tick_cmd.duration)
	msg := tick_cmd.callback(time.now())
	app.send(msg)
}

// exec_every_cmd waits out a clock-aligned tick off the update thread.
fn (mut app App) exec_every_cmd(every_cmd EveryCmd) {
	if isnil(every_cmd.callback) {
		return
	}
	spawn app.run_every_cmd(every_cmd)
}

// run_every_cmd waits until the next duration boundary and delivers its
// message. The boundary is computed here, at dispatch, so the alignment is
// taken from when the command runs rather than from when it was built.
fn (mut app App) run_every_cmd(every_cmd EveryCmd) {
	nanos_per_duration := every_cmd.duration.nanoseconds()
	if nanos_per_duration <= 0 {
		app.send(every_cmd.callback(time.now()))
		return
	}
	current_nanos := time.now().unix_nano()
	next_boundary := ((current_nanos / nanos_per_duration) + 1) * nanos_per_duration
	time.sleep(time.Duration(next_boundary - current_nanos))
	app.send(every_cmd.callback(time.now()))
}

// exec_batch_cmd runs a batch's commands concurrently.
fn (mut app App) exec_batch_cmd(batch_cmd BatchCmd) {
	for cmd in batch_cmd.cmds {
		go app.exec_cmd_async(cmd)
	}
}

// exec_sequence_cmd dispatches a sequence's commands in order, on the calling
// thread.
//
// This orders dispatch rather than completion: a tick inside a sequence is
// still handed to its own thread, so a sequence can never block the update
// loop for the length of a delay. What a sequence guarantees is the order in
// which its commands are started and the order in which the messages they
// carry are queued.
fn (mut app App) exec_sequence_cmd(sequence_cmd SequenceCmd) {
	for cmd in sequence_cmd.cmds {
		match cmd {
			NoCmd {}
			MsgCmd {
				app.send_resolved(cmd.msg)
			}
			CmdFn {
				if !isnil(cmd) {
					app.send_resolved(call_cmd_fn(cmd))
				}
			}
			BatchCmd {
				app.exec_batch_cmd(cmd)
			}
			SequenceCmd {
				app.exec_sequence_cmd(cmd)
			}
			TickCmd {
				app.exec_tick_cmd(cmd)
			}
			EveryCmd {
				app.exec_every_cmd(cmd)
			}
		}
	}
}

// exec_cmd_async carries out a command off the update thread, queueing whatever
// it delivers.
fn (mut app App) exec_cmd_async(cmd Cmd) {
	match cmd {
		NoCmd {}
		MsgCmd {
			app.send_resolved(cmd.msg)
		}
		CmdFn {
			if !isnil(cmd) {
				app.send_resolved(call_cmd_fn(cmd))
			}
		}
		BatchCmd {
			app.exec_batch_cmd(cmd)
		}
		SequenceCmd {
			app.exec_sequence_cmd(cmd)
		}
		TickCmd {
			app.exec_tick_cmd(cmd)
		}
		EveryCmd {
			app.exec_every_cmd(cmd)
		}
	}
}

// send_resolved queues a message produced by a command running off the update
// thread, answering the control messages that must not reach the model.
//
// It queues rather than going through next_msg, because next_msg holds a single
// message: routing a command's result through it would drop whatever was
// already waiting there.
fn (mut app App) send_resolved(msg Msg) {
	match msg {
		NoopMsg {}
		TickCmd {
			app.exec_tick_cmd(msg)
		}
		EveryCmd {
			app.exec_every_cmd(msg)
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
pub fn (mut app App) send(msg Msg) {
	lock app.msg_queue {
		app.msg_queue << msg
	}
}

// process_queued_messages processes all messages in the queue
fn (mut app App) process_queued_messages() {
	for {
		mut msg_to_process := Msg(NoopMsg{})
		mut has_msg := false
		lock app.msg_queue {
			if app.msg_queue.len > 0 {
				msg_to_process = app.msg_queue[0]
				has_msg = true
				if app.msg_queue.len == 1 {
					app.msg_queue.clear()
				} else {
					app.msg_queue = app.msg_queue[1..]
				}
			}
		}

		if has_msg {
			app.handle_event(msg_to_process)
		} else {
			break
		}
	}
}

// Update loop - runs at high frequency for model updates
fn update_loop(mut app App) {
	mut had_activity := false

	// Check if there are any messages to process
	lock app.msg_queue {
		if app.msg_queue.len > 0 {
			had_activity = true
		}
	}

	// Check if there's a next_msg pending
	if app.next_msg != none {
		had_activity = true
	}

	// The model's init command runs on the first turn of the loop.
	if app.pending_cmd != none {
		had_activity = true
	}

	// Update last activity time if there was activity
	if had_activity {
		app.last_activity_mono = time.sys_mono_now()
		app.is_idle = false
	}

	// Carry out the init command before anything else, so the model's opening
	// state is in place before the first queued event is handled.
	if cmd := app.pending_cmd {
		app.pending_cmd = none
		app.exec_cmd(cmd)
	}

	// Process all queued messages
	app.process_queued_messages()

	// Process next_msg if present
	if msg := app.next_msg {
		app.next_msg = none
		app.handle_event(msg)
	}

	time_since_last_activity := time.Duration(i64(time.sys_mono_now() - app.last_activity_mono))

	if time_since_last_activity > 100 * time.millisecond {
		// We've been idle for more than 100ms
		if !app.is_idle {
			app.is_idle = true
			// Optional: log that we entered idle mode
			// eprintln('Entering idle mode')
		}

		// Sleep longer when idle (10ms instead of 1ms)
		// This reduces CPU usage from 1-2% to ~0.1%
		time.sleep(10 * time.millisecond)
	} else {
		// We're active, use normal sleep
		app.is_idle = false
		time.sleep(time.millisecond)
	}
}

// NOTE(tauraamui) [22/10/2025]: this function is called on each iteration of runtime loop directly
//                               we now only handle rendering here, update logic moved to update_loop
fn frame(mut app App) {
	if !app.needs_render {
		return
	}
	app.needs_render = false
	app.ui.clear()
	app.ui.hide_cursor() // make it default, should think harder about this
	// when it comes time to implement dynamic input fields etc.,
	app.initial_model.view(mut app.ui)
	app.ui.reset()
	app.ui.flush()
}

@[params]
pub struct ProgramOpts {
pub:
	on_quit ?fn ()
}

pub fn new_program(mut m Model, opts ProgramOpts) App {
	return App{
		initial_model: m
		on_quit:       opts.on_quit
	}
}

// no_cmds returns an empty command list, for a caller accumulating commands
// before handing them to batch_array or sequence_array.
pub fn no_cmds() []Cmd {
	return []Cmd{}
}
