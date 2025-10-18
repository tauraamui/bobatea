module bobatea

import term.ui as tui

pub struct App {
    render_debug bool
mut:
    t_ref         &tui.Context
    initial_model Model
}

pub interface Model {
mut:
    init() !Cmd
    update(Msg) (Model, Cmd)
}

pub interface Msg {}

pub type Cmd = fn () Msg

pub fn (mut a App) run() ! {
    cmd := a.initial_model.init()!
}

pub fn new_program(mut m Model) App {
    return App{
        t_ref: tui.init(tui.Config{})
        initial_model: m
    }
}

