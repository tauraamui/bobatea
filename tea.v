module bobatea

import term.ui as tui
import lib.draw

pub struct App {
    render_debug bool
mut:
    t_ref         &tui.Context
    initial_model Model
}

pub interface Model {
mut:
    init() ?Cmd
    update(Msg) (Model, ?Cmd)
    view(mut draw.Contextable)
}

pub interface Msg {}

pub type Cmd = fn () Msg

struct NoopMsg {}

fn noop_cmd() Msg {
    return NoopMsg{}
}

pub fn (mut a App) run() ! {
    cmd := a.initial_model.init() or { noop_cmd }
    cmd() // TODO(tauraamui): something with the initial msg?
}

pub fn new_program(mut m Model) App {
    return App{
        t_ref: tui.init(tui.Config{})
        initial_model: m
    }
}

