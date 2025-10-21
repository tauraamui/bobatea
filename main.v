module main

import bobatea as tea
import lib.draw

enum SessionState as u8 {
    timer
    spinner
}

struct MainModel {
mut:
    state SessionState
	event_count int
}

fn (mut m MainModel) init() ?tea.Cmd {
    return none // no init required for now
}

fn (mut m MainModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
    // NOTE(tauraamui): have to create manual non-mutable copy of the final
    // returned model instance in order to not encounter catastrophic C level
    // compiler panic
	m.event_count += 1

    if msg is tea.KeyMsg {
        if msg.code == .escape {
            return MainModel{}, tea.quit
        }

        if msg.code == .tab {
	        m.state = if m.state == .timer { .spinner } else { .timer }
			return MainModel{
				state: m.state
				event_count: m.event_count
			}, none
        }

		if msg.code == .a {
			m.event_count = 0
			return MainModel{
				state: m.state
				event_count: m.event_count
			}, none
		}
    }

    i_m := m
    return i_m, none
}

fn (mut m MainModel) view(mut ctx draw.Contextable) {
    win_width := ctx.window_width()
    win_height := ctx.window_height()

	state := if m.state == .timer { "timer" } else { "spinner" }
    msg := "welcome to boba tea! ${state} -> ${m.event_count}"
    ctx.draw_text((win_width / 2) - (msg.len / 2), win_height / 2, msg)
}

fn new_model() MainModel {
    return MainModel{
        state: .timer
    }
}

fn main() {
    mut entry_model := new_model()
    mut app := tea.new_program(mut entry_model)
    app.run() or { panic("something went wrong! ${err}") }
}
