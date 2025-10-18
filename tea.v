module bobatea

import term.ui as tui

pub struct App {
    render_debug bool
mut:
    t_ref         &tui.Context
    initial_model Model
}

pub interface Model {
    init() !
}

pub fn (mut a App) run() ! {
    a.initial_model.init()!
    return
}

pub fn new_program(m Model) App {
    return App{
        t_ref: tui.init(tui.Config{})
        initial_model: m
    }
}

