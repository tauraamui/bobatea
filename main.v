module main

import bobatea as tea
import lib.draw
import strings

enum SessionState as u8 {
    timer
    spinner
}

struct MainModel {
mut:
    state SessionState
}

fn new_model(mut nums []int) MainModel {
    return MainModel{
        state: .timer
    }
}

fn (mut m MainModel) init() ?tea.Cmd {
    return none // no init required for now
}

fn (mut m MainModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
    if msg is tea.KeyMsg {
        if msg.code == .escape {
            return MainModel{}, tea.quit
        }

        if msg.code == .tab {
	        m.state = if m.state == .timer { .spinner } else { .timer }
	        return m.clone(), none
        }
    }

	return m.clone(), none
}

fn (m MainModel) view(mut ctx draw.Contextable) {
    win_width := ctx.window_width()
    win_height := ctx.window_height()

	state := if m.state == .timer { "timer" } else { "spinner" }
    msg := "welcome to boba tea! ${state}"
    draw_text_in_box(mut ctx, (win_width / 2) - (msg.len / 2), win_height / 2, msg)
}

fn draw_text_in_box(mut ctx draw.Contextable, x int, y int, msg string) {
	// TODO(tauraamui) [21/10/2025]: properly handle multi width runes
	ctx.draw_text(x, y, "${tea.top_left}${strings.repeat_string(string(tea.top), msg.len)}${tea.top_right}")
	ctx.draw_text(x, y + 1, "${tea.left}${msg}${tea.right}")
	ctx.draw_text(x, y + 2, "${tea.bottom_left}${strings.repeat_string(string(tea.bottom), msg.len)}${tea.bottom_right}")
}

fn (m MainModel) clone() tea.Model {
	return MainModel{
		...m
	}
}

fn main() {
	mut numbers := [1, 10, 32, 99]
    mut entry_model := new_model(mut numbers)
    mut app := tea.new_program(mut entry_model)
    app.run() or { panic("something went wrong! ${err}") }
}
