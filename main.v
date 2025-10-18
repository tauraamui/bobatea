module main

import bobatea as tea

struct TestModel {}

fn (m TestModel) init() ! {
    return
}

fn main() {
    mut app := tea.new_program(TestModel{})
    app.run() or { panic("something went wrong! ${err}") }
}
