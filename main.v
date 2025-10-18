module main

import bobatea as tea

enum SessionState as u8 {
    timer
    spinner
}

struct MainModel {
    state SessionState
}

fn (mut m MainModel) init() !tea.Cmd {
    return fn () tea.Msg { return tea.Msg(EmptyMsg{}) }
}

struct EmptyMsg {}

fn (mut m MainModel) update(msg tea.Msg) (tea.Model, tea.Cmd) {
    return m, fn () tea.Msg { return tea.Msg(EmptyMsg{}) }
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
