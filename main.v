module main

import bobatea as tea
import lib.draw

enum SessionState as u8 {
    timer
    spinner
}

struct MainModel {
    state SessionState
}

fn (mut m MainModel) init() ?tea.Cmd {
    return none // no init required for now
}

fn (mut m MainModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
    // NOTE(tauraamui): have to create manual non-mutable copy of the final
    // returned model instance in order to not encounter catastrophic C level
    // compiler panic
    i_m := m
    return i_m, none
}

fn (mut m MainModel) view(mut ctx draw.Contextable) {
    win_width := ctx.window_width()
    win_height := ctx.window_height()

    msg := "welcome to boba tea!"
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
