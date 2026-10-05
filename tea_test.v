module bobatea

import time

struct TestModel {}

fn (mut m TestModel) init() Cmd {
	return no_cmd
}

fn (mut m TestModel) update(msg Msg) (Model, Cmd) {
	return TestModel{}, no_cmd
}

fn (mut m TestModel) view(mut ctx Context) {}

fn (mut m TestModel) clone() Model {
	return TestModel{}
}

fn test_new_program_without_callback() {
	mut m := TestModel{}
	app := new_program(mut m)
	assert app.on_quit == none
}

fn test_new_program_with_callback() {
	mut m := TestModel{}
	ch := chan bool{cap: 1}
	app := new_program(mut m,
		on_quit: fn [ch] () {
			ch <- true
		}
	)
	assert app.on_quit != none

	if cb := app.on_quit {
		cb()
	}
	assert <-ch == true
}

struct ProbeMsg {
	n int
}

fn test_no_cmd_is_the_nocmd_variant() {
	assert no_cmd is NoCmd
}

fn test_msg_cmd_carries_its_message_without_a_closure() {
	cmd := msg_cmd(ProbeMsg{7})
	assert cmd is MsgCmd
	if cmd is MsgCmd {
		inner := cmd.msg
		assert inner is ProbeMsg
		if inner is ProbeMsg {
			assert inner.n == 7
		}
	}
}

fn test_batch_collapses_empty_and_single() {
	assert batch() is NoCmd
	assert batch(no_cmd, no_cmd) is NoCmd
	single := batch(no_cmd, msg_cmd(ProbeMsg{1}))
	assert single is MsgCmd
	pair := batch(msg_cmd(ProbeMsg{1}), msg_cmd(ProbeMsg{2}))
	assert pair is BatchCmd
	if pair is BatchCmd {
		assert pair.cmds.len == 2
	}
}

fn test_sequence_collapses_empty_and_single() {
	assert sequence() is NoCmd
	assert sequence(no_cmd) is NoCmd
	pair := sequence(msg_cmd(ProbeMsg{1}), msg_cmd(ProbeMsg{2}))
	assert pair is SequenceCmd
	if pair is SequenceCmd {
		assert pair.cmds.len == 2
	}
}

fn test_batch_drops_nil_cmd_fns() {
	nil_fn := CmdFn(unsafe { nil })
	assert batch(nil_fn, nil_fn) is NoCmd
	one := batch(nil_fn, msg_cmd(ProbeMsg{3}))
	assert one is MsgCmd
}

fn test_a_plain_function_is_a_cmd_without_capturing() {
	cmd := Cmd(CmdFn(noop_cmd))
	assert cmd is CmdFn
	if cmd is CmdFn {
		f := cmd
		assert f() is NoopMsg
	}
}

fn test_tick_and_every_build_values_not_closures() {
	t := tick(5, probe_tick_fired)
	assert t is TickCmd
	if t is TickCmd {
		assert t.duration == 5
	}
	e := every(5, probe_tick_fired)
	assert e is EveryCmd
	if e is EveryCmd {
		assert e.duration == 5
	}
}

fn probe_tick_fired(t time.Time) Msg {
	return ProbeMsg{1}
}

fn test_nested_batches_and_sequences_compose() {
	inner := sequence(msg_cmd(ProbeMsg{1}), msg_cmd(ProbeMsg{2}))
	outer := batch(inner, msg_cmd(ProbeMsg{3}))
	assert outer is BatchCmd
	if outer is BatchCmd {
		assert outer.cmds.len == 2
		assert outer.cmds[0] is SequenceCmd
	}
}

// batch and sequence must return their own variant.
//
// These pin a v3 backend miscompile: when batch and sequence were each a
// one-line tail call to a separate builder, `sequence` returned a BatchCmd,
// because `return sequence_array(cmds)` resolved to batch_array. Every form
// now routes through group_cmds. A regression here silently turns every
// sequenced command in a consumer into a concurrent batch, which reorders
// work that was explicitly ordered.
fn test_sequence_does_not_return_a_batch() {
	a := msg_cmd(ProbeMsg{1})
	b := msg_cmd(ProbeMsg{2})

	assert sequence(a, b) is SequenceCmd
	assert sequence_array([a, b]) is SequenceCmd
	assert batch(a, b) is BatchCmd
	assert batch_array([a, b]) is BatchCmd

	// and the variants must not be confused with each other
	assert sequence(a, b) !is BatchCmd
	assert batch(a, b) !is SequenceCmd
}

fn test_group_cmds_chooses_by_group() {
	a := msg_cmd(ProbeMsg{1})
	b := msg_cmd(ProbeMsg{2})
	assert group_cmds(.sequence, [a, b]) is SequenceCmd
	assert group_cmds(.batch, [a, b]) is BatchCmd
	assert group_cmds(.sequence, []) is NoCmd
	assert group_cmds(.batch, [a]) is MsgCmd
}

// cmd_fn must produce a properly tagged CmdFn.
//
// Handing a bare function to something that takes a Cmd is miscompiled in
// argument position: the Cmd carries no variant tag, so a match on it falls
// through every arm and the command is dropped in silence. cmd_fn does the
// cast in return position, which is handled correctly. If this ever fails,
// every CmdFn-shaped command in a consumer is being discarded.
// selected_arm reports which match arm a Cmd selects, or '' when it falls
// through every one - which is what an untagged Cmd does.
fn selected_arm(c Cmd) string {
	match c {
		NoCmd { return 'NoCmd' }
		MsgCmd { return 'MsgCmd' }
		CmdFn { return 'CmdFn' }
		BatchCmd { return 'BatchCmd' }
		SequenceCmd { return 'SequenceCmd' }
		TickCmd { return 'TickCmd' }
		EveryCmd { return 'EveryCmd' }
	}
	return ''
}

fn test_cmd_fn_is_tagged_and_callable() {
	cmd := cmd_fn(noop_cmd)
	assert selected_arm(cmd) == 'CmdFn', 'a match fell through every arm: the Cmd has no variant tag'
	assert cmd.delivered_msgs().len == 1
	assert cmd.delivered_msgs()[0] is NoopMsg
}

// A cmd_fn must survive being collected into a batch, which is where the
// implicit coercion used to lose it.
fn test_cmd_fn_survives_a_batch() {
	grouped := batch(cmd_fn(noop_cmd), msg_cmd(ProbeMsg{1}))
	assert selected_arm(grouped) == 'BatchCmd'
	if grouped is BatchCmd {
		assert grouped.cmds.len == 2
		assert selected_arm(grouped.cmds[0]) == 'CmdFn'
	}
	assert grouped.delivered_msgs().len == 2
}

// Every variant must select its own arm. This is the general form of the
// untagged-Cmd failure.
fn test_every_variant_selects_its_own_arm() {
	assert selected_arm(no_cmd) == 'NoCmd'
	assert selected_arm(msg_cmd(ProbeMsg{1})) == 'MsgCmd'
	assert selected_arm(cmd_fn(noop_cmd)) == 'CmdFn'
	assert selected_arm(batch(msg_cmd(ProbeMsg{1}), msg_cmd(ProbeMsg{2}))) == 'BatchCmd'
	assert selected_arm(sequence(msg_cmd(ProbeMsg{1}), msg_cmd(ProbeMsg{2}))) == 'SequenceCmd'
	assert selected_arm(tick(5, probe_tick_fired)) == 'TickCmd'
	assert selected_arm(every(5, probe_tick_fired)) == 'EveryCmd'
}
